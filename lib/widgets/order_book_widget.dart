import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;

class OrderBookWidget extends StatelessWidget {
  final Map<String, dynamic> stockData;
  final double maxDepth;

  const OrderBookWidget({
    super.key,
    required this.stockData,
    this.maxDepth = 20,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order Book', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                    child: Text('Price', style: theme.textTheme.labelMedium)),
                Expanded(
                    child: Text('Size', style: theme.textTheme.labelMedium)),
                Expanded(
                    child: Text('Total', style: theme.textTheme.labelMedium)),
              ],
            ),
            const Divider(),
            SizedBox(
              height: 300,
              child: Row(
                children: [
                  // Asks (Sell Orders)
                  Expanded(
                    child: _buildOrderList(
                      generateMockOrders(true),
                      isAsk: true,
                      theme: theme,
                    ),
                  ),
                  // Bids (Buy Orders)
                  Expanded(
                    child: _buildOrderList(
                      generateMockOrders(false),
                      isAsk: false,
                      theme: theme,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: OrderBookChart(
                asks: generateMockOrders(true),
                bids: generateMockOrders(false),
                basePrice: stockData['price'],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderList(
    List<OrderBookEntry> orders, {
    required bool isAsk,
    required ThemeData theme,
  }) {
    return ListView.builder(
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = isAsk ? orders[index] : orders[orders.length - 1 - index];
        final cumulative = orders
            .sublist(0, isAsk ? index + 1 : orders.length - index)
            .fold(0.0, (sum, item) => sum + item.size);

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                isAsk
                    ? Colors.red.withValues(alpha: 0.1)
                    : Colors.green.withValues(alpha: 0.1),
                Colors.transparent,
              ],
              stops: [cumulative / orders.last.cumulativeTotal, 1.0],
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  order.price.toStringAsFixed(2),
                  style: TextStyle(
                    color: isAsk ? Colors.red : Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  order.size.toStringAsFixed(2),
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              Expanded(
                child: Text(
                  cumulative.toStringAsFixed(2),
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<OrderBookEntry> generateMockOrders(bool isAsk) {
    final random = math.Random();
    final basePrice = stockData['price'] as double;
    final orders = <OrderBookEntry>[];
    double cumulativeTotal = 0;

    for (int i = 0; i < maxDepth; i++) {
      final price = basePrice * (1 + (isAsk ? 1 : -1) * i * 0.001);
      final size = 100 + random.nextDouble() * 900;
      cumulativeTotal += size;
      orders.add(OrderBookEntry(
        price: price,
        size: size,
        cumulativeTotal: cumulativeTotal,
      ));
    }

    return orders;
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
