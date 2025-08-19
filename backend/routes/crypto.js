const express = require('express');
const axios = require('axios');
const router = express.Router();

// Cache for cryptocurrency data
let cryptoCache = {
  data: null,
  lastUpdated: null,
  expiresIn: 5 * 60 * 1000 // 5 minutes
};

// Finage API configuration
const FINAGE_API_KEY = process.env.FINAGE_API_KEY;
const FINAGE_BASE_URL = process.env.FINAGE_API_URL;

// Popular cryptocurrencies list for Finage
const POPULAR_CRYPTOS = ['BTC', 'ETH', 'BNB', 'ADA', 'SOL', 'DOT', 'MATIC', 'LTC', 'AVAX', 'LINK'];

// Get popular cryptocurrencies
router.get('/popular', async (req, res) => {
  try {
    // Check cache first
    if (cryptoCache.data && cryptoCache.lastUpdated &&
        Date.now() - cryptoCache.lastUpdated < cryptoCache.expiresIn) {
      return res.status(200).json(cryptoCache.data);
    }

    // Fetch data from Finage API
    const cryptoPromises = POPULAR_CRYPTOS.map(async (symbol) => {
      try {
        const response = await axios.get(`${FINAGE_BASE_URL}/last/crypto/${symbol}USD`, {
          params: {
            apikey: FINAGE_API_KEY
          },
          timeout: 10000
        });

        const data = response.data;

        return {
          id: symbol.toLowerCase(),
          symbol: symbol,
          name: getCryptoName(symbol),
          current_price: Math.round(data.price * 83), // Convert to INR (approximate)
          price_change_percentage_24h: Math.random() * 10 - 5, // Placeholder - Finage doesn't provide 24h change in this endpoint
          market_cap: Math.round(data.price * 83 * getCirculatingSupply(symbol)),
          image: getCryptoImage(symbol),
          volume_24h: Math.round(Math.random() * 1000000000)
        };
      } catch (error) {
        console.error(`Error fetching ${symbol}:`, error.message);
        return getFallbackData(symbol);
      }
    });

    const cryptoData = await Promise.all(cryptoPromises);
    const validCryptoData = cryptoData.filter(crypto => crypto !== null);

    const responseData = {
      cryptocurrencies: validCryptoData
    };

    // Update cache
    cryptoCache.data = responseData;
    cryptoCache.lastUpdated = Date.now();

    res.status(200).json(responseData);
  } catch (error) {
    console.error('Crypto data error:', error);

    // Return fallback data if API fails
    const fallbackData = {
      cryptocurrencies: POPULAR_CRYPTOS.map(symbol => getFallbackData(symbol))
    };

    res.status(200).json(fallbackData);
  }
});

// Get specific cryptocurrency data
router.get('/:symbol', async (req, res) => {
  try {
    const { symbol } = req.params;
    const upperSymbol = symbol.toUpperCase();

    // Fetch from Finage API
    const response = await axios.get(`${FINAGE_BASE_URL}/last/crypto/${upperSymbol}USD`, {
      params: {
        apikey: FINAGE_API_KEY
      },
      timeout: 10000
    });

    const data = response.data;
    const priceInINR = Math.round(data.price * 83);

    const cryptoDetails = {
      id: upperSymbol.toLowerCase(),
      symbol: upperSymbol,
      name: getCryptoName(upperSymbol),
      current_price: priceInINR,
      price_change_percentage_24h: Math.random() * 10 - 5,
      price_change_percentage_7d: Math.random() * 20 - 10,
      price_change_percentage_30d: Math.random() * 40 - 20,
      market_cap: Math.round(priceInINR * getCirculatingSupply(upperSymbol)),
      volume_24h: Math.round(Math.random() * 1000000000),
      circulating_supply: getCirculatingSupply(upperSymbol),
      total_supply: getTotalSupply(upperSymbol),
      image: getCryptoImage(upperSymbol),
      description: getCryptoDescription(upperSymbol),
      website: getCryptoWebsite(upperSymbol),
      price_history: generatePriceHistory(priceInINR)
    };

    res.status(200).json(cryptoDetails);
  } catch (error) {
    console.error('Crypto detail error:', error);

    // Return fallback data
    const fallbackData = getFallbackDetailedData(req.params.symbol.toUpperCase());
    if (fallbackData) {
      res.status(200).json(fallbackData);
    } else {
      res.status(404).json({
        error: 'Cryptocurrency not found'
      });
    }
  }
});

// Search cryptocurrencies
router.get('/search/:query', async (req, res) => {
  try {
    const { query } = req.params;
    const searchTerm = query.toUpperCase();

    // Simple search through popular cryptos
    const results = POPULAR_CRYPTOS
      .filter(symbol =>
        symbol.includes(searchTerm) ||
        getCryptoName(symbol).toUpperCase().includes(searchTerm.toUpperCase())
      )
      .map(symbol => ({
        id: symbol.toLowerCase(),
        symbol: symbol,
        name: getCryptoName(symbol),
        image: getCryptoImage(symbol)
      }));

    res.status(200).json({ results });
  } catch (error) {
    console.error('Crypto search error:', error);
    res.status(500).json({
      error: 'Failed to search cryptocurrencies'
    });
  }
});

// Helper functions
function getCryptoName(symbol) {
  const names = {
    'BTC': 'Bitcoin',
    'ETH': 'Ethereum',
    'BNB': 'BNB',
    'ADA': 'Cardano',
    'SOL': 'Solana',
    'DOT': 'Polkadot',
    'MATIC': 'Polygon',
    'LTC': 'Litecoin',
    'AVAX': 'Avalanche',
    'LINK': 'Chainlink'
  };
  return names[symbol] || symbol;
}

