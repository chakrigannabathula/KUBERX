const express = require('express');
const Portfolio = require('../models/Portfolio');
const Transaction = require('../models/Transaction');
const User = require('../models/User');
const router = express.Router();

// Get user portfolio
router.get('/', async (req, res) => {
  try {
    const portfolio = await Portfolio.findOne({ userId: req.user._id });

    if (!portfolio) {
      // Create empty portfolio if it doesn't exist
      const newPortfolio = new Portfolio({
        userId: req.user._id,
        holdings: [],
        totalValue: 0,
        totalInvested: 0,
        totalProfitLoss: 0,
        totalProfitLossPercentage: 0
      });
      await newPortfolio.save();
      return res.status(200).json({ portfolio: newPortfolio });
    }

    res.status(200).json({ portfolio });
  } catch (error) {
    console.error('Portfolio fetch error:', error);
    res.status(500).json({
      error: 'Failed to fetch portfolio'
    });
  }
});

// Buy cryptocurrency
router.post('/buy', async (req, res) => {
  try {
    const { symbol, name, amount, price, paymentMethod } = req.body;

    if (!symbol || !name || !amount || !price) {
      return res.status(400).json({
        error: 'Missing required fields: symbol, name, amount, price'
      });
    }

    const totalValue = amount * price;
    const fees = totalValue * 0.01; // 1% fee
    const finalAmount = totalValue + fees;

    // Create transaction
    const transaction = new Transaction({
      userId: req.user._id,
      type: 'buy',
      symbol: symbol.toUpperCase(),
      name,
      amount,
      price,
      totalValue,
      fees,
      paymentMethod: paymentMethod || 'wallet',
      status: 'completed' // In real app, this would be 'pending' initially
    });

    await transaction.save();

    // Update portfolio
    let portfolio = await Portfolio.findOne({ userId: req.user._id });

    if (!portfolio) {
      portfolio = new Portfolio({
        userId: req.user._id,
        holdings: [],
        totalValue: 0,
        totalInvested: 0
      });
    }

    // Find existing holding or create new one
    const existingHoldingIndex = portfolio.holdings.findIndex(
      holding => holding.symbol === symbol.toUpperCase()
    );

    if (existingHoldingIndex >= 0) {
      // Update existing holding
      const holding = portfolio.holdings[existingHoldingIndex];
      const newTotalAmount = holding.amount + amount;
      const newTotalValue = (holding.amount * holding.averageBuyPrice) + totalValue;

      holding.amount = newTotalAmount;
      holding.averageBuyPrice = newTotalValue / newTotalAmount;
      holding.currentPrice = price;
      holding.totalValue = newTotalAmount * price;
    } else {
      // Add new holding
      portfolio.holdings.push({
        symbol: symbol.toUpperCase(),
        name,
        amount,
        averageBuyPrice: price,
        currentPrice: price,
        totalValue: totalValue,
        imageUrl: getImageUrl(symbol)
      });
    }

    // Update portfolio totals
    portfolio.totalInvested += totalValue;
    portfolio.totalValue = portfolio.holdings.reduce((sum, holding) => sum + holding.totalValue, 0);
    portfolio.totalProfitLoss = portfolio.totalValue - portfolio.totalInvested;
    portfolio.totalProfitLossPercentage = portfolio.totalInvested > 0
      ? (portfolio.totalProfitLoss / portfolio.totalInvested) * 100 : 0;
    portfolio.lastUpdated = new Date();

    await portfolio.save();

    // Update user's total portfolio value
    await User.findByIdAndUpdate(req.user._id, {
      totalPortfolioValue: portfolio.totalValue
    });

    res.status(201).json({
      message: 'Purchase successful',
      transaction,
      portfolio
    });

  } catch (error) {
    console.error('Buy crypto error:', error);
    res.status(500).json({
      error: 'Failed to process purchase'
    });
  }
});

