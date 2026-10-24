const express = require('express');
const Message = require('../models/Message');
const Job = require('../models/Job');
const requireAuth = require('../middleware/requireAuth');

const router = express.Router();

async function canAccessJob(jobId, userId) {
  const job = await Job.findById(jobId);
  if (!job) return { allowed: false, notFound: true };
  const isCreator = job.creator.toString() === userId;
  const isAssignee = job.assignedTo && job.assignedTo.toString() === userId;
  return { allowed: isCreator || isAssignee, job };
}

// GET /api/jobs/:jobId/messages  (chat history — only creator or assignee)
router.get('/:jobId/messages', requireAuth, async (req, res) => {
  try {
    const auth = await canAccessJob(req.params.jobId, req.userId);
    if (auth.notFound) return res.status(404).json({ message: 'Job not found' });
    if (!auth.allowed) {
      return res.status(403).json({ message: 'Not authorized to view this chat' });
    }

    const messages = await Message.find({
      job: req.params.jobId,
      deletedFor: { $ne: req.userId },
    })
      .sort({ createdAt: 1 })
      .populate('sender', 'name');

    const sanitized = messages.map((m) => {
      const doc = m.toObject();
      if (doc.isDeletedForEveryone) {
        doc.text = '';
        doc.imageUrl = null;
      }
      return doc;
    });

    res.json({ messages: sanitized });
  } catch (err) {
    res.status(500).json({ message: 'Failed to fetch messages', error: err.message });
  }
});

// POST /api/jobs/:jobId/messages (send message endpoint with socket broadcast)
router.post('/:jobId/messages', requireAuth, async (req, res) => {
  try {
    const auth = await canAccessJob(req.params.jobId, req.userId);
    if (auth.notFound) return res.status(404).json({ message: 'Job not found' });
    if (!auth.allowed) {
      return res.status(403).json({ message: 'Not authorized to post to this chat' });
    }

    const { text, imageUrl } = req.body;
    if ((!text || !text.trim()) && !imageUrl) {
      return res.status(400).json({ message: 'Message text or image is required' });
    }

    const message = await Message.create({
      job: req.params.jobId,
      sender: req.userId,
      text: text ? text.trim() : '',
      imageUrl: imageUrl || null,
    });

    const populated = await message.populate('sender', 'name');

    const io = req.app.get('io');
    if (io) {
      io.to(req.params.jobId).emit('new_message', populated);
    }

    res.status(201).json({ message: populated });
  } catch (err) {
    res.status(500).json({ message: 'Failed to send message', error: err.message });
  }
});

// DELETE /api/jobs/:jobId/messages/:messageId (delete for me or delete for everyone)
router.delete('/:jobId/messages/:messageId', requireAuth, async (req, res) => {
  try {
    const auth = await canAccessJob(req.params.jobId, req.userId);
    if (auth.notFound) return res.status(404).json({ message: 'Job not found' });
    if (!auth.allowed) {
      return res.status(403).json({ message: 'Not authorized to modify this chat' });
    }

    const message = await Message.findById(req.params.messageId);
    if (!message) return res.status(404).json({ message: 'Message not found' });

    const forEveryone = req.query.forEveryone === 'true' || req.body?.forEveryone === true;

    if (forEveryone) {
      // Must be sender
      if (message.sender.toString() !== req.userId) {
        return res.status(403).json({ message: 'You can only delete your own messages for everyone' });
      }

      message.isDeletedForEveryone = true;
      message.text = '';
      message.imageUrl = null;
      await message.save();

      const io = req.app.get('io');
      if (io) {
        io.to(req.params.jobId).emit('message_deleted', {
          messageId: message._id.toString(),
          isDeletedForEveryone: true,
        });
      }

      return res.json({ success: true, messageId: message._id, isDeletedForEveryone: true });
    } else {
      // Delete for me only
      if (!message.deletedFor.includes(req.userId)) {
        message.deletedFor.push(req.userId);
        await message.save();
      }

      return res.json({ success: true, messageId: message._id, isDeletedForEveryone: false });
    }
  } catch (err) {
    res.status(500).json({ message: 'Failed to delete message', error: err.message });
  }
});

module.exports = router;