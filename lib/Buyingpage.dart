import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'services/crypto_service.dart';

class CryptoDetailScreen extends StatefulWidget {
  final CryptoData cryptoData;
  final double holding;

  const CryptoDetailScreen({
    super.key,
    required this.cryptoData,
    required this.holding,
  });

  @override
  _CryptoDetailScreenState createState() => _CryptoDetailScreenState();
}

class _CryptoDetailScreenState extends State<CryptoDetailScreen> {
  late CryptoService _cryptoService;
  CryptoData? _currentData;
  List<PricePoint> _historicalData = [];
  bool _isLoadingChart = true;
  String _selectedTimeframe = '7D';

  @override
  void initState() {
    super.initState();
    _cryptoService = CryptoService();
    _currentData = widget.cryptoData;
    _loadHistoricalData();
    _startRealTimeUpdates();
  }

  void _startRealTimeUpdates() {
    _cryptoService.startRealTimeUpdates([widget.cryptoData.symbol]);
    _cryptoService.cryptoStream.listen((cryptoList) {
      if (mounted && cryptoList.isNotEmpty) {
        setState(() {
          _currentData = cryptoList.first;
        });
      }
    });
  }

  void _loadHistoricalData() async {
    setState(() {
      _isLoadingChart = true;
    });

    final days = _getTimeframeDays(_selectedTimeframe);
    print('🔄 Loading historical data for ${widget.cryptoData.symbol} - ${_selectedTimeframe} ($days days)');

    try {
      final data = await _cryptoService.getHistoricalData(widget.cryptoData.symbol, days: days);
      if (mounted) {
        setState(() {
          _historicalData = data;
          _isLoadingChart = false;
        });
        print('✅ Loaded ${data.length} data points for ${_selectedTimeframe}');
      }
    } catch (e) {
      print('❌ Error loading historical data: $e');
      if (mounted) {
        setState(() {
          _historicalData = [];
          _isLoadingChart = false;
        });
      }
    }
  }

  int _getTimeframeDays(String timeframe) {
    switch (timeframe) {
      case '24H': return 1;  // Fixed: was '1D', now matches UI
      case '7D': return 7;
      case '1M': return 30;
      case '3M': return 90;
      case '1Y': return 365;
      default: return 7;
    }
  }

