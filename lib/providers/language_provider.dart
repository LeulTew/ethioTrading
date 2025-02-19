import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider with ChangeNotifier {
  static const String _languageKey = 'language';
  static const String defaultLanguage = 'en';

  final SharedPreferences prefs;
  late String _currentLanguage;

  LanguageProvider(this.prefs) {
    _currentLanguage = prefs.getString(_languageKey) ?? defaultLanguage;
  }

  String get currentLanguage => _currentLanguage;

  Future<void> setLanguage(String languageCode) async {
    if (languageCode != _currentLanguage) {
      await prefs.setString(_languageKey, languageCode);
      _currentLanguage = languageCode;
      notifyListeners();
    }
  }

  String translate(String key) {
    final translations =
        _currentLanguage == 'en' ? englishTranslations : amharicTranslations;
    return translations[key] ?? englishTranslations[key] ?? key;
  }
}

const Map<String, String> englishTranslations = {
  // Common
  'app_title': 'Ethiopian Trading App',
  'home': 'Home',
  'market': 'Market',
  'portfolio': 'Portfolio',
  'profile': 'Profile',

  // Authentication
  'login': 'Login',
  'register': 'Register',
  'email': 'Email',
  'password': 'Password',
  'forgot_password': 'Forgot Password?',
  'new_user': 'New user? Register here',
  'already_member': 'Already a member? Login',
  'please_enter_email': 'Please enter your email',
  'enter_valid_email': 'Please enter a valid email',
  'please_enter_password': 'Please enter your password',
  'password_too_short': 'Password must be at least 6 characters',
  'password_reset_sent': 'Password reset instructions sent to your email',

  // Actions
  'save_changes': 'Save Changes',
  'back': 'Back',
  'send': 'Send',
  'confirm': 'Confirm',
  'cancel': 'Cancel',

  // Theme
  'light_mode': 'Light Mode',
  'dark_mode': 'Dark Mode',
  'system_default': 'System Default',

  // Trading
  'buy': 'Buy',
  'sell': 'Sell',
  'trade': 'Trade',
  'price': 'Price',
  'quantity': 'Quantity',
  'total': 'Total',
  'shares': 'Shares',

  // Market Data
  'market_data': 'Market Data',
  'performance': 'Performance',
  'overview': 'Overview',
  'statistics': 'Statistics',
  'chart': 'Chart',
  'news': 'News',
  'volume': 'Volume',
  'market_cap': 'Market Cap',
  'sector': 'Sector',
  'ownership': 'Ownership',
  'last_updated': 'Last Updated',
  'market_status': 'Market Status',
  'market_open': 'Market Open',
  'market_closed': 'Market Closed',

  // Time Periods
  'day': '1 Day',
  'week': '1 Week',
  'month': '1 Month',
  'quarter': '3 Months',
  'year': '1 Year',

  // Portfolio
  'total_value': 'Total Value',
  'today_change': 'Today\'s Change',
  'total_change': 'Total Change',
  'holdings': 'Holdings',
  'transactions': 'Transactions',
  'asset_distribution': 'Asset Distribution',

  // Watchlist
  'add_to_watchlist': 'Add to Watchlist',
  'remove_from_watchlist': 'Remove from Watchlist',
  'added_to_watchlist': 'Added to watchlist',
  'removed_from_watchlist': 'Removed from watchlist',

  // Market Analysis
  'sector_performance': 'Sector Performance',
  'top_movers': 'Top Movers',
  'top_gainers': 'Top Gainers',
  'top_losers': 'Top Losers',
  'market_index': 'Market Index',

  // Search
  'search_stocks': 'Search stocks...',

  // Misc
  'notifications': 'Notifications',
  'notifications_coming_soon': 'Notifications feature coming soon',
  'language': 'Language',
  'english': 'English',
  'amharic': 'አማርኛ',
};

const Map<String, String> amharicTranslations = {
  // ... existing Amharic translations ...
};
