import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'dart:math' as math;

class TechnicalAnalysisWidget extends StatefulWidget {
  final Map<String, dynamic> stockData;
  final List<Map<String, dynamic>> historicalData;

  const TechnicalAnalysisWidget({
    super.key,
    required this.stockData,
    required this.historicalData,
  });

  @override
  State<TechnicalAnalysisWidget> createState() =>
      _TechnicalAnalysisWidgetState();
}

class _TechnicalAnalysisWidgetState extends State<TechnicalAnalysisWidget> {
  bool showRSI = true;
  bool showMACD = true;
  bool showBollingerBands = true;
  bool showVolume = true;
  int selectedMAPeriod = 20;
  List<ChartIndicator> selectedIndicators = [];

  @override
  void initState() {
    super.initState();
    _initializeIndicators();
  }

  void _initializeIndicators() {
    selectedIndicators = [
      ChartIndicator(
        name: 'RSI',
        isVisible: showRSI,
        color: Colors.blue,
        values: _calculateRSI(14),
      ),
      ChartIndicator(
        name: 'MACD',
        isVisible: showMACD,
        color: Colors.purple,
        values: _calculateMACD(),
      ),
      ChartIndicator(
        name: 'Bollinger Bands',
        isVisible: showBollingerBands,
        color: Colors.orange,
        values: _calculateBollingerBands(20, 2),
      ),
    ];
  }

  List<Map<String, double>> _calculateRSI(int period) {
    final List<Map<String, double>> rsiData = [];
    double avgGain = 0;
    double avgLoss = 0;

    // Calculate first average gain and loss
    for (int i = 1; i < period + 1; i++) {
      final double change = widget.historicalData[i]['close'] -
          widget.historicalData[i - 1]['close'];
      if (change >= 0) {
        avgGain += change;
      } else {
        avgLoss += change.abs();
      }
    }

    avgGain /= period;
    avgLoss /= period;

    // Calculate RSI for the rest of the data
    for (int i = period + 1; i < widget.historicalData.length; i++) {
      final double change = widget.historicalData[i]['close'] -
          widget.historicalData[i - 1]['close'];

      avgGain =
          ((avgGain * (period - 1)) + (change >= 0 ? change : 0)) / period;
      avgLoss =
          ((avgLoss * (period - 1)) + (change < 0 ? change.abs() : 0)) / period;

      final double rs = avgGain / avgLoss;
      final double rsi = 100 - (100 / (1 + rs));

      rsiData.add({
        'timestamp': widget.historicalData[i]['timestamp'].toDouble(),
        'value': rsi,
      });
    }

    return rsiData;
  }

  List<Map<String, double>> _calculateMACD() {
    final ema12 = _calculateEMA(12);
    final ema26 = _calculateEMA(26);
    final List<Map<String, double>> macdData = [];

    for (int i = 0; i < ema12.length; i++) {
      if (i < ema26.length) {
        final macd = ema12[i]['value']! - ema26[i]['value']!;
        macdData.add({
          'timestamp': ema12[i]['timestamp']!,
          'value': macd,
        });
      }
    }

    return macdData;
  }

  List<Map<String, double>> _calculateEMA(int period) {
    final List<Map<String, double>> emaData = [];
    double multiplier = 2 / (period + 1);
    double initialSMA = 0;

    // Calculate initial SMA
    for (int i = 0; i < period; i++) {
      initialSMA += widget.historicalData[i]['close'];
    }
    initialSMA /= period;

    emaData.add({
      'timestamp': widget.historicalData[period - 1]['timestamp'].toDouble(),
      'value': initialSMA,
    });

    // Calculate EMA
    for (int i = period; i < widget.historicalData.length; i++) {
      final double close = widget.historicalData[i]['close'];
      final double ema = (close - emaData.last['value']!) * multiplier +
          emaData.last['value']!;

      emaData.add({
        'timestamp': widget.historicalData[i]['timestamp'].toDouble(),
        'value': ema,
      });
    }

    return emaData;
  }