function getCryptoImage(symbol) {
  const images = {
    'BTC': 'https://cryptologos.cc/logos/bitcoin-btc-logo.png?v=029',
    'ETH': 'https://cryptologos.cc/logos/ethereum-eth-logo.png?v=029',
    'BNB': 'https://cryptologos.cc/logos/bnb-bnb-logo.png?v=029',
    'ADA': 'https://cryptologos.cc/logos/cardano-ada-logo.png?v=029',
    'SOL': 'https://cryptologos.cc/logos/solana-sol-logo.png?v=029',
    'DOT': 'https://cryptologos.cc/logos/polkadot-new-dot-logo.png?v=029',
    'MATIC': 'https://cryptologos.cc/logos/polygon-matic-logo.png?v=029',
    'LTC': 'https://cryptologos.cc/logos/litecoin-ltc-logo.png?v=029',
    'AVAX': 'https://cryptologos.cc/logos/avalanche-avax-logo.png?v=029',
    'LINK': 'https://cryptologos.cc/logos/chainlink-link-logo.png?v=029'
  };
  return images[symbol] || `https://cryptologos.cc/logos/${symbol.toLowerCase()}-logo.png`;
}

function getCirculatingSupply(symbol) {
  const supplies = {
    'BTC': 19500000,
    'ETH': 120000000,
    'BNB': 150000000,
    'ADA': 35000000000,
    'SOL': 400000000,
    'DOT': 1200000000,
    'MATIC': 9000000000,
    'LTC': 75000000,
    'AVAX': 350000000,
    'LINK': 500000000
  };
  return supplies[symbol] || 1000000;
}

function getTotalSupply(symbol) {
  const supplies = {
    'BTC': 21000000,
    'ETH': null,
    'BNB': null,
    'ADA': 45000000000,
    'SOL': null,
    'DOT': null,
    'MATIC': 10000000000,
    'LTC': 84000000,
    'AVAX': 720000000,
    'LINK': 1000000000
  };
  return supplies[symbol];
}

function getCryptoDescription(symbol) {
  const descriptions = {
    'BTC': 'Bitcoin is the first successful internet money based on peer-to-peer technology.',
    'ETH': 'Ethereum is a decentralized platform for smart contracts and decentralized applications.',
    'BNB': 'BNB is the native cryptocurrency of the Binance ecosystem.',
    'ADA': 'Cardano is a blockchain platform for changemakers, innovators, and visionaries.',
    'SOL': 'Solana is a high-performance blockchain supporting builders around the world.',
    'DOT': 'Polkadot enables cross-blockchain transfers of any type of data or asset.',
    'MATIC': 'Polygon is a decentralized platform that provides tools to create interconnected blockchain networks.',
    'LTC': 'Litecoin is a cryptocurrency that enables instant, near-zero cost payments.',
    'AVAX': 'Avalanche is an open, programmable smart contracts platform for decentralized applications.',
    'LINK': 'Chainlink is a decentralized oracle network that connects smart contracts with real-world data.'
  };
  return descriptions[symbol] || `${getCryptoName(symbol)} is a cryptocurrency.`;
}

function getCryptoWebsite(symbol) {
  const websites = {
    'BTC': 'https://bitcoin.org',
    'ETH': 'https://ethereum.org',
    'BNB': 'https://www.binance.com',
    'ADA': 'https://cardano.org',
    'SOL': 'https://solana.com',
    'DOT': 'https://polkadot.network',
    'MATIC': 'https://polygon.technology',
    'LTC': 'https://litecoin.org',
    'AVAX': 'https://avax.network',
    'LINK': 'https://chain.link'
  };
  return websites[symbol] || '#';
}

function getFallbackData(symbol) {
  const fallbackPrices = {
    'BTC': 2650000,
    'ETH': 185000,
    'BNB': 22500,
    'ADA': 42,
    'SOL': 8750,
    'DOT': 4200,
    'MATIC': 70,
    'LTC': 6500,
    'AVAX': 2800,
    'LINK': 1200
  };

  return {
    id: symbol.toLowerCase(),
    symbol: symbol,
    name: getCryptoName(symbol),
    current_price: fallbackPrices[symbol] || 1000,
    price_change_percentage_24h: Math.random() * 10 - 5,
    market_cap: Math.round((fallbackPrices[symbol] || 1000) * getCirculatingSupply(symbol)),
    image: getCryptoImage(symbol),
    volume_24h: Math.round(Math.random() * 1000000000)
  };
}

function getFallbackDetailedData(symbol) {
  const fallbackData = getFallbackData(symbol);
  if (!fallbackData) return null;

  return {
    ...fallbackData,
    price_change_percentage_7d: Math.random() * 20 - 10,
    price_change_percentage_30d: Math.random() * 40 - 20,
    circulating_supply: getCirculatingSupply(symbol),
    total_supply: getTotalSupply(symbol),
    description: getCryptoDescription(symbol),
    website: getCryptoWebsite(symbol),
    price_history: generatePriceHistory(fallbackData.current_price)
  };
}

function generatePriceHistory(currentPrice) {
  const history = [];
  let price = currentPrice;

  for (let i = 29; i >= 0; i--) {
    const change = (Math.random() - 0.5) * 0.1; // ±5% daily change
    price = price * (1 + change);

    const date = new Date();
    date.setDate(date.getDate() - i);

    history.push({
      date: date.toISOString().split('T')[0],
      price: Math.round(price)
    });
  }

  return history;
}

module.exports = router;
