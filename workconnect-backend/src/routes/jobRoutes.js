const express = require('express');
const Job = require('../models/Job');
const requireAuth = require('../middleware/requireAuth');
const { notifyMatchingUsers } = require('../utils/sendNotification');
const router = express.Router();

// POST /api/jobs  (create a job — requires login)
router.post('/', requireAuth, async (req, res) => {
  try {
    const { title, description, skillsRequired, priority, deadline, milestones } = req.body;

    if (!title || !description || !deadline) {
      return res.status(400).json({ message: 'title, description, and deadline are required' });
    }

    const job = await Job.create({
      title,
      description,
      skillsRequired: Array.isArray(skillsRequired) ? skillsRequired : [],
      priority: priority || 'Medium',
      deadline: new Date(deadline),
      creator: req.userId,
      milestones: Array.isArray(milestones) ? milestones.map(m => typeof m === 'string' ? { title: m, done: false } : m) : [],
    });

    const populated = await job.populate('creator', 'name email');
    res.status(201).json({ job: populated });

    // Fire-and-forget: notify matching users after responding to the request
    notifyMatchingUsers(job).catch((err) =>
      console.error('Failed to notify matching users:', err.message)
    );
  } catch (err) {
    res.status(500).json({ message: 'Failed to create job', error: err.message });
  }
});

// GET /api/jobs  (list all jobs, newest first — public, no login required)
router.get('/', async (req, res) => {
  try {
    let hiddenJobIds = [];
    const authHeader = req.headers.authorization;
    if (authHeader && authHeader.startsWith('Bearer ')) {
      const token = authHeader.split(' ')[1];
      try {
        const decoded = require('jsonwebtoken').verify(token, process.env.JWT_SECRET);
        const User = require('../models/User');
        const user = await User.findById(decoded.userId);
        if (user && user.hiddenJobs) {
          hiddenJobIds = user.hiddenJobs;
        }
      } catch (err) {
        // ignore invalid token
      }
    }

    const query = hiddenJobIds.length > 0 ? { _id: { $nin: hiddenJobIds } } : {};
    const jobs = await Job.find(query)
      .sort({ createdAt: -1 })
      .populate('creator', 'name email')
      .populate('assignedTo', 'name email')
      .populate('applicants', 'name email skills');
    res.json({ jobs });
  } catch (err) {
    res.status(500).json({ message: 'Failed to fetch jobs', error: err.message });
  }
});

// GET /api/jobs/:id  (single job detail)
router.get('/:id', async (req, res) => {
  try {
    const job = await Job.findById(req.params.id)
      .populate('creator', 'name email')
      .populate('assignedTo', 'name email')
      .populate('applicants', 'name email skills');

    if (!job) return res.status(404).json({ message: 'Job not found' });
    res.json({ job });
  } catch (err) {
    res.status(500).json({ message: 'Failed to fetch job', error: err.message });
  }
});

// POST /api/jobs/:id/apply  (logged-in user applies to a job)
router.post('/:id/apply', requireAuth, async (req, res) => {
  try {
    const job = await Job.findById(req.params.id);
    if (!job) return res.status(404).json({ message: 'Job not found' });

    if (job.applicants.some((id) => id.toString() === req.userId)) {
      return res.status(409).json({ message: 'You already applied to this job' });
    }

    job.applicants.push(req.userId);
    await job.save();

    const populated = await Job.findById(job._id)
      .populate('creator', 'name email')
      .populate('assignedTo', 'name email')
      .populate('applicants', 'name email skills');

    // Notify project creator
    try {
      const User = require('../models/User');
      const { sendNotificationToUser } = require('../utils/sendNotification');
      const applicant = await User.findById(req.userId);
      const applicantName = applicant ? applicant.name : 'Someone';
      await sendNotificationToUser({
        userId: populated.creator._id,
        title: 'New Collaboration Request',
        body: `Your "${populated.title}" project has an invitation request from ${applicantName}.`,
        jobId: populated._id,
      });
    } catch (notifErr) {
      console.error('Failed to send application notification:', notifErr.message);
    }

    res.json({ message: 'Applied successfully', job: populated });
  } catch (err) {
    res.status(500).json({ message: 'Failed to apply', error: err.message });
  }
});
// PATCH /api/jobs/:id/assign  (creator assigns one applicant to the job)
router.patch('/:id/assign', requireAuth, async (req, res) => {
  try {
    const { applicantId } = req.body;
    const job = await Job.findById(req.params.id);

    if (!job) return res.status(404).json({ message: 'Job not found' });
    if (job.creator.toString() !== req.userId) {
      return res.status(403).json({ message: 'Only the job creator can assign this project' });
    }
    if (!job.applicants.some((id) => id.toString() === applicantId)) {
      return res.status(400).json({ message: 'That user has not applied to this job' });
    }

    job.assignedTo = applicantId;
    job.status = 'Accepted';
    await job.save();

    const populated = await Job.findById(job._id)
      .populate('creator', 'name email')
      .populate('assignedTo', 'name email')
      .populate('applicants', 'name email skills');
    res.json({ job: populated });
  } catch (err) {
    res.status(500).json({ message: 'Failed to assign job', error: err.message });
  }
});