// Sell cryptocurrency
router.post('/sell', async (req, res) => {
  try {
    const { symbol, amount, price } = req.body;

    if (!symbol || !amount || !price) {
      return res.status(400).json({
        error: 'Missing required fields: symbol, amount, price'
      });
    }

    const portfolio = await Portfolio.findOne({ userId: req.user._id });
    if (!portfolio) {
      return res.status(404).json({
        error: 'Portfolio not found'
      });
    }

    const holdingIndex = portfolio.holdings.findIndex(
      holding => holding.symbol === symbol.toUpperCase()
    );

    if (holdingIndex === -1) {
      return res.status(400).json({
        error: 'You do not own this cryptocurrency'
      });
    }

    const holding = portfolio.holdings[holdingIndex];
    if (holding.amount < amount) {
      return res.status(400).json({
        error: 'Insufficient balance'
      });
    }

    const totalValue = amount * price;
    const fees = totalValue * 0.01; // 1% fee
    const finalAmount = totalValue - fees;

    // Create transaction
    const transaction = new Transaction({
      userId: req.user._id,
      type: 'sell',
      symbol: symbol.toUpperCase(),
      name: holding.name,
      amount,
      price,
      totalValue,
      fees,
      status: 'completed'
    });

    await transaction.save();

    // Update holding
    holding.amount -= amount;
    holding.totalValue = holding.amount * price;

    // Remove holding if amount becomes zero
    if (holding.amount === 0) {
      portfolio.holdings.splice(holdingIndex, 1);
    }

    // Update portfolio totals
    const soldInvestment = amount * holding.averageBuyPrice;
    portfolio.totalInvested -= soldInvestment;
    portfolio.totalValue = portfolio.holdings.reduce((sum, h) => sum + h.totalValue, 0);
    portfolio.totalProfitLoss = portfolio.totalValue - portfolio.totalInvested;
    portfolio.totalProfitLossPercentage = portfolio.totalInvested > 0
      ? (portfolio.totalProfitLoss / portfolio.totalInvested) * 100 : 0;
    portfolio.lastUpdated = new Date();

    await portfolio.save();

    // Update user's total portfolio value
    await User.findByIdAndUpdate(req.user._id, {
      totalPortfolioValue: portfolio.totalValue
    });

    res.status(200).json({
      message: 'Sale successful',
      transaction,
      portfolio
    });

  } catch (error) {
    console.error('Sell crypto error:', error);
    res.status(500).json({
      error: 'Failed to process sale'
    });
  }
});

// Update portfolio prices (should be called periodically)
router.put('/update-prices', async (req, res) => {
  try {
    const { prices } = req.body; // { BTC: 2650000, ETH: 185000, ... }

    const portfolio = await Portfolio.findOne({ userId: req.user._id });
    if (!portfolio) {
      return res.status(404).json({
        error: 'Portfolio not found'
      });
    }

    // Update current prices and calculate new values
    portfolio.holdings.forEach(holding => {
      if (prices[holding.symbol]) {
        holding.currentPrice = prices[holding.symbol];
        holding.totalValue = holding.amount * holding.currentPrice;
        holding.profitLoss = holding.totalValue - (holding.amount * holding.averageBuyPrice);
        holding.profitLossPercentage = holding.averageBuyPrice > 0
          ? (holding.profitLoss / (holding.amount * holding.averageBuyPrice)) * 100 : 0;
      }
    });

    // Update portfolio totals
    portfolio.totalValue = portfolio.holdings.reduce((sum, holding) => sum + holding.totalValue, 0);
    portfolio.totalProfitLoss = portfolio.totalValue - portfolio.totalInvested;
    portfolio.totalProfitLossPercentage = portfolio.totalInvested > 0
      ? (portfolio.totalProfitLoss / portfolio.totalInvested) * 100 : 0;
    portfolio.lastUpdated = new Date();

    await portfolio.save();

    // Update user's total portfolio value
    await User.findByIdAndUpdate(req.user._id, {
      totalPortfolioValue: portfolio.totalValue
    });

    res.status(200).json({
      message: 'Portfolio updated successfully',
      portfolio
    });

  } catch (error) {
    console.error('Update portfolio error:', error);
    res.status(500).json({
      error: 'Failed to update portfolio'
    });
  }
});

// Helper function to get crypto image URL
function getImageUrl(symbol) {
  const imageMap = {
    'BTC': 'https://cryptologos.cc/logos/bitcoin-btc-logo.png?v=029',
    'ETH': 'https://cryptologos.cc/logos/ethereum-eth-logo.png?v=029',
    'BNB': 'https://cryptologos.cc/logos/bnb-bnb-logo.png?v=029',
    'ADA': 'https://cryptologos.cc/logos/cardano-ada-logo.png?v=029',
    'SOL': 'https://cryptologos.cc/logos/solana-sol-logo.png?v=029'
  };
  return imageMap[symbol.toUpperCase()] || null;
}

module.exports = router;
