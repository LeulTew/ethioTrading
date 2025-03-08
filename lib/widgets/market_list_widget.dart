import 'package:flutter/material.dart';
import '../models/asset.dart';

class MarketListWidget extends StatelessWidget {
  final List<Asset> assets;
  final Function(Asset) onAssetTap;
  final bool showFullList;
  final int maxItems;

  const MarketListWidget({
    super.key,
    required this.assets,
    required this.onAssetTap,
    this.showFullList = false,
    this.maxItems = 5,
  });

  @override
  Widget build(BuildContext context) {
    final displayAssets =
        showFullList ? assets : assets.take(maxItems).toList();

    return ListView.builder(
      itemCount: displayAssets.length,
      itemBuilder: (context, index) {
        final asset = displayAssets[index];
        return _buildAssetCard(context, asset);
      },
    );
  }

  Widget _buildAssetCard(BuildContext context, Asset asset) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: () => onAssetTap(asset),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Symbol and name
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      asset.symbol,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      asset.name,
                      style: theme.textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Price
              Expanded(
                flex: 2,
                child: Text(
                  asset.formattedPrice,
                  style: theme.textTheme.titleMedium,
                  textAlign: TextAlign.right,
                ),
              ),

              // Change and change percent
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      asset.formattedChange,
                      style: TextStyle(
                        color: asset.isUp ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: asset.isUp
                            ? Colors.green.withAlpha(51) // 0.2 * 255 = 51
                            : Colors.red.withAlpha(51), // 0.2 * 255 = 51
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        asset.formattedChangePercent,
                        style: TextStyle(
                          fontSize: 12,
                          color: asset.isUp ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
