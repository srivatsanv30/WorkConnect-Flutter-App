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

// PUT /api/users/me  (update profile: skills, bio, title, phone, location, availability)
router.put('/me', requireAuth, async (req, res) => {
  const { name, skills, bio, title, phone, location, availability } = req.body;

  const user = await User.findByIdAndUpdate(
    req.userId,
    {
      ...(name !== undefined && { name }),
      ...(skills !== undefined && { skills }),
      ...(bio !== undefined && { bio }),
      ...(title !== undefined && { title }),
      ...(phone !== undefined && { phone }),
      ...(location !== undefined && { location }),
      ...(availability !== undefined && { availability }),
    },
    { new: true }
  );

  if (!user) return res.status(404).json({ message: 'User not found' });
  res.json({ user });
});

// GET /api/users/:id/reputation
router.get('/:id/reputation', async (req, res) => {
  try {
    const userId = req.params.id;
    const Job = require('../models/Job');
    const completedJobs = await Job.find({
      assignedTo: userId,
      status: 'Completed'
    }).populate('creator', 'name email');

    const jobsWithRating = completedJobs.filter(j => j.rating !== undefined && j.rating !== null);
    const ratingCount = jobsWithRating.length;
    const ratingSum = jobsWithRating.reduce((sum, j) => sum + j.rating, 0);
    const ratingAverage = ratingCount > 0 ? Number((ratingSum / ratingCount).toFixed(1)) : 0.0;
    const trustScore = (completedJobs.length * 10) + Math.round(ratingAverage * 5);

    const reviews = jobsWithRating.map(j => ({
      jobId: j._id,
      jobTitle: j.title,
      rating: j.rating,
      reviewText: j.reviewText || '',
      reviewerName: j.creator ? j.creator.name : 'Unknown Creator',
      completedAt: j.completedAt || j.updatedAt
    }));

    res.json({
      completedCount: completedJobs.length,
      ratingAverage,
      ratingCount,
      trustScore,
      reviews
    });
  } catch (err) {
    res.status(500).json({ message: 'Failed to fetch reputation', error: err.message });
  }
});

// GET /api/users
router.get('/', async (req, res) => {
  try {
    const { query } = req.query;
    let filter = {};
    if (query) {
      filter = {
        $or: [
          { name: { $regex: query, $options: 'i' } },
          { skills: { $regex: query, $options: 'i' } },
          { title: { $regex: query, $options: 'i' } }
        ]
      };
    }
    const users = await User.find(filter).select('-password');
    res.json({ users });
  } catch (err) {
    res.status(500).json({ message: 'Failed to search users', error: err.message });
  }
});

module.exports = router;
router.get('/debug/all', async (req, res) => {
  const users = await User.find({}, 'name email skills fcmToken');
  res.json({ users });
});