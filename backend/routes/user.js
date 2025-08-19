const express = require('express');
const User = require('../models/User');
const Portfolio = require('../models/Portfolio');
const Transaction = require('../models/Transaction');
const router = express.Router();

// Get user profile
router.get('/profile', async (req, res) => {
  try {
    const user = await User.findById(req.user._id)
      .select('-firebaseUid -__v')
      .populate('portfolio');

    res.status(200).json({
      user
    });
  } catch (error) {
    console.error('Get profile error:', error);
    res.status(500).json({
      error: 'Failed to fetch user profile'
    });
  }
});

// Update user profile
router.put('/profile', async (req, res) => {
  try {
    const { name, dateOfBirth, phoneNumber, language } = req.body;

    const updateData = {};
    if (name) updateData.name = name;
    if (dateOfBirth) updateData.dateOfBirth = new Date(dateOfBirth);
    if (phoneNumber) updateData.phoneNumber = phoneNumber;
    if (language) updateData.language = language;

    const user = await User.findByIdAndUpdate(
      req.user._id,
      updateData,
      { new: true, runValidators: true }
    ).select('-firebaseUid -__v');

    res.status(200).json({
      message: 'Profile updated successfully',
      user
    });
  } catch (error) {
    console.error('Update profile error:', error);
    res.status(500).json({
      error: 'Failed to update profile'
    });
  }
});

// Get user dashboard data
router.get('/dashboard', async (req, res) => {
  try {
    const user = await User.findById(req.user._id);
    const portfolio = await Portfolio.findOne({ userId: req.user._id });

    // Get recent transactions
    const recentTransactions = await Transaction.find({ userId: req.user._id })
      .sort({ createdAt: -1 })
      .limit(10);

    // Calculate total stats
    const totalTransactions = await Transaction.countDocuments({ userId: req.user._id });
    const totalInvested = portfolio?.totalInvested || 0;
    const currentValue = portfolio?.totalValue || 0;
    const profitLoss = currentValue - totalInvested;
    const profitLossPercentage = totalInvested > 0 ? (profitLoss / totalInvested) * 100 : 0;

    res.status(200).json({
      dashboard: {
        totalPortfolioValue: currentValue,
        totalInvested,
        profitLoss,
        profitLossPercentage,
        totalTransactions,
        holdingsCount: portfolio?.holdings?.length || 0,
        recentTransactions: recentTransactions.slice(0, 5)
      }
    });
  } catch (error) {
    console.error('Dashboard error:', error);
    res.status(500).json({
      error: 'Failed to fetch dashboard data'
    });
  }
});

// Get user transaction history
router.get('/transactions', async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;

    const transactions = await Transaction.find({ userId: req.user._id })
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit);

    const total = await Transaction.countDocuments({ userId: req.user._id });

    res.status(200).json({
      transactions,
      pagination: {
        page,
        limit,
        total,
        pages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    console.error('Transactions error:', error);
    res.status(500).json({
      error: 'Failed to fetch transactions'
    });
  }
});

// Delete user account
router.delete('/account', async (req, res) => {
  try {
    // Delete user's portfolio and transactions
    await Portfolio.deleteMany({ userId: req.user._id });
    await Transaction.deleteMany({ userId: req.user._id });

    // Soft delete user (mark as inactive)
    await User.findByIdAndUpdate(req.user._id, { isActive: false });

    res.status(200).json({
      message: 'Account deleted successfully'
    });
  } catch (error) {
    console.error('Delete account error:', error);
    res.status(500).json({
      error: 'Failed to delete account'
    });
  }
});

module.exports = router;
