const express = require('express');
const User = require('../models/User');
const Notification = require('../models/Notification');
const requireAuth = require('../middleware/requireAuth');

const router = express.Router();

// POST /api/notifications/register-token  (save this device's FCM token)
router.post('/register-token', requireAuth, async (req, res) => {
  try {
    const { fcmToken } = req.body;
    if (!fcmToken) {
      return res.status(400).json({ message: 'fcmToken is required' });
    }

    await User.findByIdAndUpdate(req.userId, { fcmToken });
    res.json({ message: 'Token registered' });
  } catch (err) {
    res.status(500).json({ message: 'Failed to register token', error: err.message });
  }
});

// GET /api/notifications  (list this user's notifications, newest first)
router.get('/', requireAuth, async (req, res) => {
  try {
    const notifications = await Notification.find({ user: req.userId })
      .sort({ createdAt: -1 })
      .limit(50);
    res.json({ notifications });
  } catch (err) {
    res.status(500).json({ message: 'Failed to fetch notifications', error: err.message });
  }
});

// PATCH /api/notifications/:id/read  (mark one as read)
router.patch('/:id/read', requireAuth, async (req, res) => {
  try {
    await Notification.findOneAndUpdate(
      { _id: req.params.id, user: req.userId },
      { read: true }
    );
    res.json({ message: 'Marked as read' });
  } catch (err) {
    res.status(500).json({ message: 'Failed to update', error: err.message });
  }
});

module.exports = router;