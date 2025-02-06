import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../models/asset.dart';

class HomeScreen extends StatefulWidget {
  final ValueChanged<ThemeMode> onThemeChanged;

  const HomeScreen({super.key, required this.onThemeChanged});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}
class _HomeScreenState extends State<HomeScreen>{
  @override
  Widget build(BuildContext context) {
    final List<Asset> assets = generateMockAssets();
    assets.shuffle();
    final List<Asset> displayedAssets = assets.take(3).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: ListView.builder(
        itemCount: displayedAssets.length,
        itemBuilder: (context, index) {
          final asset = displayedAssets[index];
          return ListTile(
            title: Text(asset.name),
            subtitle: Text(asset.symbol),
            trailing: Text('\$${asset.price.toStringAsFixed(2)}'),
          );
        },
      ),
    );
  }
}