  List<Map<String, double>> _calculateBollingerBands(
      int period, double stdDev) {
    final List<Map<String, double>> bbands = [];
    final List<double> closePrices =
        getPrices(); // Using the fixed getPrices method

    for (int i = period - 1; i < closePrices.length; i++) {
      final List<double> subset = closePrices.sublist(i - period + 1, i + 1);
      final double sma = subset.reduce((a, b) => a + b) / period;

      // Calculate Standard Deviation
      final double variance = subset.fold(0.0, (sum, price) {
            return sum + math.pow(price - sma, 2);
          }) /
          period;
      final double standardDeviation = math.sqrt(variance);

      bbands.add({
        'timestamp': widget.historicalData[i]['timestamp'].toDouble(),
        'middle': sma,
        'upper': sma + (standardDeviation * stdDev),
        'lower': sma - (standardDeviation * stdDev),
      });
    }

    return bbands;
  }

  List<double> calculateMACD(List<double> prices,
      {int shortPeriod = 12, int longPeriod = 26, int signalPeriod = 9}) {
    List<double> shortEMA = calculateEMA(prices, shortPeriod);
    List<double> longEMA = calculateEMA(prices, longPeriod);
    List<double> macdLine = List.generate(
      prices.length,
      (i) => i < longPeriod - 1 ? 0 : shortEMA[i] - longEMA[i],
    );

    // Use the signal line in the MACD calculation
    List<double> signalLine = calculateEMA(macdLine, signalPeriod);
    return List.generate(
      prices.length,
      (i) => i < longPeriod - 1 ? 0 : macdLine[i] - signalLine[i],
    );
  }

  List<double> calculateBollingerBands(List<dynamic> prices, int period) {
    // Convert dynamic list to double list
    List<double> priceDoubles =
        prices.map<double>((price) => price.toDouble()).toList();
    double sma = priceDoubles.reduce((a, b) => a + b) / period;
    double standardDeviation = calculateStandardDeviation(priceDoubles, sma);
    return [
      sma + (2 * standardDeviation), // Upper band
      sma, // Middle band
      sma - (2 * standardDeviation), // Lower band
    ];
  }

  List<double> calculateEMA(List<double> prices, int period) {
    double multiplier = 2 / (period + 1);
    List<double> ema = List.filled(prices.length, 0);

    // Start with SMA for the first period
    double sum = 0;
    for (int i = 0; i < period; i++) {
      sum += prices[i];
    }
    ema[period - 1] = sum / period;

    // Calculate EMA
    for (int i = period; i < prices.length; i++) {
      ema[i] = (prices[i] - ema[i - 1]) * multiplier + ema[i - 1];
    }
    return ema;
  }

  double calculateStandardDeviation(List<double> values, double mean) {
    double sumSquaredDiff = 0;
    for (double value in values) {
      sumSquaredDiff += math.pow(value - mean, 2);
    }
    return math.sqrt(sumSquaredDiff / values.length);
  }

  List<double> getClosePrices() {
    return widget.historicalData
        .map((data) => (data['close'] as num).toDouble())
        .toList();
  }

  List<double> getPrices() {
    final List<double> prices = [];
    for (var data in widget.historicalData) {
      prices.add((data['close'] as num).toDouble());
    }
    return prices;
  }

  @override
  Widget build(BuildContext context) {
    final prices = getPrices();
    final bollingerBands = calculateBollingerBands(prices, 20);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text('Technical Analysis',
              style: Theme.of(context).textTheme.titleLarge),
          SizedBox(
            height: 300,
            child: SfCartesianChart(
              primaryXAxis: NumericAxis(),
              primaryYAxis: NumericAxis(),
              series: <CartesianSeries>[
                LineSeries<double, int>(
                  dataSource: prices,
                  xValueMapper: (double price, int index) => index,
                  yValueMapper: (double price, _) => price,
                ),
                LineSeries<double, int>(
                  dataSource: List.filled(prices.length, bollingerBands[0]),
                  xValueMapper: (double price, int index) => index,
                  yValueMapper: (double price, _) => price,
                  dashArray: const [5, 5],
                ),
                LineSeries<double, int>(
                  dataSource: List.filled(prices.length, bollingerBands[2]),
                  xValueMapper: (double price, int index) => index,
                  yValueMapper: (double price, _) => price,
                  dashArray: const [5, 5],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChartIndicator {
  final String name;
  bool isVisible;
  final Color color;
  final List<Map<String, double>> values;

  ChartIndicator({
    required this.name,
    required this.isVisible,
    required this.color,
    required this.values,
  });
}
