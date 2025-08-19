const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  firebaseUid: {
    type: String,
    required: true,
    unique: true,
    index: true
  },
  email: {
    type: String,
    required: true,
    unique: true,
    lowercase: true,
    trim: true
  },
  name: {
    type: String,
    required: true,
    trim: true
  },
  username: {
    type: String,
    required: true,
    unique: true,
    trim: true,
    minlength: 3,
    maxlength: 30
  },
  profilePicture: {
    type: String,
    default: null
  },
  dateOfBirth: {
    type: Date,
    required: true
  },
  phoneNumber: {
    type: String,
    default: null
  },
  language: {
    type: String,
    enum: ['English', 'Telugu'],
    default: 'English'
  },
  isVerified: {
    type: Boolean,
    default: false
  },
  kycStatus: {
    type: String,
    enum: ['pending', 'verified', 'rejected'],
    default: 'pending'
  },
  totalPortfolioValue: {
    type: Number,
    default: 0
  },
  lastLoginAt: {
    type: Date,
    default: Date.now
  },
  isActive: {
    type: Boolean,
    default: true
  },
  isProfileCompleted: {
    type: Boolean,
    default: false
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Virtual for portfolio
userSchema.virtual('portfolio', {
  ref: 'Portfolio',
  localField: '_id',
  foreignField: 'userId'
});

// Index for better performance
userSchema.index({ email: 1, firebaseUid: 1 });
userSchema.index({ createdAt: -1 });

// Add method to check if profile is complete
userSchema.methods.isProfileComplete = function() {
  return this.username && this.dateOfBirth && this.name;
};

// Pre-save middleware to update profile completion status
userSchema.pre('save', function(next) {
  this.isProfileCompleted = this.isProfileComplete();
  next();
});

module.exports = mongoose.model('User', userSchema);
