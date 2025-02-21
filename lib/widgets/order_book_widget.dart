import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../providers/language_provider.dart';
import '../utils/ethiopian_utils.dart';

class OrderBookWidget extends StatefulWidget {
  final Map<String, dynamic> stockData;
  final bool showHeader;
  final double maxHeight;

  const OrderBookWidget({
    super.key,
    required this.stockData,
    this.showHeader = true,
    this.maxHeight = 400,
  });

  @override
  State<OrderBookWidget> createState() => _OrderBookWidgetState();
}

class _OrderBookWidgetState extends State<OrderBookWidget> {
  String _selectedView = 'combined';
  bool _isExpanded = false;

  Widget _buildHeader(ThemeData theme, LanguageProvider lang) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                lang.translate('order_book'),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      _isExpanded ? Icons.fullscreen_exit : Icons.fullscreen,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _isExpanded = !_isExpanded),
                    tooltip:
                        lang.translate(_isExpanded ? 'collapse' : 'expand'),
                  ),
                  const SizedBox(width: 8),
                  _buildViewSelector(theme, lang),
                ],
              ),
            ],
          ),
        ),
        _buildMarketDepthSummary(theme, lang),
      ],
    );
  }

  Widget _buildViewSelector(ThemeData theme, LanguageProvider lang) {
    return SegmentedButton<String>(
      segments: [
        ButtonSegment(
          value: 'combined',
          label: Text(
            lang.translate('combined'),
            style: GoogleFonts.spaceGrotesk(fontSize: 12),
          ),
          icon: const Icon(Icons.compare_arrows, size: 16),
        ),
        ButtonSegment(
          value: 'bids',
          label: Text(
            lang.translate('bids'),
            style: GoogleFonts.spaceGrotesk(fontSize: 12),
          ),
          icon: const Icon(Icons.arrow_circle_up, size: 16),
        ),
        ButtonSegment(
          value: 'asks',
          label: Text(
            lang.translate('asks'),
            style: GoogleFonts.spaceGrotesk(fontSize: 12),
          ),
          icon: const Icon(Icons.arrow_circle_down, size: 16),
        ),
      ],
      selected: {_selectedView},
      onSelectionChanged: (Set<String> selected) {
        setState(() => _selectedView = selected.first);
      },
      style: const ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _buildMarketDepthSummary(ThemeData theme, LanguageProvider lang) {
    final orderBook = widget.stockData['orderBook'];
    final marketDepth = widget.stockData['marketDepth'] ?? {};
    final bidAskRatio = marketDepth['bidAskRatio'] ?? 1.0;
    final isStrongBuying = bidAskRatio > 1.2;
    final isStrongSelling = bidAskRatio < 0.8;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDepthSummaryItem(
                label: lang.translate('total_bids'),
                value: EthiopianCurrencyFormatter.formatVolume(
                  orderBook['bids']
                      .fold(0.0, (sum, bid) => sum + bid['volume']),
                ),
                color: Colors.green,
                theme: theme,
              ),
              _buildDepthSummaryItem(
                label: lang.translate('total_asks'),
                value: EthiopianCurrencyFormatter.formatVolume(
                  orderBook['asks']
                      .fold(0.0, (sum, ask) => sum + ask['volume']),
                ),
                color: Colors.red,
                theme: theme,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                isStrongBuying
                    ? Icons.trending_up
                    : isStrongSelling
                        ? Icons.trending_down
                        : Icons.trending_flat,
                size: 16,
                color: isStrongBuying
                    ? Colors.green
                    : isStrongSelling
                        ? Colors.red
                        : theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                lang.translate(
                  isStrongBuying
                      ? 'strong_buying_pressure'
                      : isStrongSelling
                          ? 'strong_selling_pressure'
                          : 'balanced_orderbook',
                ),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDepthSummaryItem({
    required String label,
    required String value,
    required Color color,
    required ThemeData theme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 12,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildOrderTable(ThemeData theme, LanguageProvider lang) {
    final orderBook = widget.stockData['orderBook'];
    final bids = orderBook['bids'] as List;
    final asks = orderBook['asks'] as List;
    final maxTotal = [...bids, ...asks]
        .map((order) => order['total'] as double)
        .reduce((a, b) => a > b ? a : b);

    return Container(
      constraints: BoxConstraints(
        maxHeight: _isExpanded ? double.infinity : widget.maxHeight,
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildTableHeader(theme, lang),
            if (_selectedView != 'asks')
              ..._buildBidRows(bids, maxTotal, theme),
            if (_selectedView != 'bids')
              ..._buildAskRows(asks, maxTotal, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader(ThemeData theme, LanguageProvider lang) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              lang.translate('price'),
              style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              lang.translate('amount'),
              style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              lang.translate('total'),
              style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBidRows(List bids, double maxTotal, ThemeData theme) {
    return bids.map((bid) {
      final total = bid['total'] as double;
      final percentageOfMax = total / maxTotal;

      return FadeIn(
        child: Stack(
          children: [
            Container(
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [
                    Colors.green.withValues(alpha: 0.1 * percentageOfMax),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      bid['price'].toStringAsFixed(2),
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      EthiopianCurrencyFormatter.formatVolume(bid['volume']),
                      style: GoogleFonts.spaceGrotesk(),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      EthiopianCurrencyFormatter.format(total),
                      style: GoogleFonts.spaceGrotesk(),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  List<Widget> _buildAskRows(List asks, double maxTotal, ThemeData theme) {
    return asks.map((ask) {
      final total = ask['total'] as double;
      final percentageOfMax = total / maxTotal;

      return FadeIn(
        child: Stack(
          children: [
            Container(
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [
                    Colors.red.withValues(alpha: 0.1 * percentageOfMax),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      ask['price'].toStringAsFixed(2),
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      EthiopianCurrencyFormatter.formatVolume(ask['volume']),
                      style: GoogleFonts.spaceGrotesk(),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      EthiopianCurrencyFormatter.format(total),
                      style: GoogleFonts.spaceGrotesk(),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = Provider.of<LanguageProvider>(context);

    return Column(
      children: [
        if (widget.showHeader) _buildHeader(theme, lang),
        _buildOrderTable(theme, lang),
      ],
    );
  }
}

class OrderBookChart extends StatelessWidget {
  final List<OrderBookEntry> asks;
  final List<OrderBookEntry> bids;
  final double basePrice;

  const OrderBookChart({
    super.key,
    required this.asks,
    required this.bids,
    required this.basePrice,
  });

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true),
        titlesData: const FlTitlesData(
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          // Asks line
          LineChartBarData(
            spots: _convertToSpots(asks),
            isCurved: false,
            color: Colors.red.withValues(alpha: 0.5),
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.red.withValues(alpha: 0.1),
            ),
          ),
          // Bids line
          LineChartBarData(
            spots: _convertToSpots(bids),
            isCurved: false,
            color: Colors.green.withValues(alpha: 0.5),
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.green.withValues(alpha: 0.1),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.blueGrey.withValues(alpha: 0.8),
          ),
        ),
      ),
    );
  }

  List<FlSpot> _convertToSpots(List<OrderBookEntry> orders) {
    return orders.map((order) {
      final priceLevel = ((order.price - basePrice) / basePrice) * 100;
      return FlSpot(priceLevel, order.cumulativeTotal);
    }).toList();
  }
}

class OrderBookEntry {
  final double price;
  final double size;
  final double cumulativeTotal;

  OrderBookEntry({
    required this.price,
    required this.size,
    required this.cumulativeTotal,
  });
}
