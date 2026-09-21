const mongoose = require('mongoose');

async function connectDB() {
  try {
    await mongoose.connect(process.env.MONGO_URI, {
      serverSelectionTimeoutMS: 30000,
    });
    console.log('MongoDB connected');
  } catch (err) {
    console.error('MongoDB connection failed:', err.message);
    console.error('Tip: Ensure your current IP is whitelisted in MongoDB Atlas Network Access (or allow 0.0.0.0/0).');
    process.exit(1);
  }
}

module.exports = connectDB;
