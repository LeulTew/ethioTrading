import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../data/ethio_data.dart';
import '../utils/ethiopian_utils.dart';
import '../providers/language_provider.dart';
import 'stock_detail_screen.dart';
import '../theme/app_theme.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> ethioMarketData = [];
  String _selectedSector = 'All';
  String _searchQuery = '';
  late Timer _marketStatusTimer;
  bool _isMarketOpen = false;
  bool _isLoading = true;
  int _selectedTimeRange = 1; // 0: 1D, 1: 1W, 2: 1M, 3: 3M, 4: 1Y, 5: ALL

  @override
  void initState() {
    super.initState();
    _initData();
    _tabController = TabController(length: 3, vsync: this);
    _updateMarketStatus();
    _marketStatusTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _updateMarketStatus(),
    );
  }

  Future<void> _initData() async {
    await Future.delayed(
        const Duration(milliseconds: 500)); // Simulate network delay
    setState(() {
      ethioMarketData = EthioData.generateMockEthioMarketData();
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _marketStatusTimer.cancel();
    super.dispose();
  }

  void _updateMarketStatus() {
    setState(() {
      _isMarketOpen = EthiopianMarketHours.isMarketOpen();
    });
  }

  List<Map<String, dynamic>> get filteredData {
    return ethioMarketData.where((data) {
      final matchesSearch =
          data['name'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
              data['symbol'].toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesSector =
          _selectedSector == 'All' || data['sector'] == _selectedSector;
      return matchesSearch && matchesSector;
    }).toList();
  }

  // Market summary data
  Map<String, dynamic> get marketSummary {
    double totalVolume = 0;
    int gainers = 0;
    int losers = 0;

    for (var stock in ethioMarketData) {
      totalVolume += (stock['volume'] as num).toDouble();
      if ((stock['change'] as double) > 0) {
        gainers++;
      } else if ((stock['change'] as double) < 0) {
        losers++;
      }
    }

    return {
      'totalVolume': totalVolume,
      'gainers': gainers,
      'losers': losers,
      'unchanged': ethioMarketData.length - gainers - losers,
    };
  }

  Widget _buildSearchBar(ThemeData theme, LanguageProvider lang) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(33),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          decoration: InputDecoration(
            hintText: lang.translate('search_stocks'),
            hintStyle: GoogleFonts.spaceGrotesk(
              color: theme.hintColor,
            ),
            prefixIcon: Icon(Icons.search, color: theme.colorScheme.primary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.transparent,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onChanged: (value) => setState(() => _searchQuery = value),
        ),
      ),
    );
  }

  Widget _buildSectorFilter(LanguageProvider lang) {
    return Container(
      height: 40,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildFilterChip('All', lang.translate('all_sectors')),
          const SizedBox(width: 8),
          ...EthioData.getSectors().map((sector) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildFilterChip(
                    sector, lang.translate(sector.toLowerCase())),
              )),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String sector, String label) {
    final theme = Theme.of(context);
    final isSelected = sector == _selectedSector;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isSelected
            ? theme.colorScheme.primary.withAlpha(51)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected
              ? theme.colorScheme.primary
              : Colors.grey.withAlpha(77),
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: () => setState(() => _selectedSector = sector),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMarketSummary(ThemeData theme, LanguageProvider lang) {
    final summary = marketSummary;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppTheme.primaryGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGradient.last.withAlpha(102),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                lang.translate('market_summary'),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              _buildTimeRangeSelector(theme),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem(
                icon: Icons.arrow_upward,
                label: lang.translate('gainers'),
                value: '${summary['gainers']}',
                valueColor: AppTheme.bullish,
                bgColor: Colors.white.withAlpha(38),
              ),
              _buildSummaryItem(
                icon: Icons.arrow_downward,
                label: lang.translate('losers'),
                value: '${summary['losers']}',
                valueColor: AppTheme.bearish,
                bgColor: Colors.white.withAlpha(38),
              ),
              _buildSummaryItem(
                icon: Icons.show_chart,
                label: lang.translate('volume'),
                value:
                    '${(summary['totalVolume'] / 1000000).toStringAsFixed(1)}M',
                valueColor: Colors.white,
                bgColor: Colors.white.withAlpha(38),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required String value,
    required Color valueColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: valueColor, size: 14),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withAlpha(204),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRangeSelector(ThemeData theme) {
    final ranges = ['1D', '1W', '1M', '3M', '1Y', 'ALL'];

    return Container(
      height: 26,
      width: 180, // Fixed width to prevent overflow
      decoration: BoxDecoration(
        color: Colors.white
            .withAlpha(38), // Using withAlpha instead of withOpacity
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: List.generate(ranges.length, (index) {
          final isSelected = index == _selectedTimeRange;

          return Expanded(
            // Make each item take equal width
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTimeRange = index;
                  // Add functionality for range change
                  _updateDataForTimeRange(ranges[index]);
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center, // Center text
                child: Text(
                  ranges[index],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? AppTheme.primaryGradient.first
                        : Colors.white,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // Add time range functionality
  void _updateDataForTimeRange(String range) {
    // In a real app, this would fetch data for the selected time range
    // For this demo, we'll just simulate a data update
    setState(() {
      _isLoading = true;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        _isLoading = false;
        // Here you would update the market data based on the selected range
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(theme, lang),
            _buildMarketStatusBanner(theme, lang),
            _buildMarketSummary(theme, lang),
            _buildSearchBar(theme, lang),
            _buildSectorFilter(lang),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredData.length,
                      itemBuilder: (context, index) {
                        return _buildStockCard(filteredData[index], theme);
                      },
                    ),
            ),
          ],
        ),
      ),
      // Keeping only one bottom navigation bar
    );
  }

  Widget _buildHeader(ThemeData theme, LanguageProvider lang) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            lang.translate('market'),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 24, // Reduced from 28 to 24
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.notifications_none,
                    color: theme.colorScheme.primary),
                onPressed: () =>
                    _showNotifications(context), // Added functionality
                tooltip: 'Notifications',
              ),
              IconButton(
                icon: Icon(Icons.more_vert, color: theme.colorScheme.primary),
                onPressed: () =>
                    _showOptionsMenu(context), // Added functionality
                tooltip: 'More options',
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Add notification functionality
  void _showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Notifications',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Clear all'),
                ),
              ],
            ),
            const Divider(),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppTheme.bullish,
                radius: 20,
                child: Icon(Icons.trending_up, color: Colors.white),
              ),
              title: const Text('Market Alert'),
              subtitle: const Text('ESE index up by 2.3% today'),
              trailing:
                  Text('2h ago', style: TextStyle(color: Colors.grey[600])),
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppTheme.bearish,
                radius: 20,
                child: Icon(Icons.trending_down, color: Colors.white),
              ),
              title: const Text('Price Alert'),
              subtitle: const Text('COOP down by 5% in the last hour'),
              trailing:
                  Text('5h ago', style: TextStyle(color: Colors.grey[600])),
            ),
          ],
        ),
      ),
    );
  }

  // Add options menu functionality
  void _showOptionsMenu(BuildContext context) {
    final theme = Theme.of(context);

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
          MediaQuery.of(context).size.width - 40, 80, 20, 0),
      items: [
        PopupMenuItem(
          value: 'filter',
          child: Row(
            children: [
              Icon(Icons.filter_list, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              const Text('Advanced Filters'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'refresh',
          child: Row(
            children: [
              Icon(Icons.refresh, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              const Text('Refresh Data'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'settings',
          child: Row(
            children: [
              Icon(Icons.settings, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              const Text('Market Settings'),
            ],
          ),
        ),
      ],
      elevation: 8,
    ).then((value) {
      if (value == 'refresh') {
        setState(() {
          _isLoading = true;
        });
        _initData();
      } else if (value == 'filter') {
        // Show advanced filter dialog
      } else if (value == 'settings') {
        // Navigate to market settings
      }
    });
  }

  Widget _buildMarketStatusBanner(ThemeData theme, LanguageProvider lang) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isMarketOpen
              ? AppTheme.successGradient
              : [AppTheme.bearish.withAlpha(179), AppTheme.bearish],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _isMarketOpen
                ? AppTheme.successGradient.last.withAlpha(76)
                : AppTheme.bearish.withAlpha(76),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withAlpha(128),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            _isMarketOpen
                ? lang.translate('market_open')
                : lang.translate('market_closed'),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(51),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              EthiopianMarketHours.getMarketStatus(),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockCard(Map<String, dynamic> stock, ThemeData theme) {
    final priceChange = stock['change'] as double;
    final isPositive = priceChange >= 0;
    final changeColor = isPositive ? AppTheme.bullish : AppTheme.bearish;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StockDetailScreen(stockData: stock),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary.withAlpha(179),
                      theme.colorScheme.primary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    stock['symbol'].substring(0, 1),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stock['symbol'],
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stock['name'],
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          stock['sector'] == 'Banking'
                              ? Icons.account_balance
                              : stock['sector'] == 'Technology'
                                  ? Icons.computer
                                  : stock['sector'] == 'Manufacturing'
                                      ? Icons.precision_manufacturing
                                      : Icons.business,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          stock['sector'],
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${stock['price'].toStringAsFixed(2)}',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: changeColor.withAlpha(38),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPositive
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          size: 14,
                          color: changeColor,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${isPositive ? '+' : ''}${(priceChange * 100).toStringAsFixed(2)}%',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: changeColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Vol: ${(stock['volume'] / 1000).round()}K',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
