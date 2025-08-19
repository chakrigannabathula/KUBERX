const express = require('express');
const jwt = require('jsonwebtoken');
const { verifyFirebaseToken, getFirebaseUser } = require('../config/firebase');
const User = require('../models/User');
const Portfolio = require('../models/Portfolio');
const { authLimiter, validateUserInput } = require('../middleware/auth');
const router = express.Router();

// Apply rate limiting to all auth routes
router.use(authLimiter);

// Generate JWT token
const generateToken = (userId) => {
  return jwt.sign({ userId }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRE || '30d'
  });
};

// Google Sign-In with Firebase
router.post('/google-signin', async (req, res) => {
  try {
    const { firebaseToken, userData } = req.body;

    if (!firebaseToken) {
      return res.status(400).json({
        error: 'Firebase token is required'
      });
    }

    // Verify Firebase token
    const decodedToken = await verifyFirebaseToken(firebaseToken);
    const { uid, email, name, picture } = decodedToken;

    // Check if user exists
    let user = await User.findOne({ firebaseUid: uid });

    if (!user) {
      // Create new user - this user will need onboarding
      const tempUsername = email.split('@')[0] + '_' + Date.now();

      user = new User({
        firebaseUid: uid,
        email: email,
        name: name || userData?.name || 'User',
        username: tempUsername, // Temporary username - will be updated in onboarding
        profilePicture: picture,
        dateOfBirth: new Date('1990-01-01'), // Default date - will be updated in onboarding
        language: userData?.language || 'English',
        isVerified: decodedToken.email_verified || false,
        isProfileCompleted: false // Mark as incomplete for new users
      });

      await user.save();

      // Create empty portfolio for new user
      const portfolio = new Portfolio({
        userId: user._id,
        holdings: [],
        totalValue: 0,
        totalInvested: 0,
        totalProfitLoss: 0,
        totalProfitLossPercentage: 0
      });

      await portfolio.save();
    } else {
      // Existing user - update last login and check if profile is complete
      user.lastLoginAt = new Date();

      // Check if this user has completed onboarding by looking at their data
      const hasRealUsername = !user.username.includes('_'); // Temp usernames have timestamps
      const hasRealDateOfBirth = user.dateOfBirth && user.dateOfBirth.getFullYear() !== 1990;

      // If user has real data, mark profile as complete
      if (hasRealUsername && hasRealDateOfBirth) {
        user.isProfileCompleted = true;
      }

      await user.save();
    }

    // Generate JWT token
    const token = generateToken(user._id);

    res.status(200).json({
      message: 'Authentication successful',
      token,
      user: {
        id: user._id,
        email: user.email,
        name: user.name,
        username: user.username,
        profilePicture: user.profilePicture,
        language: user.language,
        isVerified: user.isVerified,
        kycStatus: user.kycStatus,
        totalPortfolioValue: user.totalPortfolioValue,
        isProfileCompleted: user.isProfileCompleted
      }
    });

  } catch (error) {
    console.error('Google Sign-In error:', error);
    res.status(500).json({
      error: 'Authentication failed',
      details: error.message
    });
  }
});

// Refresh token
router.post('/refresh-token', async (req, res) => {
  try {
    const { firebaseToken } = req.body;

    if (!firebaseToken) {
      return res.status(400).json({
        error: 'Firebase token is required'
      });
    }

    const decodedToken = await verifyFirebaseToken(firebaseToken);
    const user = await User.findOne({ firebaseUid: decodedToken.uid });

    if (!user) {
      return res.status(404).json({
        error: 'User not found'
      });
    }

    const token = generateToken(user._id);

    res.status(200).json({
      message: 'Token refreshed successfully',
      token
    });

  } catch (error) {
    console.error('Token refresh error:', error);
    res.status(500).json({
      error: 'Token refresh failed',
      details: error.message
    });
  }
});

// Logout
router.post('/logout', async (req, res) => {
  try {
    // In a production app, you might want to blacklist the token
    res.status(200).json({
      message: 'Logged out successfully'
    });
  } catch (error) {
    console.error('Logout error:', error);
    res.status(500).json({
      error: 'Logout failed'
    });
  }
});

