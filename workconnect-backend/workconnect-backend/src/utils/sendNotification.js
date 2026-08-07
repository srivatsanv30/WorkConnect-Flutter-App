const { messaging } = require('../config/firebaseAdmin');
const User = require('../models/User');
const Notification = require('../models/Notification');

/**
 * Creates an in-app notification record AND sends a real push
 * (if the user has a registered device token).
 */
async function sendNotificationToUser({ userId, title, body, jobId = null }) {
  await Notification.create({ user: userId, title, body, job: jobId });

  const user = await User.findById(userId);
  if (!user || !user.fcmToken) return; // no device token yet — skip push

  try {
    awaitmessaging().send({
      token: user.fcmToken,
      notification: { title, body },
    });
  } catch (err) {
    console.error(`Failed to push to user ${userId}:`, err.message);
  }
}

/**
 * Finds users whose skills overlap with a job's required skills
 * and notifies each of them. Called right after a job is created.
 */
async function notifyMatchingUsers(job) {
  if (!job.skillsRequired || job.skillsRequired.length === 0) return;

  const matchingUsers = await User.find({
    skills: { $in: job.skillsRequired },
    _id: { $ne: job.creator },
  });

  await Promise.all(
    matchingUsers.map((user) =>
      sendNotificationToUser({
        userId: user._id,
        title: 'New project matches your skills!',
        body: `"${job.title}" is looking for ${job.skillsRequired.join(', ')}`,
        jobId: job._id,
      })
    )
  );
}

module.exports = { sendNotificationToUser, notifyMatchingUsers };