import 'package:intl/intl.dart';

class EthiopianCurrencyFormatter {
  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'am_ET',
    symbol: 'ETB',
    decimalDigits: 2,
  );

  static String format(double amount) {
    return _formatter.format(amount);
  }

  static double parse(String amount) {
    return _formatter.parse(amount).toDouble();
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
  // Ethiopian market hours are from 9:00 AM to 3:00 PM EAT (UTC+3)
  static const int marketOpenHour = 9;
  static const int marketCloseHour = 15;

  // List of fixed Ethiopian holidays (month and day in Gregorian calendar)
  static const Map<int, List<int>> _fixedHolidays = {
    1: [
      7,
      19
    ], // Genna (Ethiopian Christmas) - Jan 7, Timkat (Epiphany) - Jan 19
    3: [2], // Adwa Victory Day - March 2
    5: [1, 28], // Labor Day - May 1, Derg Downfall Day - May 28
    9: [11, 27], // Ethiopian New Year (Enkutatash) - Sept 11, Meskel - Sept 27
  };

  // List of variable Ethiopian holidays (calculated based on Ethiopian and Islamic calendars)
  static bool _isVariableHoliday(DateTime date) {
    final ethiopianDate = EthiopianCalendar.getCurrentDate();
    final hijriDate = EthiopianCalendar.gregorianToHijri(date);

    // Fasika (Ethiopian Easter) - Calculate based on Ethiopian calendar
    if (ethiopianDate['month'] == 8) {
      if (ethiopianDate['day'] >= 14 && ethiopianDate['day'] <= 16) {
        return true;
      }
    }

    final hijriMonth = hijriDate['month'] ?? 0;
    final hijriDay = hijriDate['day'] ?? 0;

    // Eid Al-Fitr (1st Shawwal)
    if (hijriMonth == 10 && hijriDay <= 3) {
      return true;
    }

    // Eid Al-Adha (10th Dhul Hijjah)
    if (hijriMonth == 12 && hijriDay >= 10 && hijriDay <= 12) {
      return true;
    }

    // Prophet Muhammad's Birthday (12th Rabi' al-Awwal)
    if (hijriMonth == 3 && hijriDay == 12) {
      return true;
    }

    return false;
  }

  static bool isHoliday(DateTime date) {
    // Check fixed holidays
    final fixedHolidayDays = _fixedHolidays[date.month];
    if (fixedHolidayDays != null && fixedHolidayDays.contains(date.day)) {
      return true;
    }

    // Check variable holidays
    return _isVariableHoliday(date);
  }

  // Market is closed on weekends and Ethiopian holidays
  static bool isMarketOpen() {
    final now = DateTime.now().toLocal();
    final hour = now.hour;
    final minute = now.minute;

    // Check if it's weekend
    if (now.weekday == DateTime.saturday || now.weekday == DateTime.sunday) {
      return false;
    }

    // Check if it's a holiday
    if (isHoliday(now)) {
      return false;
    }

    // Check if within trading hours
    if (hour < marketOpenHour || hour >= marketCloseHour) {
      return false;
    }

    // Special case for market closing time
    if (hour == marketCloseHour - 1 && minute >= 30) {
      return false; // Market closes at 14:30
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
}

class TradingValidator {
  // Maximum daily price movement allowed (10% in Ethiopian market)
  static const double maxDailyPriceChange = 0.10;

  // Minimum trade amount in ETB
  static const double minTradeAmount = 100.0;

  static bool isValidPrice(double currentPrice, double basePrice) {
    final maxChange = basePrice * maxDailyPriceChange;
    return (currentPrice - basePrice).abs() <= maxChange;
  }

  static bool isValidTradeAmount(double amount) {
    return amount >= minTradeAmount;
  }

  static double calculateCommission(double tradeAmount) {
    // Ethiopian market commission structure
    const double baseCommission = 0.0027; // 0.27%
    const double minCommission = 50.0; // Minimum 50 ETB

    final commission = tradeAmount * baseCommission;
    return commission < minCommission ? minCommission : commission;
  }

  static Map<String, double> calculateTradingFees({
    required double amount,
    bool isBuy = true,
  }) {
    final commission = calculateCommission(amount);
    // VAT on commission (15%)
    final vat = commission * 0.15;
    // Capital gains tax (15% on sell transactions)
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

      // Market cap weighted index calculation
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
