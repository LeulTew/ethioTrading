import 'package:flutter/material.dart';
import 'package:ethio_trading_app/data/ethio_data.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
    List<EthioMarketData> ethioMarketData = [];

      @override
      void initState() {
        super.initState();
        ethioMarketData = generateMockEthioMarketData();
      }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Market'),
      ),
      body: ListView.builder(
        itemCount: ethioMarketData.length,
        itemBuilder: (context, index) {
          final data = ethioMarketData[index];
          return ListTile(
            title: Text(data.name),
            subtitle: Text(data.symbol),
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('\$${data.price.toStringAsFixed(2)}'),
                Text(
                  '${data.change.toStringAsFixed(2)}%',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}