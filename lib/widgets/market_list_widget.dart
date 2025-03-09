import 'package:flutter/material.dart';
import '../models/asset.dart';
import '../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class MarketListWidget extends StatelessWidget {
  final List<Asset> assets;
  final Function(Asset) onAssetTap;
  final bool showFullList;
  final int maxItems;
  final Set<String> favoriteAssets;
  final Function(String) onFavoriteToggle;

  const MarketListWidget({
    super.key,
    required this.assets,
    required this.onAssetTap,
    this.showFullList = false,
    this.maxItems = 5,
    this.favoriteAssets = const {},
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    final displayAssets =
        showFullList ? assets : assets.take(maxItems).toList();

    return ListView.builder(
      shrinkWrap: true, // Added to prevent overflow in nested scrolling context
      physics:
          const NeverScrollableScrollPhysics(), // Let parent handle scrolling
      itemCount: displayAssets.length,
      itemBuilder: (context, index) {
        final asset = displayAssets[index];
        return _buildAssetCard(context, asset);
      },
    );
  }

  Widget _buildAssetCard(BuildContext context, Asset asset) {
    final theme = Theme.of(context);
    final isFavorite = favoriteAssets.contains(asset.symbol);
    final isPositive = asset.change >= 0;
    final changeColor = isPositive ? AppTheme.bullish : AppTheme.bearish;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: () => onAssetTap(asset),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Favorite star icon
              IconButton(
                icon: Icon(
                  isFavorite ? Icons.star : Icons.star_border,
                  color: isFavorite ? Colors.amber : Colors.grey,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => onFavoriteToggle(asset.symbol),
              ),
              const SizedBox(width: 8),

              // Symbol and name
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      asset.symbol,
                      style: GoogleFonts.spaceGrotesk(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      asset.name,
                      style: TextStyle(
                        color: theme.textTheme.bodySmall?.color,
                        fontSize: 12,
                      ),
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
                  textAlign: TextAlign.right,
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              // Change and change percent
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: changeColor.withValues(alpha:0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        asset.formattedChangePercent,
                        style: TextStyle(
                          color: changeColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      asset.formattedChange,
                      style: TextStyle(
                        color: changeColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Trade button
              IconButton(
                icon: const Icon(Icons.trending_up, color: Colors.blue),
                onPressed: () => onAssetTap(asset),
                tooltip: 'Trade',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
