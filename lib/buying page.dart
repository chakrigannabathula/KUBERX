import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class CryptoDetailScreen extends StatelessWidget {
  final String coinName;
  final String coinSymbol;
  final String coinPrice;
  final String coinChange;
  final String coinImage;

  const CryptoDetailScreen({
    super.key,
    required this.coinName,
    required this.coinSymbol,
    required this.coinPrice,
    required this.coinChange,
    required this.coinImage,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(coinName, style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(coinImage),
                ),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("$coinSymbol/INR", style: TextStyle(fontSize: 16)),
                    SizedBox(height: 4),
                    Text(coinPrice, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    SizedBox(height: 2),
                    Text(coinChange, style: TextStyle(
                      color: coinChange.startsWith('+') ? Colors.green : Colors.red,
                      fontSize: 14
                    )),
                  ],
                ),
              ],
            ),
            SizedBox(height: 20),
            AspectRatio(
              aspectRatio: 1.7,
              child: LineChart(
                LineChartData(
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun"];
                          return Text(months[value.toInt() % months.length]);
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        FlSpot(0, 1.2),
                        FlSpot(1, 1.0),
                        FlSpot(2, 1.3),
                        FlSpot(3, 0.9),
                        FlSpot(4, 1.6),
                        FlSpot(5, 1.1),
                      ],
                      isCurved: true,
                      color: Colors.green.shade700,
                      barWidth: 3,
                      dotData: FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              "About $coinName",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              "$coinName is a digital cryptocurrency that can be traded on various exchanges. View real-time price movements and market trends.",
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            Spacer(),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Buy functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Buy $coinSymbol functionality coming soon!"),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      "Buy $coinSymbol",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Sell functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Sell $coinSymbol functionality coming soon!"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      "Sell $coinSymbol",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
