const express = require('express');
const Job = require('../models/Job');
const requireAuth = require('../middleware/requireAuth');
const router = express.Router();
function isParticipant(job, userId) {
  const isCreator = job.creator.toString() === userId;
  const isAssignee = job.assignedTo && job.assignedTo.toString() === userId;
  return isCreator || isAssignee;
}
// PATCH /api/jobs/:id/status  (update job status)
router.patch('/:id/status', requireAuth, async (req, res) => {
  try {
    const { status } = req.body;
    const validStatuses = ['Pending', 'Accepted', 'In Progress', 'Review', 'Completed'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({ message: 'Invalid status' });
    }
    const job = await Job.findById(req.params.id);
    if (!job) return res.status(404).json({ message: 'Job not found' });
    if (!isParticipant(job, req.userId)) {
      return res.status(403).json({ message: 'Not authorized' });
    }
    job.status = status;
    await job.save();
    res.json({ job });
  } catch (err) {
    res.status(500).json({ message: 'Failed to update status', error: err.message });
  }
});
// POST /api/jobs/:id/milestones  (add a milestone)
router.post('/:id/milestones', requireAuth, async (req, res) => {
  try {
    const { title } = req.body;
    if (!title || !title.trim()) {
      return res.status(400).json({ message: 'title is required' });
    }
    const job = await Job.findById(req.params.id);
    if (!job) return res.status(404).json({ message: 'Job not found' });
    if (!isParticipant(job, req.userId)) {
      return res.status(403).json({ message: 'Not authorized' });
    }
    job.milestones.push({ title: title.trim(), done: false });
    await job.save();
    res.status(201).json({ job });
  } catch (err) {
    res.status(500).json({ message: 'Failed to add milestone', error: err.message });
  }
});
// PATCH /api/jobs/:id/milestones/:milestoneId  (toggle done)
router.patch('/:id/milestones/:milestoneId', requireAuth, async (req, res) => {
  try {
    const job = await Job.findById(req.params.id);
    if (!job) return res.status(404).json({ message: 'Job not found' });
    if (!isParticipant(job, req.userId)) {
      return res.status(403).json({ message: 'Not authorized' });
    }
    const milestone = job.milestones.id(req.params.milestoneId);
    if (!milestone) return res.status(404).json({ message: 'Milestone not found' });
    milestone.done = !milestone.done;
    await job.save();
    res.json({ job });
  } catch (err) {
    res.status(500).json({ message: 'Failed to update milestone', error: err.message });
  }
});

// POST /complete-review  (mark status as Completed, rate, and review assignee)
router.post('/:id/complete-review', requireAuth, async (req, res) => {
  try {
    const { rating, reviewText } = req.body;
    const job = await Job.findById(req.params.id);
    if (!job) return res.status(404).json({ message: 'Job not found' });

    if (job.creator.toString() !== req.userId) {
      return res.status(403).json({ message: 'Only the creator can complete and review the project' });
    }

    if (!job.assignedTo) {
      return res.status(400).json({ message: 'No collaborator assigned to this job' });
    }

    job.status = 'Completed';
    job.completedAt = new Date();
    job.rating = rating;
    job.reviewText = reviewText;

    // Mark all milestones as completed
    job.milestones.forEach(m => m.done = true);

    await job.save();

    // Update the collaborator's rating average and count
    const User = require('../models/User');
    const collaborator = await User.findById(job.assignedTo);
    if (collaborator) {
      const completedJobs = await Job.find({ assignedTo: job.assignedTo, status: 'Completed' });
      const ratedJobs = completedJobs.filter(j => j.rating !== undefined && j.rating !== null);
      
      collaborator.ratingCount = ratedJobs.length;
      const totalRating = ratedJobs.reduce((sum, j) => sum + j.rating, 0);
      collaborator.ratingAverage = ratedJobs.length > 0 ? Number((totalRating / ratedJobs.length).toFixed(1)) : 0;
      await collaborator.save();
    }

    const populated = await Job.findById(job._id)
      .populate('creator', 'name email')
      .populate('assignedTo', 'name email')
      .populate('applicants', 'name email skills');

    res.json({ job: populated });
  } catch (err) {
    res.status(500).json({ message: 'Failed to complete project', error: err.message });
  }
});

// POST /review-feedback  (creator requests changes or approves review)
router.post('/:id/review-feedback', requireAuth, async (req, res) => {
  try {
    const { action, feedback } = req.body;
    const job = await Job.findById(req.params.id);
    if (!job) return res.status(404).json({ message: 'Job not found' });

    if (job.creator.toString() !== req.userId) {
      return res.status(403).json({ message: 'Only the creator can review the project' });
    }

    if (action === 'request_changes') {
      job.status = 'In Progress';
      if (feedback) {
        if (!job.reviewComments) job.reviewComments = [];
        job.reviewComments.push(feedback);
      }
    } else if (action === 'approve') {
      job.status = 'Review';
      if (feedback) {
        if (!job.reviewComments) job.reviewComments = [];
        job.reviewComments.push(feedback);
      }
    }

    await job.save();

    const populated = await Job.findById(job._id)
      .populate('creator', 'name email')
      .populate('assignedTo', 'name email')
      .populate('applicants', 'name email skills');

    res.json({ job: populated });
  } catch (err) {
    res.status(500).json({ message: 'Failed to process review', error: err.message });
  }
});

module.exports = router;