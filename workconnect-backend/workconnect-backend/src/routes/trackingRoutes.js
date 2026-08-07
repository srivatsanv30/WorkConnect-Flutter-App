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
module.exports = router;