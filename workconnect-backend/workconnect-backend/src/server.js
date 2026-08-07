require('dotenv').config();
const express = require('express');
const aiRoutes = require('./routes/aiRoutes');
const cors = require('cors');
const connectDB = require('./config/db');
const authRoutes = require('./routes/authRoutes');
const userRoutes = require('./routes/userRoutes');
const jobRoutes = require('./routes/jobRoutes');
const notificationRoutes = require('./routes/notificationRoutes');
const http = require('http');
const { Server } = require('socket.io');
const messageRoutes = require('./routes/messageRoutes');
const setupSocket = require('./socket');
const app = express();
const server = http.createServer(app);
const io = new Server(server, { cors: { origin: '*' } });
const trackingRoutes = require('./routes/trackingRoutes');

app.use(cors());
app.use(express.json());

app.get('/api/health', (req, res) => {
  res.json({ status: 'ok' });
});

app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/jobs', jobRoutes);
app.use('/api/jobs', messageRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/tracking', trackingRoutes);
app.use('/api/ai', aiRoutes);
const PORT = process.env.PORT || 5000;

setupSocket(io);

connectDB().then(() => {
  server.listen(PORT, () => {
    console.log(`WorkConnect API running on http://localhost:${PORT}`);
  });
});
