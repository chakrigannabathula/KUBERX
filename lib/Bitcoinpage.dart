import 'package:flutter/material.dart';
import 'buying page.dart';

class InvestmentsScreen extends StatelessWidget {
  final List<Map<String, String>> assets = [
    {
      "name": "Bitcoin",
      "symbol": "BTC",
      "amount": "0.00123 BTC",
      "value": "₹ 50,000",
      "change": "+2.5% (24h)",
      "image": "https://cryptologos.cc/logos/bitcoin-btc-logo.png?v=029"
    },
    {
      "name": "Ethereum",
      "symbol": "ETH",
      "amount": "0.0123 ETH",
      "value": "₹ 30,000",
      "change": "+1.8% (24h)",
      "image": "https://cryptologos.cc/logos/ethereum-eth-logo.png?v=029"
    },
    {
      "name": "Starknet",
      "symbol": "STRK",
      "amount": "12.34 STRK",
      "value": "₹ 20,000",
      "change": "-0.5% (24h)",
      "image": "https://cryptologos.cc/logos/starknet-strk-logo.png?v=029"
    },
    {
      "name": "USD Coin",
      "symbol": "USDC",
      "amount": "123.45 USDC",
      "value": "₹ 23,456",
      "change": "+0.1% (24h)",
      "image": "https://cryptologos.cc/logos/usd-coin-usdc-logo.png?v=029"
    },
  ];

  InvestmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Your Investments", style: TextStyle(color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [Icon(Icons.notifications_none, color: Colors.black)],
      ),
      backgroundColor: Colors.white,
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCard("Total Value", "84,000.00 INR"),
            SizedBox(height: 8),
            _buildSummaryCard("Profit", "6,000.00 INR"),
            SizedBox(height: 20),
            Text("Your Assets", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: assets.length,
                itemBuilder: (context, index) {
                  final asset = assets[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(asset['image']!),
                      ),
                      title: Text(asset['name']!),
                      subtitle: Text(asset['amount']!),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            asset['value']!,
                            style: TextStyle(fontWeight: FontWeight.w500)
                          ),
                          Text(
                            asset['change']!,
                            style: TextStyle(
                              color: asset['change']!.startsWith('+')
                                  ? Colors.green
                                  : Colors.red,
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
                              coinName: asset['name']!,
                              coinSymbol: asset['symbol']!,
                              coinPrice: asset['value']!,
                              coinChange: asset['change']!,
                              coinImage: asset['image']!,
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
    );
  }

  Widget _buildSummaryCard(String title, String value) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Color(0xFFDFF59D), // light green
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(color: Colors.black54)),
        SizedBox(height: 4),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ]),
    );
  }
}
