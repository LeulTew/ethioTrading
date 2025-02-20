import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:candlesticks/candlesticks.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:provider/provider.dart';
import '../utils/ethiopian_utils.dart';
import '../utils/validators.dart';
import '../providers/language_provider.dart';
import 'dart:math' as math;

class StockDetailScreen extends StatefulWidget {
  final Map<String, dynamic> stockData;

  const StockDetailScreen({
    super.key,
    required this.stockData,
  });

  @override
  State<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  bool isBuySelected = true;
  bool isInWatchlist = false;
  bool isMarketOrder = true;
  String selectedTimeframe = '1D';
  List<Map<String, dynamic>> mockNews = [];
  List<Candle> candles = [];
  bool showVolume = true;
  bool showGrid = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _quantityController.text = '1';
    _priceController.text = widget.stockData['price'].toString();
    _generateMockNews();
    _generateCandleData();
  }

  void _generateCandleData() {
    final random = math.Random();
    double open = widget.stockData['price'];
    double close = open;
    final List<Candle> generatedCandles = [];

    // Generate 100 candles for historical data
    for (int i = 100; i > 0; i--) {
      open = close;
      // Generate realistic price movements
      final changePercent = (random.nextDouble() - 0.5) * 2; // -1% to +1%
      close = open * (1 + changePercent / 100);
      final high = math.max(open, close) * (1 + random.nextDouble() / 100);
      final low = math.min(open, close) * (1 - random.nextDouble() / 100);
      final volume = random.nextDouble() * 100000;

      generatedCandles.add(
        Candle(
          date: DateTime.now().subtract(Duration(days: i)),
          high: high,
          low: low,
          open: open,
          close: close,
          volume: volume,
        ),
      );
    }

    setState(() => candles = generatedCandles);
  }

  Widget _buildAdvancedChart() {
    return Column(
      children: [
        Expanded(
          child: Candlesticks(
            candles: candles,
          ),
        ),
        _buildTimeframeSelector(),
      ],
    );
  }

  Widget _buildTimeframeSelector() {
    final timeframes = ['1D', '1W', '1M', '3M', '6M', '1Y', 'ALL'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: timeframes.map((timeframe) {
          final isSelected = selectedTimeframe == timeframe;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(timeframe),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    selectedTimeframe = timeframe;
                    _generateCandleData(); // Regenerate data for new timeframe
                  });
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTradingForm() {
    final theme = Theme.of(context);
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Form(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Order Type Selector
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(
                value: true,
                label: Text(languageProvider.translate('market_order')),
              ),
              ButtonSegment(
                value: false,
                label: Text(languageProvider.translate('limit_order')),
              ),
            ],
            selected: {isMarketOrder},
            onSelectionChanged: (Set<bool> selected) {
              setState(() => isMarketOrder = selected.first);
            },
          ),
          const SizedBox(height: 16),

          // Buy/Sell Selector
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(
                value: true,
                label: Text(languageProvider.translate('buy')),
                icon: const Icon(Icons.add_circle_outline),
              ),
              ButtonSegment(
                value: false,
                label: Text(languageProvider.translate('sell')),
                icon: const Icon(Icons.remove_circle_outline),
              ),
            ],
            selected: {isBuySelected},
            onSelectionChanged: (Set<bool> selected) {
              setState(() => isBuySelected = selected.first);
            },
          ),
          const SizedBox(height: 16),

          // Quantity Input
          TextFormField(
            controller: _quantityController,
            decoration: InputDecoration(
              labelText: languageProvider.translate('quantity'),
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.shopping_cart_outlined),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (value) => TradeValidator.validateQuantity(
              value,
              1000000, // Example max quantity
            ),
          ),
          const SizedBox(height: 16),

          // Price Input (for limit orders)
          if (!isMarketOrder)
            TextFormField(
              controller: _priceController,
              decoration: InputDecoration(
                labelText: languageProvider.translate('price'),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.attach_money),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (value) => TradeValidator.validatePrice(
                value,
                widget.stockData['price'],
              ),
            ),

          // Order Summary
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    languageProvider.translate('order_summary'),
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  _buildSummaryRow(
                    languageProvider.translate('order_type'),
                    isMarketOrder ? 'Market' : 'Limit',
                  ),
                  _buildSummaryRow(
                    languageProvider.translate('quantity'),
                    _quantityController.text,
                  ),
                  if (!isMarketOrder)
                    _buildSummaryRow(
                      languageProvider.translate('price'),
                      EthiopianCurrencyFormatter.format(
                        double.tryParse(_priceController.text) ?? 0,
                      ),
                    ),
                  const Divider(),
                  _buildSummaryRow(
                    languageProvider.translate('estimated_total'),
                    EthiopianCurrencyFormatter.format(
                      (int.tryParse(_quantityController.text)?.toDouble() ??
                              0) *
                          (double.tryParse(_priceController.text) ??
                              widget.stockData['price']),
                    ),
                    isTotal: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Place Order Button
          ElevatedButton(
            onPressed: _handlePlaceOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: isBuySelected ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(languageProvider.translate(
              isBuySelected ? 'place_buy_order' : 'place_sell_order',
            )),
          ),
        ],
      ),
    );
  }

  void _handlePlaceOrder() {
    // Implement order placement logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          Provider.of<LanguageProvider>(context, listen: false).translate(
            'order_placed_successfully',
          ),
        ),
      ),
    );
    Navigator.pop(context);
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  void _generateMockNews() {
    mockNews = [
      {
        'title': 'የ${widget.stockData['name']} አዲስ የንግድ እድሎች',
        'source': 'Capital Ethiopia',
        'time': '2 ሰዓት በፊት',
        'isPositive': true,
      },
      {
        'title': 'የገበያው ሁኔታ ግምገማ - ${widget.stockData['sector']}',
        'source': 'Addis Fortune',
        'time': '5 ሰዓት በፊት',
        'isPositive': null,
      },
      {
        'title': '${widget.stockData['symbol']} አዳዲስ ኢንቨስትመንቶች',
        'source': 'Ethiopian Herald',
        'time': 'ዛሬ',
        'isPositive': true,
      },
    ];
  }

  @override
  void dispose() {
    _tabController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _showTradeBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: _buildTradingForm(),
        ),
      ),
    );
  }

  void _showNewsDetail(Map<String, dynamic> news) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(news['title'], style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(news['source'],
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(width: 8),
                Text(news['time'],
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
                'Coming soon: Full news content will be displayed here.'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isPositiveChange = (widget.stockData['change'] ?? 0) >= 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.stockData['symbol']),
        actions: [
          IconButton(
            icon: Icon(
              isInWatchlist ? Icons.star : Icons.star_border,
              color: isInWatchlist ? Colors.amber : null,
            ),
            onPressed: () => setState(() => isInWatchlist = !isInWatchlist),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: languageProvider.translate('overview')),
            Tab(text: languageProvider.translate('chart')),
            Tab(text: languageProvider.translate('analysis')),
            Tab(text: languageProvider.translate('news')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(theme, isPositiveChange),
          _buildAdvancedChart(),
          _buildAnalysisTab(theme),
          _buildNewsTab(theme),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _showTradeBottomSheet(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: Text(languageProvider.translate('trade')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab(ThemeData theme, bool isPositiveChange) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.stockData['name'] ?? '',
              style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '${widget.stockData['currency']} ${(widget.stockData['price'] ?? 0.0).toStringAsFixed(2)}',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPositiveChange
                      ? Colors.green.withAlpha((0.1 * 255).round())
                      : Colors.red.withAlpha((0.1 * 255).round()),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${isPositiveChange ? '+' : ''}${(widget.stockData['change'] ?? 0.0).toStringAsFixed(2)}%',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isPositiveChange ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildInfoCard('Company Details', [
            _buildInfoRow('Sector', widget.stockData['sector'] ?? ''),
            _buildInfoRow('Ownership', widget.stockData['ownership'] ?? ''),
            _buildInfoRow('Market Cap',
                'ETB ${(widget.stockData['marketCap'] ?? 0.0).toStringAsFixed(2)}'),
          ]),
          const SizedBox(height: 16),
          _buildInfoCard('Trading Information', [
            _buildInfoRow('Volume', (widget.stockData['volume'] ?? '').toString()),
            _buildInfoRow(
                'Last Updated', widget.stockData['lastUpdated'] ?? ''),
          ]),
        ],
      ),
    );
  }

  Widget _buildAnalysisTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildMarketDepthCard(theme),
        const SizedBox(height: 16),
        _buildTradingVolumeCard(theme),
      ],
    );
  }

  Widget _buildMarketDepthCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Market Depth', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: SfCartesianChart(
                primaryXAxis: NumericAxis(),
                primaryYAxis: NumericAxis(),
                series: _getMarketDepthSeries(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<CartesianSeries> _getMarketDepthSeries() {
    final random = math.Random();
    final basePrice = widget.stockData['price'] as double;

    // Generate bid data with explicit double type
    final bidData = List<MapEntry<double, double>>.generate(10, (index) {
      final price = basePrice * (1 - index * 0.001);
      final volume = 1000.0 + random.nextDouble() * 1000;
      return MapEntry(price, volume);
    });

    // Generate ask data with explicit double type
    final askData = List<MapEntry<double, double>>.generate(10, (index) {
      final price = basePrice * (1 + index * 0.001);
      final volume = 1000.0 + random.nextDouble() * 1000;
      return MapEntry(price, volume);
    });

    return [
      LineSeries<MapEntry<double, double>, double>(
        dataSource: bidData,
        xValueMapper: (MapEntry<double, double> data, _) => data.key,
        yValueMapper: (MapEntry<double, double> data, _) => data.value,
        color: Colors.green,
      ),
      LineSeries<MapEntry<double, double>, double>(
        dataSource: askData,
        xValueMapper: (MapEntry<double, double> data, _) => data.key,
        yValueMapper: (MapEntry<double, double> data, _) => data.value,
        color: Colors.red,
      ),
    ];
  }

  Widget _buildTradingVolumeCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Trading Volume', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: SfCartesianChart(
                primaryXAxis: DateTimeAxis(),
                primaryYAxis: NumericAxis(),
                series: _getVolumeSeries(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<CartesianSeries> _getVolumeSeries() {
    final random = math.Random();
    final now = DateTime.now();

    final volumeData = List.generate(30, (index) {
      final date = now.subtract(Duration(days: 29 - index));
      return MapEntry<DateTime, double>(
        date,
        10000 + random.nextDouble() * 20000,
      );
    });

    return [
      ColumnSeries<MapEntry<DateTime, double>, DateTime>(
        dataSource: volumeData,
        xValueMapper: (MapEntry<DateTime, double> data, _) => data.key,
        yValueMapper: (MapEntry<DateTime, double> data, _) => data.value,
        color: Theme.of(context).primaryColor.withOpacity(0.5),
      ),
    ];
  }

  Widget _buildNewsTab(ThemeData theme) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: mockNews.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final news = mockNews[index];
        return ListTile(
          title: Text(
            news['title'],
            style: theme.textTheme.titleMedium,
          ),
          subtitle: Row(
            children: [
              Text(news['source'], style: theme.textTheme.bodySmall),
              const SizedBox(width: 8),
              Text(news['time'], style: theme.textTheme.bodySmall),
            ],
          ),
          trailing: news['isPositive'] != null
              ? Icon(
                  news['isPositive'] ? Icons.trending_up : Icons.trending_down,
                  color: news['isPositive'] ? Colors.green : Colors.red,
                )
              : null,
          onTap: () => _showNewsDetail(news),
        );
      },
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value),
        ],
      ),
    );
  }
}
