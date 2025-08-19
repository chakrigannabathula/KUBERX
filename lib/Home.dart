import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'Buyingpage.dart';
import 'accounts.dart';
import 'services/crypto_service.dart';

class InvestmentsScreen extends StatefulWidget {
  @override
  _InvestmentsScreenState createState() => _InvestmentsScreenState();
}

class _InvestmentsScreenState extends State<InvestmentsScreen> {
  late CryptoService _cryptoService;
  List<CryptoData> _cryptoDataList = [];
  bool _isLoading = true;
  double _totalValue = 0.0;
  double _totalProfit = 0.0;

  // Your portfolio holdings (you can modify these based on user's actual holdings)
  final Map<String, double> _holdings = {
    'BTC': 0.00123,
    'ETH': 0.0123,
    'STRK': 12.34,
    'USDC': 123.45,
  };

  @override
  void initState() {
    super.initState();
    _cryptoService = CryptoService();
    _initializeRealTimeData();
  }

  void _initializeRealTimeData() {
    // Start real-time updates for your crypto holdings
    final symbols = _holdings.keys.toList();
    _cryptoService.startRealTimeUpdates(symbols);

    // Listen to real-time updates
    _cryptoService.cryptoStream.listen((cryptoDataList) {
      if (mounted) {
        setState(() {
          _cryptoDataList = cryptoDataList;
          _isLoading = false;
          _calculatePortfolioValue();
        });
      }
    });
  }

  void _calculatePortfolioValue() {
    _totalValue = 0.0;
    _totalProfit = 0.0;

    for (var crypto in _cryptoDataList) {
      final holding = _holdings[crypto.symbol] ?? 0.0;
      final currentValue = crypto.price * holding;
      _totalValue += currentValue;

      // Calculate profit (assuming average buy price is 10% lower for demo)
      final estimatedBuyPrice = crypto.price * 0.9;
      final profit = (crypto.price - estimatedBuyPrice) * holding;
      _totalProfit += profit;
    }
  }

  @override
  void dispose() {
    _cryptoService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Investments", style: TextStyle(color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: const [
          Icon(Icons.notifications_none, color: Colors.black),
          SizedBox(width: 16),
        ],
      ),
      backgroundColor: Colors.white,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AccountScreen()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshData,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryCard("Total Value", "${_totalValue.toStringAsFixed(2)} INR"),
                    const SizedBox(height: 8),
                    _buildSummaryCard("Profit", "${_totalProfit.toStringAsFixed(2)} INR"),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Your Assets", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.fiber_manual_record, color: Colors.green, size: 8),
                              SizedBox(width: 4),
                              Text("Live", style: TextStyle(color: Colors.green, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _cryptoDataList.length,
                        itemBuilder: (context, index) {
                          final crypto = _cryptoDataList[index];
                          final holding = _holdings[crypto.symbol] ?? 0.0;
                          final currentValue = crypto.price * holding;

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundImage: NetworkImage(_getCryptoImageUrl(crypto.symbol)),
                                backgroundColor: Colors.grey.shade200,
                              ),
                              title: Text(crypto.name),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('$holding ${crypto.symbol}'),
                                  if (crypto.isError)
                                    const Text('Data unavailable', style: TextStyle(color: Colors.red, fontSize: 12)),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    crypto.isError ? 'N/A' : '₹${currentValue.toStringAsFixed(2)}',
                                    style: const TextStyle(fontWeight: FontWeight.w500)
                                  ),
                                  Text(
                                    crypto.isError ? 'N/A' : crypto.formattedChange,
                                    style: TextStyle(
                                      color: crypto.isError ? Colors.grey :
                                             crypto.isPositiveChange ? Colors.green : Colors.red,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CryptoDetailScreen(
                                      cryptoData: crypto,
                                      holding: holding,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _refreshData() async {
    final symbols = _holdings.keys.toList();
    final newData = await _cryptoService.getRealTimeCryptoData(symbols);
    if (mounted) {
      setState(() {
        _cryptoDataList = newData;
        _calculatePortfolioValue();
      });
    }
  }

  Widget _buildSummaryCard(String title, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFDFF59D), // light green
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: Colors.black54)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ]),
    );
  }

  String _getCryptoImageUrl(String symbol) {
    final Map<String, String> imageUrls = {
      'BTC': 'https://assets.coingecko.com/coins/images/1/large/bitcoin.png',
      'ETH': 'https://assets.coingecko.com/coins/images/279/large/ethereum.png',
      'STRK': 'https://assets.coingecko.com/coins/images/26433/large/starknet.png',
    };
    return imageUrls[symbol] ?? 'https://cryptologos.cc/logos/bitcoin-btc-logo.png?v=029';
  }
}
