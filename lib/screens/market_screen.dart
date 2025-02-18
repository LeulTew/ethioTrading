import 'package:flutter/material.dart';
import '../data/mock_data.dart';

class MarketScreen extends StatelessWidget {
  const MarketScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final assets = generateMockAssets();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Market'),
      ),
      body: ListView.builder(
        itemCount: assets.length,
        itemBuilder: (context, index) {
          final asset = assets[index];
          return ListTile(
            title: Text(asset.name),
            subtitle: Text(asset.symbol),
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('\$${asset.price.toStringAsFixed(2)}'),
                Text(
                  '${asset.change.toStringAsFixed(2)}%',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
