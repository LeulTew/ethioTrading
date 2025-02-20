class EthiopianCurrencyFormatter {
  static String format(double amount) {
    final formatter = amount.toStringAsFixed(2);
    final parts = formatter.split('.');
    final wholePart = parts[0];
    final decimalPart = parts[1];

    // Add thousands separators
    final chars = wholePart.split('').reversed.toList();
    final formatted = [];
    for (var i = 0; i < chars.length; i++) {
      if (i > 0 && i % 3 == 0) {
        formatted.add(',');
      }
      formatted.add(chars[i]);
    }

    return 'ETB ${formatted.reversed.join('')}.$decimalPart';
  }

  static double parse(String amount) {
    // Remove currency symbol and commas
    final cleaned = amount.replaceAll('ETB', '').replaceAll(',', '').trim();
    return double.parse(cleaned);
  }
}

class EthiopianCalendar {
  static Map<String, dynamic> getCurrentDate() {
    // Ethiopian calendar is 7-8 years behind Gregorian calendar
    final now = DateTime.now();
    int ethYear = now.year - 7;
    int ethMonth = now.month;
    int ethDay = now.day;

    // Adjust for Ethiopian calendar's different new year start (September 11/12)
    if (now.month > 9 || (now.month == 9 && now.day >= 11)) {
      ethYear += 1;
    }

    return {
      'year': ethYear,
      'month': ethMonth,
      'day': ethDay,
      'monthName': _getEthiopianMonthName(ethMonth),
    };
  }

  static String _getEthiopianMonthName(int month) {
    final months = [
      'መስከረም', // Meskerem
      'ጥቅምት', // Tikimt
      'ህዳር', // Hidar
      'ታህሳስ', // Tahsas
      'ጥር', // Tir
      'የካቲት', // Yekatit
      'መጋቢት', // Megabit
      'ሚያዚያ', // Miazia
      'ግንቦት', // Ginbot
      'ሰኔ', // Sene
      'ሐምሌ', // Hamle
      'ነሐሴ', // Nehase
      'ጳጉሜ', // Pagume
    ];
    return months[(month - 1) % 13];
  }
}

class EthiopianMarketHours {
  static bool isMarketOpen() {
    final now = DateTime.now();
    final ethiopianTime = now.toUtc().add(const Duration(hours: 3)); // UTC+3

    // Market is closed on weekends
    if (ethiopianTime.weekday == DateTime.saturday ||
        ethiopianTime.weekday == DateTime.sunday) {
      return false;
    }

    // Market hours: 9:00 AM - 4:00 PM Ethiopian time
    final hour = ethiopianTime.hour;
    return hour >= 9 && hour < 16;
  }

  static String getMarketStatus() {
    if (!isMarketOpen()) {
      final now = DateTime.now();
      final ethiopianTime = now.toUtc().add(const Duration(hours: 3));

      if (ethiopianTime.weekday == DateTime.saturday ||
          ethiopianTime.weekday == DateTime.sunday) {
        return 'ገበያው ዝግ ነው - ወደ ሚቀጥለው የስራ ቀን';
      }

      if (ethiopianTime.hour < 9) {
        return 'ገበያው ዝግ ነው - 9:00 AM ይከፈታል';
      }

      return 'ገበያው ዝግ ነው - ነገ 9:00 AM ይከፈታል';
    }

    return 'ገበያው ክፍት ነው';
  }

  static String getNextMarketOpenTime() {
    final now = DateTime.now();
    final ethiopianTime = now.toUtc().add(const Duration(hours: 3));

    if (isMarketOpen()) {
      return 'ገበያው አሁን ክፍት ነው';
    }

    DateTime nextOpen;
    if (ethiopianTime.hour < 9) {
      // Market opens today at 9 AM
      nextOpen = DateTime(
          ethiopianTime.year, ethiopianTime.month, ethiopianTime.day, 9, 0);
    } else {
      // Market opens next business day at 9 AM
      nextOpen = DateTime(
              ethiopianTime.year, ethiopianTime.month, ethiopianTime.day, 9, 0)
          .add(const Duration(days: 1));

      // Skip weekends
      while (nextOpen.weekday == DateTime.saturday ||
          nextOpen.weekday == DateTime.sunday) {
        nextOpen = nextOpen.add(const Duration(days: 1));
      }
    }

    return 'ገበያው ${_formatDateTime(nextOpen)} ይከፈታል';
  }

  static String _formatDateTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final period = dt.hour < 12 ? 'AM' : 'PM';
    return '$hour:00 $period';
  }
}
