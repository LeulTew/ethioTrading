import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../providers/language_provider.dart';

class EthiopianCurrencyFormatter {
  static String format(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'en_US',
      symbol: 'ETB ',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  // Add the missing formatCompact method
  static String formatCompact(double amount) {
    final formatter = NumberFormat.compactCurrency(
      locale: 'en_US',
      symbol: 'ETB ',
      decimalDigits: 1,
    );
    return formatter.format(amount);
  }

  // Format for volume display
  static String formatVolume(double volume) {
    if (volume >= 1000000) {
      return '${(volume / 1000000).toStringAsFixed(2)}M';
    } else if (volume >= 1000) {
      return '${(volume / 1000).toStringAsFixed(2)}K';
    } else {
      return volume.toStringAsFixed(0);
    }
  }
}

class EthiopianCalendar {
  static final List<String> _ethiopianMonths = [
    'Meskerem',
    'Tikimt',
    'Hidar',
    'Tahsas',
    'Tir',
    'Yekatit',
    'Megabit',
    'Miazia',
    'Ginbot',
    'Sene',
    'Hamle',
    'Nehase',
    'Pagume'
  ];

  static Map<String, dynamic> getCurrentDate() {
    final gregorianDate = DateTime.now();
    // Ethiopian calendar is 7 years and 8 months behind Gregorian calendar
    final ethiopianYear = gregorianDate.year - 7;
    var ethiopianMonth = gregorianDate.month + 8;
    if (ethiopianMonth > 13) {
      ethiopianMonth -= 13;
    }

    return {
      'year': ethiopianYear,
      'month': ethiopianMonth,
      'monthName': _ethiopianMonths[ethiopianMonth - 1],
      'day': gregorianDate.day,
    };
  }

  // Function to convert Gregorian to Islamic date (Hijri)
  static Map<String, int> gregorianToHijri(DateTime date) {
    // Rough approximation: Hijri year is about 11 days shorter than Gregorian
    final gregorianYear = date.year;
    final gregorianMonth = date.month;
    final gregorianDay = date.day;

    // Base date: 1/1/2000 Gregorian = 23/9/1420 Hijri
    const baseGregorianYear = 2000;
    const baseHijriYear = 1420;

    // Calculate days since base date
    final daysSinceBase = DateTime(gregorianYear, gregorianMonth, gregorianDay)
        .difference(DateTime(baseGregorianYear, 1, 1))
        .inDays;

    // Convert to Hijri (approximate)
    final hijriDays = daysSinceBase * 354 / 365; // Hijri year is 354 days
    final yearsSinceBase = (hijriDays / 354).floor();
    final hijriYear = baseHijriYear + yearsSinceBase;

    // Calculate month and day (approximate)
    final daysInYear = hijriDays % 354;
    final month = ((daysInYear / 29.5) + 1).floor();
    final day = (daysInYear % 29.5).floor() + 1;

    return {
      'year': hijriYear,
      'month': month,
      'day': day,
    };
  }
}

class EthiopianMarketHours {
  static const int marketOpenHour = 9;
  static const int marketCloseHour = 15;

  static const Map<int, List<int>> _fixedHolidays = {
    1: [7, 19],
    3: [2],
    5: [1, 28],
    9: [11, 27],
  };

  static bool _isVariableHoliday(DateTime date) {
    final ethiopianDate = EthiopianCalendar.getCurrentDate();
    final hijriDate = EthiopianCalendar.gregorianToHijri(date);

    if (ethiopianDate['month'] == 8) {
      if (ethiopianDate['day'] >= 14 && ethiopianDate['day'] <= 16) {
        return true;
      }
    }

    final hijriMonth = hijriDate['month'] ?? 0;
    final hijriDay = hijriDate['day'] ?? 0;

    if (hijriMonth == 10 && hijriDay <= 3) {
      return true;
    }

    if (hijriMonth == 12 && hijriDay >= 10 && hijriDay <= 12) {
      return true;
    }

    if (hijriMonth == 3 && hijriDay == 12) {
      return true;
    }

    return false;
  }

  static bool isHoliday(DateTime date) {
    final fixedHolidayDays = _fixedHolidays[date.month];
    if (fixedHolidayDays != null && fixedHolidayDays.contains(date.day)) {
      return true;
    }

    return _isVariableHoliday(date);
  }

  static bool isMarketOpen() {
    final now = DateTime.now().toLocal();
    final hour = now.hour;
    final minute = now.minute;

    if (now.weekday == DateTime.saturday || now.weekday == DateTime.sunday) {
      return false;
    }

    if (isHoliday(now)) {
      return false;
    }

    if (hour < marketOpenHour || hour >= marketCloseHour) {
      return false;
    }

    if (hour == marketCloseHour - 1 && minute >= 30) {
      return false;
    }

    return true;
  }

  static String getMarketStatus() {
    final now = DateTime.now().toLocal();
    final hour = now.hour;

    if (now.weekday == DateTime.saturday || now.weekday == DateTime.sunday) {
      final nextOpeningDate = _getNextTradingDay();
      final formatter = DateFormat('EEEE, MMMM d');
      return 'Market Closed - Opens ${formatter.format(nextOpeningDate)} at 9:00 AM';
    }

    if (isHoliday(now)) {
      final nextOpeningDate = _getNextTradingDay();
      final formatter = DateFormat('EEEE, MMMM d');
      return 'Market Closed (Holiday) - Opens ${formatter.format(nextOpeningDate)} at 9:00 AM';
    }

    if (hour < marketOpenHour) {
      return 'Pre-market - Opens at 9:00 AM';
    } else if (hour >= marketCloseHour ||
        (hour == marketCloseHour - 1 && now.minute >= 30)) {
      return 'Market Closed - Opens next trading day at 9:00 AM';
    }

    return 'Market Open - Closes at 2:30 PM';
  }

