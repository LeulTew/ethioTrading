import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/ethiopian_utils.dart';
import 'dart:math' as math;

class StockDetailScreen extends StatefulWidget {
  final Map<String, dynamic>? stockData;

  const StockDetailScreen({
    super.key,
    this.stockData,
  });

  @override
  State<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _quantityController = TextEditingController();
  bool isBuySelected = true;
  bool isInWatchlist = false;
  List<Map<String, dynamic>> mockNews = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _quantityController.text = '1';
    _generateMockNews();
  }

  void _generateMockNews() {
    mockNews = [
      {
        'title': 'የ${widget.stockData?['name']} አዲስ የንግድ እድሎች',
        'source': 'Capital Ethiopia',
        'time': '2 ሰዓት በፊት',
        'isPositive': true,
      },
      {
        'title': 'የገበያው ሁኔታ ግምገማ - ${widget.stockData?['sector']}',
        'source': 'Addis Fortune',
        'time': '5 ሰዓት በፊት',
        'isPositive': null,
      },
      {
        'title': '${widget.stockData?['symbol']} አዳዲስ ኢንቨስትመንቶች',
        'source': 'Ethiopian Herald',
        'time': 'ዛሬ',
        'isPositive': true,
      },
    ];
  }

  List<Map<String, dynamic>> _generateMockChartData() {
    final random = math.Random();
    final List<Map<String, dynamic>> data = [];
    double price = widget.stockData?['price'] ?? 0.0;

    for (int i = 30; i >= 0; i--) {
      price += (random.nextDouble() - 0.5) * 5;
      data.add({
        'day': i,
        'price': price,
      });
    }
    return data;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _showTradeBottomSheet(BuildContext context) {
    final theme = Theme.of(context);
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(value: true, label: Text('ግዛ')), // Buy
                        ButtonSegment(value: false, label: Text('ሽጥ')), // Sell
                      ],
                      selected: {isBuySelected},
                      onSelectionChanged: (Set<bool> selected) {
                        setState(() => isBuySelected = selected.first);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _quantityController,
                      decoration: const InputDecoration(
                        labelText: 'መጠን', // Quantity
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ጠቅላላ',
                            style: theme.textTheme.labelLarge), // Total
                        const SizedBox(height: 8),
                        Text(
                          EthiopianCurrencyFormatter.format(
                              (int.tryParse(_quantityController.text)?.toDouble() ?? 0.0) *
                                  (widget.stockData?['price']?.toDouble() ?? 0.0)),
                          style: theme.textTheme.titleLarge,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isBuySelected
                          ? 'የግዢ ትዕዛዝ ተከናውኗል'
                          : 'የሽያጭ ትዕዛዝ ተከናውኗል'),
                    ),
                  );
                },
                child: Text(isBuySelected ? 'አሁን ግዛ' : 'አሁን ሽጥ'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _handleTimeframeChange(String timeframe) {
    setState(() {
      _generateMockChartData();
    });
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
    final isPositiveChange = (widget.stockData?['change'] ?? 0) >= 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.stockData?['symbol'] ?? 'Stock Detail'),
        actions: [
          IconButton(
            icon: Icon(
              isInWatchlist ? Icons.star : Icons.star_border,
              color: isInWatchlist ? Colors.amber : null,
            ),
            onPressed: () {
              setState(() => isInWatchlist = !isInWatchlist);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      Text(isInWatchlist ? 'ወደ ዝርዝር ተጨምሯል' : 'ከዝርዝር ተወግዷል'),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'አጠቃላይ'), // Overview
            Tab(text: 'ስታትስቲክስ'), // Stats
            Tab(text: 'ግራፍ'), // Chart
            Tab(text: 'ዜና'), // News
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(theme, isPositiveChange),
          _buildStatsTab(theme),
          _buildChartTab(theme),
          _buildNewsTab(theme),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _showTradeBottomSheet(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('ግብይት'), // Trade
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() => isInWatchlist = !isInWatchlist);
                },
                child: Text(isInWatchlist ? 'ከዝርዝር አውጣ' : 'ወደ ዝርዝር ጨምር'),
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
          Text(widget.stockData?['name'] ?? '',
              style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '${widget.stockData?['currency']} ${(widget.stockData?['price'] ?? 0.0).toStringAsFixed(2)}',
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
                  '${isPositiveChange ? '+' : ''}${(widget.stockData?['change'] ?? 0.0).toStringAsFixed(2)}%',
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
            _buildInfoRow('Sector', widget.stockData?['sector'] ?? ''),
            _buildInfoRow('Ownership', widget.stockData?['ownership'] ?? ''),
            _buildInfoRow('Market Cap',
                'ETB ${(widget.stockData?['marketCap'] ?? 0.0).toStringAsFixed(2)}'),
          ]),
          const SizedBox(height: 16),
          _buildInfoCard('Trading Information', [
            _buildInfoRow(
                'Volume', widget.stockData?['volume'].toString() ?? ''),
            _buildInfoRow(
                'Last Updated', widget.stockData?['lastUpdated'] ?? ''),
          ]),
        ],
      ),
    );
  }

  Widget _buildStatsTab(ThemeData theme) {
    return const Center(child: Text('Coming soon...'));
  }

  Widget _buildChartTab(ThemeData theme) {
    final chartData = _generateMockChartData();
    final maxPrice = chartData
        .map((d) => d['price'] as double)
        .reduce((a, b) => a > b ? a : b);
    final minPrice = chartData
        .map((d) => d['price'] as double)
        .reduce((a, b) => a < b ? a : b);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1.5,
            child: CustomPaint(
              painter: ChartPainter(
                data: chartData,
                maxPrice: maxPrice,
                minPrice: minPrice,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTimeFrameButton(theme, '1ቀን', true),
              _buildTimeFrameButton(theme, '1ሳምንት', false),
              _buildTimeFrameButton(theme, '1ወር', false),
              _buildTimeFrameButton(theme, '3ወር', false),
              _buildTimeFrameButton(theme, '1አመት', false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeFrameButton(ThemeData theme, String text, bool isSelected) {
    return ChoiceChip(
      label: Text(text),
      selected: isSelected,
      onSelected: (bool selected) {
        if (selected) {
          _handleTimeframeChange(text);
        }
      },
    );
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

class ChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final double maxPrice;
  final double minPrice;
  final Color color;

  ChartPainter({
    required this.data,
    required this.maxPrice,
    required this.minPrice,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final path = Path();
    final paddingTop = size.height * 0.1;
    final paddingBottom = size.height * 0.1;
    final availableHeight = size.height - paddingTop - paddingBottom;
    final xStep = size.width / (data.length - 1);

    for (var i = 0; i < data.length; i++) {
      final price = (data[i]['price'] as num).toDouble(); // cast num to double
      final normalizedY = 1 - ((price - minPrice) / (maxPrice - minPrice));
      final x = i * xStep;
      final y = normalizedY * availableHeight + paddingTop;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(ChartPainter oldDelegate) => true;
}
