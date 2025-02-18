import 'package:flutter/material.dart';
import 'package:ethio_trading_app/data/ethio_data.dart'; // add import

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
    List<Map<String, dynamic>> ethioMarketData = [];

      @override
      void initState() {
        super.initState();
        ethioMarketData = EthioData.generateMockEthioMarketData(); // import ethio_data to use EthioData.
      }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Market'), ),
        
      body: ListView.builder(
        itemCount: ethioMarketData.length,
        itemBuilder: (context, index) {
          final data = ethioMarketData[index];
          // access data using data['name'] and data['symbol']
          return ListTile(
            title: Text(data['name']), // access data using data['name']
            subtitle: Text(data['symbol']), // access data using data['symbol']
            trailing: Column( // remove duplicate title and subtitle parameters.
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('\$${data['price'].toStringAsFixed(2)}'),
                Text('${data['change'].toStringAsFixed(2)}%'),
              ],          
            ),
          );
        },
      ),
    );
  }
}