// DELETE /api/jobs/:id (creator deletes their job)
router.delete('/:id', requireAuth, async (req, res) => {
  try {
    const job = await Job.findById(req.params.id);
    if (!job) return res.status(404).json({ message: 'Job not found' });
    
    if (job.creator.toString() !== req.userId) {
      return res.status(403).json({ message: 'Only the creator can delete this job' });
    }
    
    await Job.deleteOne({ _id: req.params.id });
    res.json({ message: 'Job deleted successfully' });
  } catch (err) {
    res.status(500).json({ message: 'Failed to delete job', error: err.message });
  }
});

// POST /api/jobs/:id/hide (user hides a job from their feed)
router.post('/:id/hide', requireAuth, async (req, res) => {
  try {
    const User = require('../models/User');
    const user = await User.findById(req.userId);
    if (!user) return res.status(404).json({ message: 'User not found' });

    if (!user.hiddenJobs) {
      user.hiddenJobs = [];
    }

    if (!user.hiddenJobs.includes(req.params.id)) {
      user.hiddenJobs.push(req.params.id);
      await user.save();
    }

    res.json({ message: 'Job hidden successfully' });
  } catch (err) {
    res.status(500).json({ message: 'Failed to hide job', error: err.message });
  }
});

// POST /api/jobs/:id/complete
router.post('/:id/complete', requireAuth, async (req, res) => {
  try {
    const { rating, reviewText } = req.body;
    const job = await Job.findById(req.params.id);
    if (!job) return res.status(404).json({ message: 'Job not found' });
    
    if (job.creator.toString() !== req.userId) {
      return res.status(403).json({ message: 'Only the creator can mark this job as complete' });
    }
    
    if (job.status === 'Completed') {
      return res.status(400).json({ message: 'Job is already completed' });
    }
    
    job.status = 'Completed';
    job.completedAt = new Date();
    
    if (rating) {
      job.rating = rating;
      if (reviewText) job.reviewText = reviewText;
      
      if (job.assignedTo) {
        const User = require('../models/User');
        const assignee = await User.findById(job.assignedTo);
        if (assignee) {
          assignee.projectsCompleted = (assignee.projectsCompleted || 0) + 1;
          
          // Calculate XP (e.g., 50 base XP + 10 * rating)
          assignee.xp = (assignee.xp || 0) + 50 + (rating * 10);
          
          // Update rating
          const newCount = (assignee.ratingCount || 0) + 1;
          const oldAverage = assignee.ratingAverage || 0;
          const oldCount = assignee.ratingCount || 0;
          
          assignee.ratingAverage = ((oldAverage * oldCount) + rating) / newCount;
          assignee.ratingCount = newCount;
          
          await assignee.save();
        }
      }
    }
    
    await job.save();
    res.json({ message: 'Job completed successfully', job });
  } catch (err) {
    res.status(500).json({ message: 'Failed to complete job', error: err.message });
  }
});

module.exports = router;