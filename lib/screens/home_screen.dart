import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:ui';
import '../data/ethio_data.dart';
import '../utils/ethiopian_utils.dart';
import '../providers/language_provider.dart';
import '../theme/app_theme.dart';
import '../models/asset.dart';
import 'stock_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late List<Map<String, dynamic>> _marketData;
  late bool _isMarketOpen;
  late Timer _refreshTimer;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _marketData = EthioData.generateMockEthioMarketData();
    _isMarketOpen = EthiopianMarketHours.isMarketOpen();

    // Setup animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animationController.forward();

    // Auto refresh market data every 30 seconds if market is open
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_isMarketOpen) {
        _refreshMarketData();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _refreshMarketData() async {
    setState(() {
      _marketData = EthioData.generateMockEthioMarketData();
      _isMarketOpen = EthiopianMarketHours.isMarketOpen();
    });
  }

  Widget _buildMarketOverview(ThemeData theme, LanguageProvider lang) {
    final marketIndex = _calculateMarketIndex();
    final isPositive = marketIndex['change'] > 0;
    final marketStats = EthioData.getMarketStatistics(_marketData);

    return FadeInDown(
      duration: const Duration(milliseconds: 600),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF6A11CB), // Deep purple
              Color(0xFF2575FC), // Bright blue
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6A11CB).withValues(alpha: 0.3),
              blurRadius: 16,
              spreadRadius: 1,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          lang.translate('market_index'),
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        _buildMarketStatusBadge(theme, lang),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              EthiopianCurrencyFormatter.format(
                                  marketIndex['value']),
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isPositive
                                      ? AppTheme.successGradient
                                      : AppTheme.errorGradient,
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isPositive
                                        ? Icons.arrow_upward
                                        : Icons.arrow_downward,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${isPositive ? '+' : ''}${marketIndex['change'].toStringAsFixed(2)}%',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildMarketStats(theme, marketStats, lang),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMarketStats(
      ThemeData theme, Map<String, dynamic> stats, LanguageProvider lang) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: _buildStatItem(
            theme,
            lang.translate('volume'),
            EthiopianCurrencyFormatter.formatVolume(stats['totalVolume']),
            Icons.bar_chart,
            color: Colors.white,
            isInCard: true,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatItem(
            theme,
            lang.translate('advancers'),
            stats['advancers'].toString(),
            Icons.trending_up,
            color: Colors.white,
            isInCard: true,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatItem(
            theme,
            lang.translate('decliners'),
            stats['decliners'].toString(),
            Icons.trending_down,
            color: Colors.white,
            isInCard: true,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(
      ThemeData theme, String label, String value, IconData icon,
      {Color? color, bool isInCard = false}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isInCard
            ? Colors.white.withValues(alpha: 0.1)
            : (color ?? theme.colorScheme.primary).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        boxShadow: isInCard
            ? []
            : [
                BoxShadow(
                  color: (color ?? theme.colorScheme.primary)
                      .withValues(alpha: 0.05),
                  blurRadius: 8,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isInCard
                      ? Colors.white.withValues(alpha: 0.2)
                      : (color ?? theme.colorScheme.primary)
                          .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon,
                    size: 14,
                    color: isInCard
                        ? Colors.white
                        : (color ?? theme.colorScheme.primary)),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isInCard
                        ? Colors.white.withValues(alpha: 0.9)
                        : theme.textTheme.bodyLarge?.color
                            ?.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isInCard
                  ? Colors.white
                  : (color ?? theme.colorScheme.onSurface),
              letterSpacing: -0.3,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMarketStatusBadge(ThemeData theme, LanguageProvider lang) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _isMarketOpen
            ? const Color(0xFF059669).withValues(alpha: 0.1)
            : theme.colorScheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isMarketOpen
              ? const Color(0xFF059669).withValues(alpha: 0.3)
              : theme.colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isMarketOpen
                  ? const Color(0xFF059669)
                  : theme.colorScheme.error,
              boxShadow: [
                BoxShadow(
                  color: (_isMarketOpen
                          ? const Color(0xFF059669)
                          : theme.colorScheme.error)
                      .withValues(alpha: 0.3),
                  blurRadius: 4,
                  spreadRadius: 0,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            lang.translate(_isMarketOpen ? 'market_open' : 'market_closed'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: _isMarketOpen
                  ? const Color(0xFF059669)
                  : theme.colorScheme.error,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectorPerformance(ThemeData theme, LanguageProvider lang) {
    final sectors = _calculateSectorPerformance();
    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                lang.translate('sector_performance'),
                style: theme.textTheme.titleLarge,
              ),
            ),
            ...sectors.entries.map((entry) {
              final isPositive = entry.value > 0;
              return ListTile(
                title: Text(entry.key),
                trailing: Text(
                  '${isPositive ? '+' : ''}${entry.value.toStringAsFixed(2)}%',
                  style: TextStyle(
                    color: isPositive ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTopMovers(ThemeData theme, LanguageProvider lang) {
    final gainers = List.from(_marketData)
      ..sort(
          (a, b) => (b['change'] as double).compareTo(a['change'] as double));
    final losers = List.from(_marketData)
      ..sort(
          (a, b) => (a['change'] as double).compareTo(b['change'] as double));

    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                lang.translate('top_movers'),
                style: theme.textTheme.titleLarge,
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ...gainers
                      .take(3)
                      .map((stock) => _buildStockCard(stock, theme, true)),
                  ...losers
                      .take(3)
                      .map((stock) => _buildStockCard(stock, theme, false)),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStockCard(
      Map<String, dynamic> stock, ThemeData theme, bool isGainer) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StockDetailScreen(
            asset: Asset(
              name: stock['name'],
              symbol: stock['symbol'],
              sector: stock['sector'],
              ownership: stock['ownership'],
              price: stock['price'].toDouble(),
              change: stock['change'].toDouble(),
              changePercent: stock['changePercent'].toDouble(),
              volume: stock['volume'].toDouble(),
              marketCap: stock['marketCap'].toDouble(),
            ),
          ),
        ),
      ),
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(left: 16),
        child: Card(
          elevation: 2,
          shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.08),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.05),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color:
                              (stock['change'] >= 0 ? Colors.green : Colors.red)
                                  .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          stock['change'] >= 0
                              ? Icons.trending_up
                              : Icons.trending_down,
                          color:
                              stock['change'] >= 0 ? Colors.green : Colors.red,
                          size: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          stock['symbol'],
                          style: GoogleFonts.spaceGrotesk(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    EthiopianCurrencyFormatter.format(stock['price']),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (stock['change'] >= 0 ? Colors.green : Colors.red)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${stock['change'] >= 0 ? '+' : ''}${stock['change'].toStringAsFixed(2)}%',
                      style: GoogleFonts.spaceGrotesk(
                        color: stock['change'] >= 0
                            ? Colors.green[700]
                            : Colors.red[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Map<String, double> _calculateSectorPerformance() {
    final sectorPerformance = <String, List<double>>{};

    for (final stock in _marketData) {
      final sector = stock['sector'] as String;
      sectorPerformance.putIfAbsent(sector, () => []);
      sectorPerformance[sector]!.add(stock['change'] as double);
    }

    return Map.fromEntries(
      sectorPerformance.entries.map(
        (entry) => MapEntry(
          entry.key,
          entry.value.reduce((a, b) => a + b) / entry.value.length,
        ),
      ),
    );
  }

  Map<String, dynamic> _calculateMarketIndex() {
    double totalValue = 0;
    double totalChange = 0;

    for (final stock in _marketData) {
      totalValue += stock['price'] as double;
      totalChange += stock['change'] as double;
    }

    return {
      'value': totalValue,
      'change': totalChange / _marketData.length,
    };
  }

  Widget _buildNotificationsScreen(ThemeData theme, LanguageProvider lang) {
    final notifications = [
      {
        'type': 'order',
        'title': 'Order Executed',
        'message':
            'Your buy order for 100 shares of EABL has been executed at ETB 167.00',
        'time': DateTime.now().subtract(const Duration(minutes: 5)),
        'read': false,
      },
      {
        'type': 'market',
        'title': 'Market Alert',
        'message': 'Market is now open for trading',
        'time': DateTime.now().subtract(const Duration(hours: 2)),
        'read': true,
      },
      {
        'type': 'price',
        'title': 'Price Alert',
        'message': 'EABL has reached your target price of ETB 170.00',
        'time': DateTime.now().subtract(const Duration(days: 1)),
        'read': true,
      },
    ];

    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: 48,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              lang.translate('no_notifications'),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        final isRead = notification['read'] as bool;

        IconData getNotificationIcon() {
          switch (notification['type']) {
            case 'order':
              return Icons.receipt_long;
            case 'market':
              return Icons.analytics;
            case 'price':
              return Icons.price_change;
            default:
              return Icons.notifications;
          }
        }

        return FadeInUp(
          duration: Duration(milliseconds: 200 + (index * 50)),
          child: Card(
            elevation: isRead ? 0 : 2,
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isRead
                    ? theme.colorScheme.surfaceContainerHighest
                    : theme.colorScheme.primary.withAlpha(26), // 0.1 * 255
                child: Icon(
                  getNotificationIcon(),
                  color: isRead
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              title: Text(
                notification['title'] as String,
                style: GoogleFonts.spaceGrotesk(
                  fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification['message'] as String,
                    style: GoogleFonts.spaceGrotesk(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    EthiopianUtils.timeAgo(
                        notification['time'] as DateTime, lang),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
              trailing: !isRead
                  ? Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.primary,
                      ),
                    )
                  : null,
              onTap: () {
                setState(() {
                  notification['read'] = true;
                });
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) =>
                      _buildNotificationDetails(notification, theme, lang),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationDetails(Map<String, dynamic> notification,
      ThemeData theme, LanguageProvider lang) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor:
                    theme.colorScheme.primary.withValues(alpha: 0.1),
                child: Icon(
                  notification['type'] == 'order'
                      ? Icons.receipt_long
                      : notification['type'] == 'market'
                          ? Icons.analytics
                          : Icons.price_change,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  notification['title'] as String,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                EthiopianUtils.timeAgo(notification['time'] as DateTime, lang),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            notification['message'] as String,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 24),
          if (notification['type'] == 'order')
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Navigate to order details
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                lang.translate('view_order_details'),
                style: GoogleFonts.spaceGrotesk(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final languageProvider = Provider.of<LanguageProvider>(context);

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: Text(languageProvider.translate('home')),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: Stack(
                children: [
                  const Icon(Icons.notifications_outlined),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 14,
                        minHeight: 14,
                      ),
                      child: Text(
                        '3',
                        style: TextStyle(
                          color: theme.colorScheme.onError,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Scaffold(
                      appBar: AppBar(
                        title:
                            Text(languageProvider.translate('notifications')),
                      ),
                      body: _buildNotificationsScreen(theme, languageProvider),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _refreshMarketData,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildMarketOverview(theme, languageProvider),
              const SizedBox(height: 16),
              _buildMarketChart(theme, languageProvider),
              const SizedBox(height: 16),
              _buildTopMovers(theme, languageProvider),
              const SizedBox(height: 16),
              _buildSectorPerformance(theme, languageProvider),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: 0, // Home is selected
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home),
              label: languageProvider.translate('home'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.show_chart),
              label: languageProvider.translate('market'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.account_balance_wallet),
              label: languageProvider.translate('portfolio'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person),
              label: languageProvider.translate('profile'),
            ),
          ],
          onTap: (index) {
            if (index != 0) {
              // Navigate to the appropriate screen
              final routes = ['/home', '/market', '/portfolio', '/profile'];
              Navigator.pushReplacementNamed(context, routes[index]);
            }
          },
        ),
      ),
    );
  }

  Widget _buildMarketChart(ThemeData theme, LanguageProvider lang) {
    final List<FlSpot> spots = List.generate(24, (index) {
      return FlSpot(index.toDouble(),
          _marketData[index % _marketData.length]['price'] as double);
    });

    return FadeInUp(
      duration: const Duration(milliseconds: 800),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lang.translate('market_trend'),
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 200,
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: theme.colorScheme.primary,
                        barWidth: 2,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
