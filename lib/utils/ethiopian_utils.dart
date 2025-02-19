class EthiopianCurrencyFormatter {
  static String format(double amount) {
    // Format with Ethiopian Birr symbol and thousands separator
    final formatted = amount.toStringAsFixed(2).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
    return 'ETB $formatted';
  }
}

class EthiopianCalendar {
  static const int yearDiff = 7;
  static const int monthDiff = 8;

  static Map<String, dynamic> getCurrentDate() {
    final now = DateTime.now();
    int ethYear = now.year + yearDiff;
    int ethMonth = now.month + monthDiff;

    if (ethMonth > 13) {
      ethMonth -= 13;
      ethYear += 1;
    }

    return {
      'year': ethYear,
      'month': ethMonth,
      'day': _adjustEthiopianDay(now.day, ethMonth),
      'monthName': getMonthName(ethMonth),
    };
  }

  static int _adjustEthiopianDay(int gregorianDay, int ethiopianMonth) {
    // Ethiopian months have 30 days, except Pagume which has 5 or 6 days
    if (ethiopianMonth == 13) {
      return gregorianDay > 6 ? 5 : gregorianDay;
    }
    return gregorianDay > 30 ? 30 : gregorianDay;
  }

  static String getMonthName(int month) {
    final months = [
      'መስከረም', // Meskerem
      'ጥቅምት', // Tikimt
      'ኅዳር', // Hidar
      'ታኅሣሥ', // Tahsas
      'ጥር', // Tir
      'የካቲት', // Yekatit
      'መጋቢት', // Megabit
      'ሚያዝያ', // Miyazia
      'ግንቦት', // Ginbot
      'ሰኔ', // Sene
      'ሐምሌ', // Hamle
      'ነሐሴ', // Nehase
      'ጳጉሜ', // Pagume
    ];
    return months[month - 1];
  }
}

class EthiopianMarketHours {
  // Ethiopian market trading hours (9:00 AM - 4:00 PM EAT)
  static bool isMarketOpen() {
    final now =
        DateTime.now().toUtc().add(const Duration(hours: 3)); // EAT is UTC+3
    final weekday = now.weekday;

    // Market is closed on weekends
    if (weekday == DateTime.saturday || weekday == DateTime.sunday) {
      return false;
    }

    final hour = now.hour;
    return hour >= 9 && hour < 16;
  }

  static String getMarketStatus() {
    if (isMarketOpen()) {
      return 'ገበያው ክፍት ነው'; // Market is Open
    }
    return 'ገበያው ዝግ ነው'; // Market is Closed
  }

  static String getNextMarketOpenTime() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 3));

    if (isMarketOpen()) {
      return 'ገበያው እስከ 4:00 PM ክፍት ነው'; // Market is open until 4:00 PM
    }

    final nextOpeningTime = _getNextOpeningTime(now);
    return 'ገበያው በ ${_formatDateTime(nextOpeningTime)} ይከፈታል'; // Market opens at...
  }

  static DateTime _getNextOpeningTime(DateTime now) {
    var nextOpen = DateTime(now.year, now.month, now.day, 9, 0);

    if (now.hour >= 16) {
      nextOpen = nextOpen.add(const Duration(days: 1));
    }

    while (nextOpen.weekday == DateTime.saturday ||
        nextOpen.weekday == DateTime.sunday) {
      nextOpen = nextOpen.add(const Duration(days: 1));
    }

    return nextOpen;
  }

  static String _formatDateTime(DateTime dt) {
    final ethiopianDate = EthiopianCalendar.getCurrentDate();
    return '${ethiopianDate['monthName']} ${ethiopianDate['day']}, ${ethiopianDate['year']} 9:00 AM';
  }
}
