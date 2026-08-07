const express = require('express');
const Job = require('../models/Job');
const requireAuth = require('../middleware/requireAuth');
const { notifyMatchingUsers } = require('../utils/sendNotification');
const router = express.Router();

// POST /api/jobs  (create a job — requires login)
router.post('/', requireAuth, async (req, res) => {
  try {
    const { title, description, skillsRequired, priority, deadline } = req.body;

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
    const jobs = await Job.find()
      .sort({ createdAt: -1 })
      .populate('creator', 'name email');
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

    res.json({ message: 'Applied successfully', job });
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

    const populated = await job.populate('creator assignedTo', 'name email');
    res.json({ job: populated });
  } catch (err) {
    res.status(500).json({ message: 'Failed to assign job', error: err.message });
  }
});

module.exports = router;