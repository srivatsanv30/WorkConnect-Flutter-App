const express = require('express');
const Message = require('../models/Message');
const Job = require('../models/Job');
const requireAuth = require('../middleware/requireAuth');

const router = express.Router();

// GET /api/jobs/:jobId/messages  (chat history — only creator or assignee)
router.get('/:jobId/messages', requireAuth, async (req, res) => {
  try {
    const job = await Job.findById(req.params.jobId);
    if (!job) return res.status(404).json({ message: 'Job not found' });

    const isCreator = job.creator.toString() === req.userId;
    const isAssignee = job.assignedTo && job.assignedTo.toString() === req.userId;
    if (!isCreator && !isAssignee) {
      return res.status(403).json({ message: 'Not authorized to view this chat' });
    }

    const messages = await Message.find({ job: req.params.jobId })
      .sort({ createdAt: 1 })
      .populate('sender', 'name');

    res.json({ messages });
  } catch (err) {
    res.status(500).json({ message: 'Failed to fetch messages', error: err.message });
  }
});

module.exports = router;