import 'package:flutter/material.dart';
import '../data/ethio_data.dart';
import '../utils/ethiopian_utils.dart';
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

  @override
  void initState() {
    super.initState();
    ethioMarketData = EthioData.generateMockEthioMarketData();
    _tabController = TabController(length: 2, vsync: this);
    _updateMarketStatus();
    _marketStatusTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _updateMarketStatus(),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ethiopianDate = EthiopianCalendar.getCurrentDate();
    final Color marketStatusColor = _isMarketOpen ? Colors.green : Colors.grey;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ገበያ'), // Market in Amharic
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
                tabs: const [
                  Tab(text: 'Market Data'),
                  Tab(text: 'Performance'),
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
          _buildPerformanceTab(theme),
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

  Widget _buildPerformanceTab(ThemeData theme) {
    final topGainers = List<Map<String, dynamic>>.from(ethioMarketData)
      ..sort(
          (a, b) => (b['change'] as double).compareTo(a['change'] as double));
    final topLosers = List<Map<String, dynamic>>.from(ethioMarketData)
      ..sort(
          (a, b) => (a['change'] as double).compareTo(b['change'] as double));

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Top Gainers', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            _buildPerformanceList(topGainers.take(5).toList(), theme),
            const SizedBox(height: 24),
            Text('Top Losers', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            _buildPerformanceList(topLosers.take(5).toList(), theme),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceList(
      List<Map<String, dynamic>> data, ThemeData theme) {
    return Column(
      children: data.map((item) {
        final isPositiveChange = item['change'] >= 0;
        return Card(
          child: ListTile(
            title: Text(item['symbol']),
            subtitle: Text(item['sector']),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${item['currency']} ${item['price'].toStringAsFixed(2)}',
                  style: theme.textTheme.bodyLarge,
                ),
                Text(
                  '${isPositiveChange ? '+' : ''}${item['change'].toStringAsFixed(2)}%',
                  style: TextStyle(
                    color: isPositiveChange ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
