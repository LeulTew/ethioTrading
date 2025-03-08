import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

class MarketSearchWidget extends StatefulWidget {
  final Function(String) onSearch;
  final Function() onClear;

  const MarketSearchWidget({
    super.key,
    required this.onSearch,
    required this.onClear,
  });

  @override
  State<MarketSearchWidget> createState() => _MarketSearchWidgetState();
}

class _MarketSearchWidgetState extends State<MarketSearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 56,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: _isSearching
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // Search icon
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Icon(
              Icons.search,
              color: _isSearching
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),

          // Search input
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: languageProvider.translate('search_markets'),
                border: InputBorder.none,
                hintStyle: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _isSearching = value.isNotEmpty;
                });
                widget.onSearch(value);
              },
              onTap: () {
                setState(() {
                  _isSearching = true;
                });
              },
            ),
          ),

          // Clear button
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _isSearching = false;
                });
                widget.onClear();
              },
            ),
        ],
      ),
    );
  }
}
