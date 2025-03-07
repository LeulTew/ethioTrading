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
    double prevDayVolume = 0;
    int gainers = 0;
    int losers = 0;

    for (var stock in ethioMarketData) {
      totalVolume += (stock['volume'] as num).toDouble();
      prevDayVolume += (stock['prevDayVolume'] as num? ?? 0).toDouble();
      if ((stock['change'] as double) > 0) {
        gainers++;
      } else if ((stock['change'] as double) < 0) {
        losers++;
      }
    }

    double volumeChange = prevDayVolume > 0
        ? ((totalVolume - prevDayVolume) / prevDayVolume) * 100
        : 0;

    return {
      'volume': totalVolume.toStringAsFixed(2),
      'volumeChange': volumeChange.toStringAsFixed(1),
      'gainers': gainers,
      'losers': losers,
      'unchanged': ethioMarketData.length - gainers - losers,
      'marketBreadth': gainers / (gainers + losers)
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
              color: Colors.black.withValues(alpha: 0.13),
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
                child: _buildFilterChip(sector, lang.translate(sector)),
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
            ? theme.colorScheme.primary.withValues(alpha: 0.51)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected
              ? theme.colorScheme.primary
              : Colors.grey.withValues(alpha: 0.77),
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
          colors: [
            Color(0xFF4A00E0), // Deep purple
            Color(0xFF2563EB), // Vibrant blue
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                lang.translate('Summary'),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
              _buildTimeRangeSelector(theme),
            ],
          ),
          const SizedBox(height: 16),
          // Reorganized layout with items in a row with proper spacing
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Volume
              Expanded(
                flex: 3,
                child: _buildSummaryItem(
                  icon: Icons.bar_chart,
                  label: lang.translate('volume'),
                  value: '${summary['volume']}M',
                  valueColor: double.parse(summary['volumeChange']) >= 0
                      ? AppTheme.bullish
                      : AppTheme.bearish,
                  bgColor: Colors.white.withValues(alpha: 0.15),
                ),
              ),
              const SizedBox(width: 8),
              // Advancers
              Expanded(
                flex: 2,
                child: _buildSummaryItem(
                  icon: Icons.arrow_upward,
                  label: lang.translate('gainers'),
                  value: '${summary['gainers']}',
                  valueColor: AppTheme.bullish,
                  bgColor: Colors.white.withValues(alpha: 0.15),
                ),
              ),
              const SizedBox(width: 8),
              // Decliners
              Expanded(
                flex: 2,
                child: _buildSummaryItem(
                  icon: Icons.arrow_downward,
                  label: lang.translate('losers'),
                  value: '${summary['losers']}',
                  valueColor: AppTheme.bearish,
                  bgColor: Colors.white.withValues(alpha: 0.15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Market breadth in a separate row
          _buildSummaryItem(
            icon: Icons.analytics,
            label: lang.translate('market_breadth'),
            value: '${(summary['marketBreadth'] * 100).toStringAsFixed(1)}%',
            valueColor: summary['marketBreadth'] >= 0.5
                ? AppTheme.bullish
                : AppTheme.bearish,
            bgColor: Colors.white.withValues(alpha: 0.15),
            isFullWidth: true,
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
    bool isFullWidth = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      width: isFullWidth ? double.infinity : null,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: isFullWidth ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: isFullWidth ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: valueColor, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
              Text(
                value,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: valueColor,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRangeSelector(ThemeData theme) {
    final ranges = ['1D', '1W', '1M', '3M', '1Y', 'ALL'];

    return Container(
      height: 28,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.3), width: 0.5),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(ranges.length, (index) {
            final isSelected = index == _selectedTimeRange;

            return GestureDetector(
              onTap: () => setState(() => _selectedTimeRange = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  ranges[index],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? AppTheme.primaryGradient.first
                        : Colors.white,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
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
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.notifications_none,
                    color: theme.colorScheme.primary),
                onPressed: () {},
              ),
              IconButton(
                icon: Icon(Icons.more_vert, color: theme.colorScheme.primary),
                onPressed: () {},
              ),
            ],
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
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
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
                        theme.colorScheme.primary.withValues(alpha: 0.8),
                        theme.colorScheme.primary,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
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
                        color: isPositive
                            ? AppTheme.bullish.withValues(alpha: 0.15)
                            : AppTheme.bearish.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isPositive
                              ? AppTheme.bullish.withValues(alpha: 0.3)
                              : AppTheme.bearish.withValues(alpha: 0.3),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isPositive
                                ? AppTheme.bullish.withValues(alpha: 0.1)
                                : AppTheme.bearish.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
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
      ),
    );
  }

  Widget _buildMarketStatusBanner(ThemeData theme, LanguageProvider lang) {
    final marketHours = EthiopianMarketHours.getMarketHours();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              _isMarketOpen ? AppTheme.successGradient : AppTheme.errorGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (_isMarketOpen
                    ? AppTheme.successGradient.last
                    : AppTheme.errorGradient.last)
                .withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isMarketOpen
                      ? AppTheme.successGradient.last
                      : AppTheme.errorGradient.last,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                lang.translate(_isMarketOpen ? 'market_open' : 'market_closed'),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Text(
            '${marketHours['openTime']} - ${marketHours['closeTime']}',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}
