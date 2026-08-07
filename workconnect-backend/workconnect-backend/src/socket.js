const jwt = require('jsonwebtoken');
const Message = require('./models/Message');
const Job = require('./models/Job');

function setupSocket(io) {
  // Authenticate every socket connection using the same JWT as REST calls
  io.use((socket, next) => {
    const token = socket.handshake.auth?.token;
    if (!token) return next(new Error('No token provided'));

    try {
      const payload = jwt.verify(token, process.env.JWT_SECRET);
      socket.userId = payload.userId;
      next();
    } catch (err) {
      next(new Error('Invalid token'));
    }
  });

  io.on('connection', (socket) => {
    socket.on('join_job_room', async (jobId) => {
      const job = await Job.findById(jobId);
      if (!job) return;

      const isCreator = job.creator.toString() === socket.userId;
      const isAssignee = job.assignedTo && job.assignedTo.toString() === socket.userId;
      if (!isCreator && !isAssignee) return; // silently refuse unauthorized join

      socket.join(jobId);
    });

    socket.on('send_message', async ({ jobId, text }) => {
      if (!text || !text.trim()) return;

      const job = await Job.findById(jobId);
      if (!job) return;

      const isCreator = job.creator.toString() === socket.userId;
      const isAssignee = job.assignedTo && job.assignedTo.toString() === socket.userId;
      if (!isCreator && !isAssignee) return;

      const message = await Message.create({
        job: jobId,
        sender: socket.userId,
        text: text.trim(),
      });

      const populated = await message.populate('sender', 'name');
      io.to(jobId).emit('new_message', populated);
    });

    socket.on('disconnect', () => {
      // nothing needed for now
    });
  });
}

module.exports = setupSocket;