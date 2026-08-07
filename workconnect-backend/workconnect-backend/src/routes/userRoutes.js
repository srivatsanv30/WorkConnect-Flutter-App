const express = require('express');
const User = require('../models/User');
const requireAuth = require('../middleware/requireAuth');

const router = express.Router();

// GET /api/users/me
router.get('/me', requireAuth, async (req, res) => {
  const user = await User.findById(req.userId);
  if (!user) return res.status(404).json({ message: 'User not found' });
  res.json({ user });
});

// PUT /api/users/me  (update profile: skills, bio, availability)
router.put('/me', requireAuth, async (req, res) => {
  const { name, skills, bio, availability } = req.body;

  const user = await User.findByIdAndUpdate(
    req.userId,
    {
      ...(name !== undefined && { name }),
      ...(skills !== undefined && { skills }),
      ...(bio !== undefined && { bio }),
      ...(availability !== undefined && { availability }),
    },
    { new: true }
  );

  if (!user) return res.status(404).json({ message: 'User not found' });
  res.json({ user });
});

module.exports = router;
// TEMPORARY DEBUG ROUTE — remove after testing
router.get('/debug/all', async (req, res) => {
  const users = await User.find({}, 'name email skills fcmToken');
  res.json({ users });
});