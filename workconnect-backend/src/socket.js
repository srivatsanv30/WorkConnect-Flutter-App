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

    socket.on('send_message', async ({ jobId, text, imageUrl }) => {
      try {
        if ((!text || !text.trim()) && !imageUrl) return;

        const job = await Job.findById(jobId);
        if (!job) return;

        const isCreator = job.creator.toString() === socket.userId;
        const isAssignee = job.assignedTo && job.assignedTo.toString() === socket.userId;
        if (!isCreator && !isAssignee) return;

        const message = await Message.create({
          job: jobId,
          sender: socket.userId,
          text: text ? text.trim() : '',
          imageUrl: imageUrl || null,
        });

        const populated = await message.populate('sender', 'name');
        io.to(jobId).emit('new_message', populated);
      } catch (err) {
        console.error('Socket send_message error:', err.message);
      }
    });

    socket.on('delete_message', async ({ jobId, messageId, forEveryone }) => {
      try {
        const message = await Message.findById(messageId);
        if (!message) return;

        if (forEveryone) {
          if (message.sender.toString() !== socket.userId) return;
          message.isDeletedForEveryone = true;
          message.text = '';
          message.imageUrl = null;
          await message.save();

          io.to(jobId).emit('message_deleted', {
            messageId: message._id.toString(),
            isDeletedForEveryone: true,
          });
        } else {
          if (!message.deletedFor.includes(socket.userId)) {
            message.deletedFor.push(socket.userId);
            await message.save();
          }
          socket.emit('message_deleted_for_me', {
            messageId: message._id.toString(),
          });
        }
      } catch (err) {
        console.error('Socket delete_message error:', err.message);
      }
    });

    socket.on('disconnect', () => {
      // client disconnected
    });
  });
}

module.exports = setupSocket;