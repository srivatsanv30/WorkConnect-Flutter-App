const mongoose = require('mongoose');

const jobSchema = new mongoose.Schema(
  {
    title: { type: String, required: true, trim: true },
    description: { type: String, required: true },
    skillsRequired: { type: [String], default: [] },
    priority: {
      type: String,
      enum: ['Low', 'Medium', 'High', 'Urgent'],
      default: 'Medium',
    },
    deadline: { type: Date, required: true },
    status: {
      type: String,
      enum: ['Pending', 'Accepted', 'In Progress', 'Review', 'Completed'],
      default: 'Pending',
    },
    milestones: [
      {
        title: { type: String, required: true },
        done: { type: Boolean, default: false },
      },
    ],
    creator: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    assignedTo: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
    applicants: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
  },
  { timestamps: true }
);

module.exports = mongoose.model('Job', jobSchema);