// Verify token endpoint
router.get('/verify', async (req, res) => {
  try {
    const token = req.header('Authorization')?.replace('Bearer ', '');

    if (!token) {
      return res.status(401).json({
        error: 'No token provided'
      });
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const user = await User.findById(decoded.userId).select('-__v');

    if (!user) {
      return res.status(404).json({
        error: 'User not found'
      });
    }

    res.status(200).json({
      valid: true,
      user: {
        id: user._id,
        email: user.email,
        name: user.name,
        profilePicture: user.profilePicture,
        language: user.language,
        isVerified: user.isVerified,
        kycStatus: user.kycStatus,
        totalPortfolioValue: user.totalPortfolioValue
      }
    });

  } catch (error) {
    res.status(401).json({
      valid: false,
      error: 'Invalid token'
    });
  }
});

// Check if user exists and profile is complete
router.post('/check-user', async (req, res) => {
  try {
    const { firebaseToken } = req.body;

    if (!firebaseToken) {
      return res.status(400).json({
        error: 'Firebase token is required'
      });
    }

    // Verify Firebase token
    const decodedToken = await verifyFirebaseToken(firebaseToken);
    const { uid, email } = decodedToken;

    // Check if user exists
    const user = await User.findOne({ firebaseUid: uid });

    if (!user) {
      return res.status(200).json({
        exists: false,
        needsOnboarding: true,
        message: 'User not found, onboarding required'
      });
    }

    // Check if profile is complete
    const profileComplete = user.isProfileComplete();

    return res.status(200).json({
      exists: true,
      needsOnboarding: !profileComplete,
      profileComplete,
      user: {
        id: user._id,
        email: user.email,
        name: user.name,
        username: user.username,
        profilePicture: user.profilePicture,
        language: user.language,
        isVerified: user.isVerified,
        kycStatus: user.kycStatus,
        totalPortfolioValue: user.totalPortfolioValue,
        isProfileCompleted: user.isProfileCompleted
      }
    });

  } catch (error) {
    console.error('Check user error:', error);
    res.status(500).json({
      error: 'Failed to check user',
      details: error.message
    });
  }
});

// Complete user onboarding
router.post('/complete-onboarding', validateUserInput, async (req, res) => {
  try {
    const { firebaseToken, username, dateOfBirth, name } = req.body;

    if (!firebaseToken || !username || !dateOfBirth) {
      return res.status(400).json({
        error: 'Firebase token, username, and date of birth are required'
      });
    }

    // Verify Firebase token
    const decodedToken = await verifyFirebaseToken(firebaseToken);
    const { uid, email, picture } = decodedToken;

    // Check if username is already taken
    const existingUser = await User.findOne({ username: username.toLowerCase() });
    if (existingUser && existingUser.firebaseUid !== uid) {
      return res.status(400).json({
        error: 'Username already taken'
      });
    }

    // Find or create user
    let user = await User.findOne({ firebaseUid: uid });

    if (!user) {
      // Create new user
      user = new User({
        firebaseUid: uid,
        email: email,
        name: name || decodedToken.name || 'User',
        username: username.toLowerCase(),
        dateOfBirth: new Date(dateOfBirth),
        profilePicture: picture,
        isVerified: decodedToken.email_verified || false,
        language: 'English'
      });

      await user.save();

      // Create empty portfolio for new user
      const portfolio = new Portfolio({
        userId: user._id,
        holdings: [],
        totalValue: 0,
        totalInvested: 0,
        totalProfitLoss: 0,
        totalProfitLossPercentage: 0
      });

      await portfolio.save();
    } else {
      // Update existing user with onboarding data
      user.name = name || user.name;
      user.username = username.toLowerCase();
      user.dateOfBirth = new Date(dateOfBirth);
      user.isProfileCompleted = true; // Mark profile as complete after onboarding
      user.lastLoginAt = new Date();
      await user.save();
    }

    // Generate JWT token
    const token = generateToken(user._id);

    res.status(200).json({
      message: 'Onboarding completed successfully',
      token,
      user: {
        id: user._id,
        email: user.email,
        name: user.name,
        username: user.username,
        profilePicture: user.profilePicture,
        language: user.language,
        isVerified: user.isVerified,
        kycStatus: user.kycStatus,
        totalPortfolioValue: user.totalPortfolioValue,
        isProfileCompleted: user.isProfileCompleted
      }
    });

  } catch (error) {
    console.error('Complete onboarding error:', error);
    res.status(500).json({
      error: 'Failed to complete onboarding',
      details: error.message
    });
  }
});

module.exports = router;
