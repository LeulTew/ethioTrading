import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import '../data/ethio_data.dart';
import '../utils/ethiopian_utils.dart';
import '../providers/language_provider.dart';
import 'stock_detail_screen.dart';
import 'dart:async';

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
  String _marketStatus = '';
  String _selectedTimeframe = '1D';
  late ZoomPanBehavior _zoomPanBehavior;

  @override
  void initState() {
    super.initState();
    ethioMarketData = EthioData.generateMockEthioMarketData();
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

  void _updateMarketStatus() {
    setState(() {
      _isMarketOpen = EthiopianMarketHours.isMarketOpen();
      _marketStatus = EthiopianMarketHours.getMarketStatus();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _marketStatusTimer.cancel();
    super.dispose();
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

  Widget _buildMarketIndexChart(ThemeData theme) {
    return Card(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Market Index', style: theme.textTheme.titleLarge),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: '1D', label: Text('1D')),
                    ButtonSegment(value: '1W', label: Text('1W')),
                    ButtonSegment(value: '1M', label: Text('1M')),
                    ButtonSegment(value: '1Y', label: Text('1Y')),
                  ],
                  selected: {_selectedTimeframe},
                  onSelectionChanged: (Set<String> selection) {
                    setState(() => _selectedTimeframe = selection.first);
                  },
                ),
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
              ),
              series: <ChartSeries>[
                // Area Series for volume
                AreaSeries<Map<String, dynamic>, DateTime>(
                  dataSource: _getChartData(),
                  xValueMapper: (Map<String, dynamic> data, _) =>
                      data['timestamp'],
                  yValueMapper: (Map<String, dynamic> data, _) =>
                      data['volume'],
                  opacity: 0.3,
                  name: 'Volume',
                ),
                // Line Series for price
                LineSeries<Map<String, dynamic>, DateTime>(
                  dataSource: _getChartData(),
                  xValueMapper: (Map<String, dynamic> data, _) =>
                      data['timestamp'],
                  yValueMapper: (Map<String, dynamic> data, _) => data['value'],
                  name: 'Market Index',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectorPerformanceChart(ThemeData theme) {
    final sectorWeights = EthioData.getSectorWeights(ethioMarketData);

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child:
                Text('Sector Performance', style: theme.textTheme.titleLarge),
          ),
          SizedBox(
            height: 300,
            child: SfCircularChart(
              legend:
                  const Legend(isVisible: true, position: LegendPosition.right),
              series: <CircularSeries>[
                DoughnutSeries<MapEntry<String, double>, String>(
                  dataSource: sectorWeights.entries.toList(),
                  xValueMapper: (MapEntry<String, double> data, _) => data.key,
                  yValueMapper: (MapEntry<String, double> data, _) =>
                      data.value,
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
    );
  }

  Widget _buildMarketDepthChart(ThemeData theme) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Market Depth', style: theme.textTheme.titleLarge),
          ),
          SizedBox(
            height: 300,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: true),
                titlesData: const FlTitlesData(show: true),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  // Bid Line
                  LineChartBarData(
                    spots: _generateBidLine(),
                    isCurved: true,
                    color: Colors.green,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                  ),
                  // Ask Line
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
    final ethiopianDate = EthiopianCalendar.getCurrentDate();
    final Color marketStatusColor = _isMarketOpen ? Colors.green : Colors.grey;
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.translate('market')),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(160),
          child: Column(
            children: [
              // Market Status Banner
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: marketStatusColor.withAlpha(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isMarketOpen ? Icons.circle : Icons.circle_outlined,
                          size: 12,
                          color: marketStatusColor,
                        ),
                        const SizedBox(width: 8),
                        Text(_marketStatus),
                      ],
                    ),
                    Text(
                      '${ethiopianDate['monthName']} ${ethiopianDate['day']}, ${ethiopianDate['year']}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search stocks...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: _selectedSector == 'All',
                      onSelected: (selected) =>
                          setState(() => _selectedSector = 'All'),
                    ),
                    const SizedBox(width: 8),
                    ...EthioData.getSectors().map<Widget>((sector) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(sector),
                            selected: _selectedSector == sector,
                            onSelected: (selected) =>
                                setState(() => _selectedSector = sector),
                          ),
                        )),
                  ],
                ),
              ),
              TabBar(
                controller: _tabController,
                tabs: [
                  Tab(text: languageProvider.translate('market_data')),
                  Tab(text: languageProvider.translate('performance')),
                  Tab(text: languageProvider.translate('market_depth')),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMarketDataTab(theme),
          Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildMarketIndexChart(theme),
                    const SizedBox(height: 16),
                    _buildSectorPerformanceChart(theme),
                  ],
                ),
              ),
            ],
          ),
          Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildMarketDepthChart(theme),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMarketDataTab(ThemeData theme) {
    return ListView.builder(
      itemCount: filteredData.length,
      itemBuilder: (context, index) {
        final data = filteredData[index];
        final isPositiveChange = data['change'] >= 0;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            title: Text(
              data['name'],
              style: theme.textTheme.titleMedium,
            ),
            subtitle: Row(
              children: [
                Text(data['symbol'], style: theme.textTheme.bodyMedium),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                        color: theme.colorScheme.outline.withAlpha(128)),
                  ),
                  child: Text(
                    data['sector'],
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${data['currency']} ${data['price'].toStringAsFixed(2)}',
                  style: theme.textTheme.titleMedium,
                ),
                Text(
                  '${isPositiveChange ? '+' : ''}${data['change'].toStringAsFixed(2)}%',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isPositiveChange ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StockDetailScreen(stockData: data),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
