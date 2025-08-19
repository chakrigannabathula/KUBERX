const jwt = require('jsonwebtoken');
const { verifyFirebaseToken } = require('../config/firebase');
const User = require('../models/User');
const rateLimit = require('express-rate-limit');

// Rate limiting for auth endpoints
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 10, // limit each IP to 10 requests per windowMs
  message: {
    error: 'Too many authentication attempts, please try again later.'
  },
  standardHeaders: true,
  legacyHeaders: false,
});

// Input validation middleware
const validateUserInput = (req, res, next) => {
  const { username, dateOfBirth } = req.body;

  if (username) {
    // Username validation
    if (!/^[a-zA-Z0-9_]{3,30}$/.test(username)) {
      return res.status(400).json({
        error: 'Username must be 3-30 characters long and contain only letters, numbers, and underscores'
      });
    }
  }

  if (dateOfBirth) {
    // Date of birth validation
    const dob = new Date(dateOfBirth);
    const today = new Date();
    const age = today.getFullYear() - dob.getFullYear();

    if (age < 13 || age > 120) {
      return res.status(400).json({
        error: 'Invalid date of birth. User must be between 13 and 120 years old'
      });
    }
  }

  next();
};

// Verify JWT token middleware
const verifyToken = async (req, res, next) => {
  try {
    const token = req.header('Authorization')?.replace('Bearer ', '');

    if (!token) {
      return res.status(401).json({
        error: 'Access denied. No token provided.'
      });
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const user = await User.findById(decoded.userId).select('-__v');

    if (!user || !user.isActive) {
      return res.status(401).json({
        error: 'Invalid token or user not found.'
      });
    }

    req.user = user;
    next();
  } catch (error) {
    console.error('Token verification error:', error);
    res.status(401).json({
      error: 'Invalid token.'
    });
  }
};

// Verify Firebase token middleware
const verifyFirebaseTokenMiddleware = async (req, res, next) => {
  try {
    const firebaseToken = req.header('Firebase-Token');

    if (!firebaseToken) {
      return res.status(401).json({
        error: 'Firebase token required.'
      });
    }

    const decodedToken = await verifyFirebaseToken(firebaseToken);
    req.firebaseUser = decodedToken;
    next();
  } catch (error) {
    console.error('Firebase token verification error:', error);
    res.status(401).json({
      error: 'Invalid Firebase token.'
    });
  }
};

// Admin verification middleware
const verifyAdmin = async (req, res, next) => {
  try {
    if (req.user.role !== 'admin') {
      return res.status(403).json({
        error: 'Access denied. Admin privileges required.'
      });
    }
    next();
  } catch (error) {
    res.status(500).json({
      error: 'Server error during admin verification.'
    });
  }
};

module.exports = {
  authLimiter,
  validateUserInput,
  verifyToken,
  verifyFirebaseTokenMiddleware,
  verifyAdmin
};
