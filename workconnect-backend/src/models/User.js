const mongoose = require('mongoose');

const userSchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true },
    email: { type: String, required: true, unique: true, lowercase: true, trim: true },
    passwordHash: { type: String, required: true },
    skills: { type: [String], default: [] },
    bio: { type: String, default: '' },
    title: { type: String, default: '' },
    phone: { type: String, default: '' },
    location: { type: String, default: '' },
    availability: {
      type: String,
      enum: ['available', 'busy', 'offline'],
      default: 'available',
    },
    fcmToken: { type: String, default: null },
    ratingAverage: { type: Number, default: 0 },
    ratingCount: { type: Number, default: 0 },
    xp: { type: Number, default: 0 },
    projectsCompleted: { type: Number, default: 0 },
    hiddenJobs: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Job' }],
    resetOtp: { type: String, default: null },
    resetOtpExpires: { type: Date, default: null },
  },
  { timestamps: true }
);

// Never send the hash or OTP back in API responses
userSchema.methods.toJSON = function () {
  const obj = this.toObject();
  delete obj.passwordHash;
  delete obj.resetOtp;
  delete obj.resetOtpExpires;
  return obj;
};

module.exports = mongoose.model('User', userSchema);
