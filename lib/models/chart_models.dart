import 'package:flutter/material.dart';

class FlSpot {
  final double x;
  final double y;

  FlSpot(this.x, this.y);
}

class Candle {
  final DateTime date;
  final double high;
  final double low;
  final double open;
  final double close;
  final double volume;

  Candle({
    required this.date,
    required this.high,
    required this.low,
    required this.open,
    required this.close,
    required this.volume,
  });
}

extension ColorHelpers on Color {
  Color withValues({int? red, int? green, int? blue, double? alpha}) {
    return Color.fromRGBO(
      red ?? r.toInt(),
      green ?? g.toInt(),
      blue ?? b.toInt(),
      alpha ?? a,
    );
  }
}
