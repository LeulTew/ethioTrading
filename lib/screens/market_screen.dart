import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'dart:async';
import '../data/ethio_data.dart';
import '../utils/ethiopian_utils.dart';
import '../providers/language_provider.dart';
import 'stock_detail_screen.dart';

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
  String _selectedTimeframe = '1D';
  late ZoomPanBehavior _zoomPanBehavior;
  bool _isLoading = true;

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
    _zoomPanBehavior = ZoomPanBehavior(
      enablePinching: true,
      enableDoubleTapZooming: true,
      enableSelectionZooming: true,
      enablePanning: true,
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

  Widget _buildMarketStatusBanner(ThemeData theme, LanguageProvider lang) {
    final ethiopianDate = EthiopianCalendar.getCurrentDate();
    final marketStatusColor =
        _isMarketOpen ? Colors.green : theme.colorScheme.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: marketStatusColor.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(
            color: marketStatusColor.withValues(alpha: 0.2),
          ),
        ),
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
                  color: marketStatusColor,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                lang.translate(_isMarketOpen ? 'market_open' : 'market_closed'),
                style: GoogleFonts.spaceGrotesk(
                  color: marketStatusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Text(
            '${ethiopianDate['monthName']} ${ethiopianDate['day']}, ${ethiopianDate['year']}',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme, LanguageProvider lang) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
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
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.transparent,
          ),
          onChanged: (value) => setState(() => _searchQuery = value),
        ),
      ),
    );
  }

  Widget _buildSectorFilter(LanguageProvider lang) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
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

  Widget _buildFilterChip(String value, String label) {
    return FilterChip(
      label: Text(label),
      selected: _selectedSector == value,
      onSelected: (selected) => setState(() => _selectedSector = value),
      showCheckmark: false,
      avatar:
          _selectedSector == value ? const Icon(Icons.check, size: 16) : null,
    );
  }

  Widget _buildTimeframeSelector(ThemeData theme, LanguageProvider lang) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: SegmentedButton<String>(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return theme.colorScheme.primary.withValues(alpha: 0.1);
            }
            return null;
          }),
          side: WidgetStateProperty.all(BorderSide.none),
        ),
        segments: [
          ButtonSegment(value: '1D', label: Text(lang.translate('1d'))),
          ButtonSegment(value: '1W', label: Text(lang.translate('1w'))),
          ButtonSegment(value: '1M', label: Text(lang.translate('1m'))),
          ButtonSegment(value: '1Y', label: Text(lang.translate('1y'))),
        ],
        selected: {_selectedTimeframe},
        onSelectionChanged: (selection) =>
            setState(() => _selectedTimeframe = selection.first),
      ),
    );
  }

  Widget _buildMarketIndexChart(ThemeData theme, LanguageProvider lang) {
    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        lang.translate('market_index'),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      _buildTimeframeSelector(theme, lang),
                    ],
                  ),
                ),
                SizedBox(
                  height: 300,
                  child: SfCartesianChart(
                    zoomPanBehavior: _zoomPanBehavior,
                    trackballBehavior: TrackballBehavior(
                      enable: true,
                      tooltipSettings: const InteractiveTooltip(enable: true),
                    ),
                    primaryXAxis: DateTimeAxis(
                      majorGridLines: const MajorGridLines(width: 0),
                      dateFormat: _selectedTimeframe == '1D'
                          ? DateFormat.Hm()
                          : DateFormat.MMMd(),
                    ),
                    primaryYAxis: NumericAxis(
                      opposedPosition: true,
                      majorGridLines:
                          const MajorGridLines(width: 0.5, dashArray: [5, 5]),
                      numberFormat: NumberFormat.currency(
                        symbol: 'ETB ',
                        decimalDigits: 2,
                      ),
                    ),
                    series: <CartesianSeries>[
                      AreaSeries<Map<String, dynamic>, DateTime>(
                        dataSource: _getChartData(),
                        xValueMapper: (data, _) => data['timestamp'],
                        yValueMapper: (data, _) => data['volume'],
                        opacity: 0.3,
                        name: lang.translate('volume'),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            theme.colorScheme.primary.withValues(alpha: 0.3),
                            theme.colorScheme.primary.withValues(alpha: 0.1),
                          ],
                        ),
                      ),
                      LineSeries<Map<String, dynamic>, DateTime>(
                        dataSource: _getChartData(),
                        xValueMapper: (data, _) => data['timestamp'],
                        yValueMapper: (data, _) => data['value'],
                        name: lang.translate('market_index'),
                        color: theme.colorScheme.primary,
                        width: 2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<FlSpot> _generateBidLine() {
    // Generate mock bid data
    return List.generate(10, (index) {
      return FlSpot(index.toDouble(), (100 - index * 2).toDouble());
    });
  }

  List<FlSpot> _generateAskLine() {
    // Generate mock ask data
    return List.generate(10, (index) {
      return FlSpot(index.toDouble(), (100 + index * 2).toDouble());
    });
  }

  List<Map<String, dynamic>> _getChartData() {
    final now = DateTime.now();
    // Generate mock time series data based on selected timeframe
    switch (_selectedTimeframe) {
      case '1D':
        return List.generate(24, (index) {
          return {
            'timestamp': now.subtract(Duration(hours: 24 - index)),
            'value': 1000 + (index * 5) + (index % 3 == 0 ? 10 : -5),
            'volume': 10000 + (index * 1000) * (index % 2 == 0 ? 1.2 : 0.8),
          };
        });
      case '1W':
        return List.generate(7, (index) {
          return {
            'timestamp': now.subtract(Duration(days: 7 - index)),
            'value': 1000 + (index * 20) + (index % 2 == 0 ? 15 : -10),
            'volume': 50000 + (index * 5000) * (index % 2 == 0 ? 1.3 : 0.7),
          };
        });
      default:
        return List.generate(30, (index) {
          return {
            'timestamp': now.subtract(Duration(days: 30 - index)),
            'value': 1000 + (index * 10) + (index % 4 == 0 ? 25 : -15),
            'volume': 100000 + (index * 10000) * (index % 3 == 0 ? 1.4 : 0.6),
          };
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.translate('market')),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(160),
          child: Column(
            children: [
              _buildMarketStatusBanner(theme, lang),
              _buildSearchBar(theme, lang),
              _buildSectorFilter(lang),
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: [
                  Tab(text: lang.translate('market_data')),
                  Tab(text: lang.translate('performance')),
                  Tab(text: lang.translate('market_depth')),
                ],
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    lang.translate('loading_market_data'),
                    style: GoogleFonts.spaceGrotesk(),
                  ),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildMarketDataTab(theme, lang),
                _buildPerformanceTab(theme, lang),
                _buildMarketDepthTab(theme, lang),
              ],
            ),
    );
  }

  Widget _buildMarketDataTab(ThemeData theme, LanguageProvider lang) {
    if (filteredData.isEmpty) {
      return Center(
        child: Text(
          lang.translate('no_stocks_found'),
          style: GoogleFonts.spaceGrotesk(),
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredData.length,
      itemBuilder: (context, index) {
        final data = filteredData[index];
        final isPositiveChange = data['change'] >= 0;

        return FadeInUp(
          duration: Duration(milliseconds: 200 + (index * 50)),
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StockDetailScreen(stockData: data),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['name'],
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                data['symbol'],
                                style: theme.textTheme.bodyMedium,
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      theme.colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  lang.translate(data['sector'].toLowerCase()),
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
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
                          '${data['currency']} ${data['price'].toStringAsFixed(2)}',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isPositiveChange
                                ? Colors.green.withValues(alpha: 0.1)
                                : Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isPositiveChange
                                    ? Icons.arrow_upward
                                    : Icons.arrow_downward,
                                size: 12,
                                color: isPositiveChange
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${isPositiveChange ? '+' : ''}${data['change'].toStringAsFixed(2)}%',
                                style: GoogleFonts.spaceGrotesk(
                                  color: isPositiveChange
                                      ? Colors.green
                                      : Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
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
      },
    );
  }

  Widget _buildPerformanceTab(ThemeData theme, LanguageProvider lang) {
    return ListView(
      children: [
        _buildMarketIndexChart(theme, lang),
        const SizedBox(height: 16),
        _buildSectorPerformanceChart(theme, lang),
      ],
    );
  }

  Widget _buildMarketDepthTab(ThemeData theme, LanguageProvider lang) {
    return ListView(
      children: [
        _buildMarketDepthChart(theme, lang),
      ],
    );
  }

  Widget _buildSectorPerformanceChart(ThemeData theme, LanguageProvider lang) {
    final sectorWeights = EthioData.getSectorWeights(ethioMarketData);

    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    lang.translate('sector_performance'),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(
                  height: 300,
                  child: SfCircularChart(
                    legend: const Legend(
                        isVisible: true, position: LegendPosition.right),
                    series: <CircularSeries>[
                      DoughnutSeries<MapEntry<String, double>, String>(
                        dataSource: sectorWeights.entries.toList(),
                        xValueMapper: (data, _) => data.key,
                        yValueMapper: (data, _) => data.value,
                        dataLabelSettings: const DataLabelSettings(
                          isVisible: true,
                          labelPosition: ChartDataLabelPosition.outside,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMarketDepthChart(ThemeData theme, LanguageProvider lang) {
    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    lang.translate('market_depth'),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(
                  height: 300,
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: true),
                      titlesData: const FlTitlesData(show: true),
                      borderData: FlBorderData(show: true),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _generateBidLine(),
                          isCurved: true,
                          color: Colors.green,
                          barWidth: 2,
                          dotData: const FlDotData(show: false),
                        ),
                        LineChartBarData(
                          spots: _generateAskLine(),
                          isCurved: true,
                          color: Colors.red,
                          barWidth: 2,
                          dotData: const FlDotData(show: false),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
