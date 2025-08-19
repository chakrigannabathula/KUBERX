# KuberX Backend Setup Guide

## Overview
This backend provides authentication, user management, portfolio tracking, and cryptocurrency data for the KuberX Flutter app using Node.js, MongoDB, and Firebase.

## Prerequisites
- Node.js (v16 or higher)
- MongoDB (local installation or MongoDB Atlas)
- Firebase project with Authentication enabled
- Google Cloud Console project (for Google Sign-In)

## Installation

### 1. Install Dependencies
```bash
cd backend
npm install
```

### 2. MongoDB Setup
- **Local MongoDB**: Ensure MongoDB is running on `mongodb://localhost:27017`
- **MongoDB Atlas**: Get your connection string from Atlas dashboard

### 3. Firebase Setup

#### Step 1: Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or select existing one
3. Enable Authentication → Sign-in method → Google

#### Step 2: Generate Service Account Key
1. Go to Project Settings → Service Accounts
2. Click "Generate new private key"
3. Download the JSON file

#### Step 3: Configure Environment Variables
Copy `.env.example` to `.env` and fill in the values:

```env
# MongoDB
MONGODB_URI=mongodb://localhost:27017/kuberx

# Server
NODE_ENV=development
PORT=3000

# JWT
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
JWT_EXPIRE=30d

# Firebase (from service account JSON)
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_PRIVATE_KEY_ID=your-private-key-id
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nyour-private-key\n-----END PRIVATE KEY-----\n"
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@your-project.iam.gserviceaccount.com
FIREBASE_CLIENT_ID=your-client-id
FIREBASE_AUTH_URI=https://accounts.google.com/o/oauth2/auth
FIREBASE_TOKEN_URI=https://oauth2.googleapis.com/token
```

## Running the Backend

### Development Mode
```bash
npm run dev
```

### Production Mode
```bash
npm start
```

The server will start on `http://localhost:3000`

## API Endpoints

### Authentication
- `POST /api/auth/google-signin` - Google Sign-In with Firebase
- `POST /api/auth/refresh-token` - Refresh JWT token
- `GET /api/auth/verify` - Verify JWT token
- `POST /api/auth/logout` - Logout user

### User Management
- `GET /api/user/profile` - Get user profile
- `PUT /api/user/profile` - Update user profile
- `GET /api/user/dashboard` - Get dashboard data
- `GET /api/user/transactions` - Get transaction history
- `DELETE /api/user/account` - Delete user account

### Cryptocurrency Data
- `GET /api/crypto/popular` - Get popular cryptocurrencies
- `GET /api/crypto/:symbol` - Get specific crypto details
- `GET /api/crypto/search/:query` - Search cryptocurrencies

### Portfolio Management
- `GET /api/portfolio` - Get user portfolio
- `POST /api/portfolio/buy` - Buy cryptocurrency
- `POST /api/portfolio/sell` - Sell cryptocurrency
- `PUT /api/portfolio/update-prices` - Update portfolio prices

## Database Schema

### User Collection
```javascript
{
  firebaseUid: String,
  email: String,
  name: String,
  profilePicture: String,
  dateOfBirth: Date,
  phoneNumber: String,
  language: String,
  isVerified: Boolean,
  kycStatus: String,
  totalPortfolioValue: Number,
  lastLoginAt: Date,
  isActive: Boolean,
  createdAt: Date,
  updatedAt: Date
}
```

### Portfolio Collection
```javascript
{
  userId: ObjectId,
  holdings: [{
    symbol: String,
    name: String,
    amount: Number,
    averageBuyPrice: Number,
    currentPrice: Number,
    totalValue: Number,
    profitLoss: Number,
    profitLossPercentage: Number,
    imageUrl: String
  }],
  totalValue: Number,
  totalInvested: Number,
  totalProfitLoss: Number,
  totalProfitLossPercentage: Number,
  lastUpdated: Date
}
```

### Transaction Collection
```javascript
{
  userId: ObjectId,
  type: String, // 'buy' or 'sell'
  symbol: String,
  name: String,
  amount: Number,
  price: Number,
  totalValue: Number,
  fees: Number,
  status: String,
  transactionId: String,
  paymentMethod: String,
  notes: String,
  createdAt: Date,
  updatedAt: Date
}
```

## Security Features
- JWT authentication
- Firebase token verification
- Rate limiting (100 requests per 15 minutes)
- CORS protection
- Helmet.js security headers
- Input validation
- Error handling middleware

## Environment Variables
Create `.env` file with these variables:
- `MONGODB_URI` - MongoDB connection string
- `JWT_SECRET` - Secret for JWT token signing
- `FIREBASE_PROJECT_ID` - Firebase project ID
- `FIREBASE_PRIVATE_KEY` - Firebase private key
- `FIREBASE_CLIENT_EMAIL` - Firebase client email
- And other Firebase configuration variables

## Health Check
Visit `http://localhost:3000/health` to check if the server is running properly.

## Troubleshooting

### Common Issues
1. **MongoDB Connection Error**: Ensure MongoDB is running and connection string is correct
2. **Firebase Authentication Error**: Check Firebase configuration and service account key
3. **CORS Error**: Verify CORS configuration in server.js
4. **JWT Token Error**: Check JWT_SECRET in environment variables

### Logs
The server uses Morgan for request logging. Check console for detailed error messages.

## Production Deployment
1. Set `NODE_ENV=production`
2. Use MongoDB Atlas for production database
3. Configure proper CORS origins
4. Use environment variables for all sensitive data
5. Enable HTTPS
6. Set up proper logging and monitoring