  @override
  void dispose() {
    _cryptoService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentPrice = _currentData?.price ?? widget.cryptoData.price;
    final currentChange = _currentData?.formattedChange ?? widget.cryptoData.formattedChange;
    final isPositive = _currentData?.isPositiveChange ?? widget.cryptoData.isPositiveChange;
    final currentValue = currentPrice * widget.holding;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_currentData?.name ?? widget.cryptoData.name,
                   style: const TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
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
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Price Section
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage(_getCryptoImageUrl(widget.cryptoData.symbol)),
                    backgroundColor: Colors.grey.shade200,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("${widget.cryptoData.symbol}/USD",
                             style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                        const SizedBox(height: 4),
                        Text(_currentData?.isError == true ? 'Price Unavailable' :
                             '\$${currentPrice.toStringAsFixed(2)}',
                             style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(currentChange,
                                 style: TextStyle(
                                   color: isPositive ? Colors.green : Colors.red,
                                   fontSize: 14
                                 )),
                            SizedBox(width: 8),
                            Text("(24h)", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text("Your Holdings", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      Text("${widget.holding} ${widget.cryptoData.symbol}",
                           style: TextStyle(fontWeight: FontWeight.w600)),
                      Text("\$${currentValue.toStringAsFixed(2)}",
                           style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),

              SizedBox(height: 20),

              // Timeframe Selector
              Row(
                children: ['24H', '7D', '1M', '3M', '1Y'].map((timeframe) {
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedTimeframe = timeframe;
                          _isLoadingChart = true;
                        });
                        _loadHistoricalData();
                      },
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 4),
                        padding: EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _selectedTimeframe == timeframe ? Colors.black : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          timeframe,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _selectedTimeframe == timeframe ? Colors.white : Colors.black,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              SizedBox(height: 20),

              // Chart Section
              Container(
                height: 250,
                child: _isLoadingChart
                    ? Center(child: CircularProgressIndicator())
                    : _historicalData.isEmpty
                        ? Center(child: Text("Chart data unavailable", style: TextStyle(color: Colors.grey[600])))
                        : AspectRatio(
                            aspectRatio: 1.7,
                            child: LineChart(
                              LineChartData(
                                titlesData: FlTitlesData(
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      interval: _historicalData.length / 5,
                                      getTitlesWidget: (value, meta) {
                                        if (value.toInt() >= 0 && value.toInt() < _historicalData.length) {
                                          final date = _historicalData[value.toInt()].timestamp;
                                          return Text(
                                            "${date.day}/${date.month}",
                                            style: TextStyle(fontSize: 10),
                                          );
                                        }
                                        return Text("");
                                      },
                                    ),
                                  ),
                                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                ),
                                borderData: FlBorderData(show: false),
                                gridData: const FlGridData(show: false),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: _historicalData.asMap().entries.map((entry) {
                                      return FlSpot(entry.key.toDouble(), entry.value.price);
                                    }).toList(),
                                    isCurved: true,
                                    color: isPositive ? Colors.green.shade700 : Colors.red.shade700,
                                    barWidth: 3,
                                    dotData: const FlDotData(show: false),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      color: (isPositive ? Colors.green : Colors.red).withValues(alpha: 0.1),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
              ),

              const SizedBox(height: 20),

              // Stats Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Market Stats", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatItem("24h Volume", _currentData?.isError == true ? 'N/A' :
                                     '\$${(_currentData?.volume24h ?? 0).toStringAsFixed(0)}'),
                        _buildStatItem("Market Cap", _currentData?.isError == true ? 'N/A' :
                                     '\$${(_currentData?.marketCap ?? 0).toStringAsFixed(0)}'),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatItem("Last Updated",
                                     _currentData?.lastUpdated.toLocal().toString().substring(11, 19) ?? 'N/A'),
                        _buildStatItem("24h Change", currentChange),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20),

              // About Section
              Text("About ${widget.cryptoData.name}",
                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Text(
                "${widget.cryptoData.name} is a digital cryptocurrency that can be traded on various exchanges. "
                "It is known for its innovative technology and potential for high returns. ",
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),

              SizedBox(height: 30),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showBuyDialog(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text("Buy ${widget.cryptoData.symbol}",
                               style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showSellDialog(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text("Sell ${widget.cryptoData.symbol}",
                               style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        Text(value, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      ],
    );
  }

  Future<void> _refreshData() async {
    final newData = await _cryptoService.getSingleCryptoData(widget.cryptoData.symbol);
    if (mounted && newData != null) {
      setState(() {
        _currentData = newData;
      });
    }
    _loadHistoricalData();
  }

  void _showBuyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Buy ${widget.cryptoData.symbol}"),
        content: Text("Real-time price: \$${(_currentData?.price ?? 0).toStringAsFixed(2)}\n\nBuy functionality coming soon!"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("OK")),
        ],
      ),
    );
  }

  void _showSellDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Sell ${widget.cryptoData.symbol}"),
        content: Text("Your holdings: ${widget.holding} ${widget.cryptoData.symbol}\n"
                     "Current value: \$${((_currentData?.price ?? 0) * widget.holding).toStringAsFixed(2)}\n\n"
                     "Sell functionality coming soon!"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("OK")),
        ],
      ),
    );
  }

  String _getCryptoImageUrl(String symbol) {
    final Map<String, String> imageUrls = {
      'BTC': 'https://assets.coingecko.com/coins/images/1/large/bitcoin.png',
      'ETH': 'https://assets.coingecko.com/coins/images/279/large/ethereum.png',
      'STRK': 'https://assets.coingecko.com/coins/images/26433/large/starknet.png',
      'USDC': 'https://assets.coingecko.com/coins/images/6319/large/USD_Coin_icon.png',
    };
    return imageUrls[symbol] ?? 'https://assets.coingecko.com/coins/images/1/large/bitcoin.png';
  }
}