  // Add this method to provide a shortened market status format
  static String getShortMarketStatus() {
    final now = DateTime.now();
    final isWeekend =
        now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;
    final hour = now.hour;

    if (isWeekend) {
      return "Closed • Weekend";
    }

    if (hour < 9) {
      return "Opens at 9:00 AM";
    } else if (hour >= 9 && hour < 15) {
      return "Open • Closes at 3:00 PM";
    } else {
      return "Closed • Opens tomorrow 9:00 AM";
    }
  }

  static DateTime _getNextTradingDay() {
    var date = DateTime.now().toLocal();
    do {
      date = date.add(const Duration(days: 1));
    } while (date.weekday == DateTime.saturday ||
        date.weekday == DateTime.sunday ||
        isHoliday(date));
    return date;
  }

  static String getMarketPhase() {
    if (!isMarketOpen()) return 'closed';

    final now = DateTime.now().toLocal();
    final hour = now.hour;

    if (hour < 10) return 'opening';
    if (hour > 13) return 'closing';
    return 'main';
  }

  static Map<String, dynamic> getMarketHours() {
    final now = DateTime.now().toLocal();
    final isOpen = isMarketOpen();
    final status = getMarketStatus();
    final phase = getMarketPhase();

    return {
      'isOpen': isOpen,
      'status': status,
      'phase': phase,
      'openTime': '9:00 AM',
      'closeTime': '2:30 PM',
      'currentTime': DateFormat('h:mm a').format(now),
    };
  }
}

class TradingValidator {
  static const double maxDailyPriceChange = 0.10;
  static const double minTradeAmount = 100.0;

  static bool isValidPrice(double currentPrice, double basePrice) {
    final maxChange = basePrice * maxDailyPriceChange;
    return (currentPrice - basePrice).abs() <= maxChange;
  }

  static bool isValidTradeAmount(double amount) {
    return amount >= minTradeAmount;
  }

  static double calculateCommission(double tradeAmount) {
    const double baseCommission = 0.0027;
    const double minCommission = 50.0;

    final commission = tradeAmount * baseCommission;
    return commission < minCommission ? minCommission : commission;
  }

  static Map<String, double> calculateTradingFees({
    required double amount,
    bool isBuy = true,
  }) {
    final commission = calculateCommission(amount);
    final vat = commission * 0.15;
    final capitalGainsTax = isBuy ? 0.0 : amount * 0.15;

    return {
      'commission': commission,
      'vat': vat,
      'capitalGainsTax': capitalGainsTax,
      'total': commission + vat + capitalGainsTax,
    };
  }
}

class MarketStatistics {
  static Map<String, dynamic> calculateMarketMetrics(
      List<Map<String, dynamic>> stocks) {
    if (stocks.isEmpty) {
      return {
        'totalVolume': 0.0,
        'totalValue': 0.0,
        'advancers': 0,
        'decliners': 0,
        'unchanged': 0,
        'marketIndex': 0.0,
        'indexChange': 0.0,
      };
    }

    double totalVolume = 0;
    double totalValue = 0;
    int advancers = 0;
    int decliners = 0;
    int unchanged = 0;
    double weightedIndexValue = 0;
    double previousIndexValue = 0;

    for (final stock in stocks) {
      totalVolume += stock['volume'] as double;
      final value = (stock['price'] as double) * (stock['volume'] as double);
      totalValue += value;

      final change = stock['change'] as double;
      if (change > 0) {
        advancers++;
      } else if (change < 0) {
        decliners++;
      } else {
        unchanged++;
      }

      weightedIndexValue += value;
      previousIndexValue += value / (1 + change / 100);
    }

    final indexChange =
        ((weightedIndexValue - previousIndexValue) / previousIndexValue) * 100;

    return {
      'totalVolume': totalVolume,
      'totalValue': totalValue,
      'advancers': advancers,
      'decliners': decliners,
      'unchanged': unchanged,
      'marketIndex': weightedIndexValue,
      'indexChange': indexChange,
    };
  }
}

class EthiopianUtils {
  static String timeAgo(DateTime dateTime, LanguageProvider lang) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return lang.translate('just_now');
    } else if (difference.inMinutes < 60) {
      // Fix: The translate method expects only one parameter - use the correct parameter format
      return lang
          .translate('min_ago_param')
          .replaceAll('{minutes}', difference.inMinutes.toString());
    } else if (difference.inHours < 24) {
      return lang
          .translate('hours_ago_param')
          .replaceAll('{hours}', difference.inHours.toString());
    } else if (difference.inDays < 7) {
      return lang
          .translate('days_ago_param')
          .replaceAll('{days}', difference.inDays.toString());
    } else {
      final formatter = DateFormat('MMM d, y');
      return formatter.format(dateTime);
    }
  }
}

// Extension for color opacity with properly converted types
extension ColorExt on Color {
  Color withValues({double? red, double? green, double? blue, double? alpha}) {
    return Color.fromRGBO(
      // Fix: Convert to int by using toInt() instead of relying on implicit conversion
      red != null ? (red * 255).toInt() : r.toInt(),
      green != null ? (green * 255).toInt() : g.toInt(),
      blue != null ? (blue * 255).toInt() : b.toInt(),
      alpha ?? a,
    );
  }
}
