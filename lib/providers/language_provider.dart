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
    String translatedText =
        translations[key] ?? englishTranslations[key] ?? key;

    // For display purposes, replace underscores with spaces and capitalize words
    // This ensures clean text in the UI while maintaining underscore keys in code
    return formatDisplayText(translatedText);
  }

  // Format display text by removing underscores and properly capitalizing
  String formatDisplayText(String text) {
    // Always replace underscores with spaces for display
    String formattedText = text.replaceAll('_', ' ');

    // If the text is in English (contains ASCII characters), capitalize each word
    if (RegExp(r'^[\x00-\x7F]+$').hasMatch(formattedText)) {
      formattedText = formattedText.split(' ').map((word) {
        if (word.isNotEmpty) {
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        }
        return word;
      }).join(' ');
    }

    return formattedText;
  }

  // Add a method to force language update across all screens
  Future<void> forceLanguageUpdate() async {
    notifyListeners();
    // Save current language preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', _currentLanguage);
  }

  // Add method to initialize language from saved preferences
  Future<void> initializeLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString('language') ?? 'en';
    notifyListeners();
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

  // Profile
  'edit_profile': 'Edit Profile',
  'save_changes': 'Save Changes',
  'cancel': 'Cancel',
  'profile_updated': 'Profile updated successfully',
  'update_error': 'Error updating profile',
  'username': 'Username',
  'phone_number': 'Phone Number',
  'address': 'Address',
  'bank_account': 'Bank Account Number',
  'verified_account': 'Verified Account',
  'verification_required': 'Verification Required',
  'verify_now': 'Verify Now',
  'account_verified': 'Your account is fully verified',
  'complete_verification':
      'Complete verification to unlock full trading features',
  'upload_photo': 'Upload Photo',

  // Trading Levels
  'trading_level': 'Trading Level',
  'beginner': 'Beginner',
  'intermediate': 'Intermediate',
  'advanced': 'Advanced',
  'current_level': 'Current Level',
  'daily_limit': 'Daily Trading Limit',
  'available_balance': 'Available Balance',
  'upgrade_level': 'Upgrade Your Trading Level',
  'request_upgrade': 'Request Upgrade',

  // Settings & Preferences
  'preferences': 'Preferences',
  'language': 'Language',
  'theme': 'Theme',
  'light_mode': 'Light Mode',
  'dark_mode': 'Dark Mode',
  'system_default': 'System Default',

  // Security
  'security': 'Security',
  'change_password': 'Change Password',
  'two_factor': 'Two-Factor Authentication',
  'trusted_devices': 'Trusted Devices',
  'login_history': 'Login History',
  'security_notifications': 'Security Notifications',
  'activity_log': 'Activity Log',

  // Market Data
  'market_overview': 'Market Overview',
  'top_movers': 'Top Movers',
  'sector_performance': 'Sector Performance',
  'market_index': 'Market Index',
  'volume': 'Volume',
  'change': 'Change',
  'market_cap': 'Market Cap',
  'price': 'Price',
  'open': 'Open',
  'high': 'High',
  'low': 'Low',
  'close': 'Close',
  'search_stocks': 'Search Stocks',
  'all_sectors': 'All Sectors',
  'Bank': 'Bank',
  'Transport': 'Transport',
  'Telecom': 'Telecom',
  'Utility': 'Utility',
  'Agriculture': 'Agriculture',
  'Manufacturing': 'Manufacturing',
  'order_type': 'Order Type',
  'quantity': 'Quantity',
  'total': 'Total',
  'place_order': 'Place Order',
  'confirm_order': 'Confirm Order',
  'order_success': 'Order placed successfully',
  'order_error': 'Error placing order',

  // Market Screen Enhanced Translations
  'search_markets': 'Search Markets',
  'gainers': 'Gainers',
  'losers': 'Losers',
  'most_active': 'Most Active',
  'tradable_assets': 'Tradable Assets',
  'view_all': 'View All',
  'ethiopian_market': 'Ethiopian Market',
  'international_market': 'International Market',
  'ethiopian_market_index': 'Ethiopian Market Index',
  'international_market_index': 'International Market Index',
  'ethiopian_news': 'Ethiopian News',
  'markets': 'Markets',
  'no_search_results': 'No search results found',
  'no_assets_available': 'No assets available',
  'no_news_available': 'No news available',

  // Notifications
  'notifications': 'Notifications',
  'notification_settings': 'Notification Settings',
  'price_alerts': 'Price Alerts',
  'news_alerts': 'News Alerts',
  'trade_confirmations': 'Trade Confirmations',

  // Market Status
  'market_status': 'Market Status',
  'market_open': 'Market Open',
  'market_closed': 'Market Closed',
  'next_opening': 'Next Opening',
  'pre_market': 'Pre-market',
  'after_hours': 'After Hours',

  // Error Messages
  'error_occurred': 'An error occurred',
  'try_again': 'Please try again',
  'connection_error': 'Connection error',
  'validation_error': 'Please check your input',
  'insufficient_funds': 'Insufficient funds',
  'invalid_quantity': 'Invalid quantity',
  'invalid_price': 'Invalid price',

  // Enhanced Login Screen
  'welcome_back': 'Welcome Back',
  'login_subtitle':
      'Sign in to continue trading on Ethiopia\'s premier trading platform',
  'remember_me': 'Remember me',
  'new_user_prompt': 'Don\'t have an account?',
  'login_success': 'Login successful',
  'email_hint': 'Enter your email address',
  'password_hint': 'Enter your password',
  'invalid_credentials': 'Invalid email or password',
  'network_error': 'Network connection error',
  'server_error': 'Server error occurred',

  // Trading related terms
  'trade_asset': 'Trade Asset',
  'current_price': 'Current Price',
  'trade_type': 'Trade Type',
  'buy': 'Buy',
  'sell': 'Sell',
  'shares': 'Shares',
  'confirm': 'Confirm',
  'buy_success': 'Purchase Successful',
  'sell_success': 'Sale Successful',

  // Notification related terms
  'no_notifications': 'No Notifications',
  'clear_all': 'Clear All',
  'mark_all_read': 'Mark All as Read',
  'order_executed': 'Order Executed',
  'market_alert': 'Market Alert',
  'price_alert': 'Price Alert',
  'system_notification': 'System Notification',
  'view_order_details': 'View Order Details',

  // User action confirmations
  'saved_to_favorites': 'Saved to Favorites',
  'removed_from_favorites': 'Removed from Favorites',
};

const Map<String, String> amharicTranslations = {
  // Common
  'app_title': 'የኢትዮጵያ የንግድ መተግበሪያ',
  'home': 'መነሻ',
  'market': 'ገበያ',
  'portfolio': 'ፖርትፎሊዮ',
  'profile': 'መገለጫ',
  'ethiopia': 'ኢትዮጵያ',
  'international': 'ዓለም አቀፍ',
  'news': 'ዜና',
  'settings': 'ቅንብሮች',
  'search': 'ፈልግ',
  'loading': 'በመጫን ላይ...',
  'refresh': 'አድስ',
  'cancel': 'ሰርዝ',
  'save': 'አስቀምጥ',
  'edit': 'አስተካክል',
  'delete': 'ሰርዝ',
  'confirm': 'አረጋግጥ',
  'success': 'ተሳክቷል',
  'error': 'ስህተት',
  'warning': 'ማስጠንቀቂያ',
  'info': 'መረጃ',

  // Authentication
  'login': 'ግባ',
  'register': 'ተመዝገብ',
  'email': 'ኢሜይል',
  'password': 'የይለፍ ቃል',
  'forgot_password': 'የይለፍ ቃል ረሳኽ?',
  'new_user': 'አዲስ ተጠቃሚ? እዚህ ይመዝገቡ',
  'already_member': 'አባል ነዎት? ይግቡ',
  'please_enter_email': 'እባክዎ ኢሜይልዎን ያስገቡ',
  'enter_valid_email': 'እባክዎ ትክክለኛ ኢሜይል ያስገቡ',
  'please_enter_password': 'እባክዎ የይለፍ ቃልዎን ያስገቡ',
  'password_too_short': 'የይለፍ ቃል ቢያንስ 6 ቁምፊዎች መሆን አለበት',
  'password_reset_sent': 'የይለፍ ቃል ዳግም ማስጀመሪያ መመሪያዎች ወደ ኢሜይልዎ ተልከዋል',
  'logout': 'ውጣ',
  'sign_in_with_google': 'በጉግል ይግቡ',
  'sign_in_with_apple': 'በአፕል ይግቡ',
  'sign_in_with_facebook': 'በፌስቡክ ይግቡ',
  'sign_in_with_twitter': 'በትዊተር ይግቡ',
  'sign_in_with_phone': 'በስልክ ቁጥር ይግቡ',
  'phone_number': 'ስልክ ቁጥር',
  'verification_code': 'የማረጋገጫ ኮድ',
  'send_code': 'ኮድ ላክ',
  'verify': 'አረጋግጥ',
  'resend_code': 'ኮድ እንደገና ላክ',
  'code_sent': 'ኮድ ተልኳል',
  'code_expired': 'ኮድ ጊዜው አልፏል',
  'invalid_code': 'ልክ ያልሆነ ኮድ',
  'invalid_credentials': 'ልክ ያልሆነ ኢሜይል ወይም የይለፍ ቃል',
  'account_created': 'መለያ ተፈጥሯል',
  'account_exists': 'መለያ አስቀድሞ አለ',
  'account_not_found': 'መለያ አልተገኘም',
  'account_disabled': 'መለያ ተዘግቷል',
  'account_locked': 'መለያ ተቆልፏል',
  'account_deleted': 'መለያ ተሰርዟል',

  // Profile
  'edit_profile': 'መገለጫ አስተካክል',
  'save_changes': 'ለውጦችን አስቀምጥ',
  'profile_updated': 'መገለጫ በተሳካ ሁኔታ ተዘምኗል',
  'update_error': 'መገለጫን ማዘመን ላይ ስህተት',
  'username': 'የተጠቃሚ ስም',
  'address': 'አድራሻ',
  'city': 'ከተማ',
  'country': 'ሀገር',
  'postal_code': 'የፖስታ ኮድ',
  'language': 'ቋንቋ',
  'theme': 'ገጽታ',
  'light': 'ብርሃን',
  'dark': 'ጨለማ',
  'system': 'የስርዓት',
  'notifications': 'ማሳወቂያዎች',
  'enable_notifications': 'ማሳወቂያዎችን አንቃ',
  'disable_notifications': 'ማሳወቂያዎችን አጥፋ',
  'account': 'መለያ',
  'security': 'ደህንነት',
  'privacy': 'ግላዊነት',
  'terms': 'የአገልግሎት ውሎች',
  'about': 'ስለ',
  'help': 'እገዛ',
  'contact': 'ያግኙን',
  'feedback': 'አስተያየት',
  'rate': 'ደረጃ ይስጡ',
  'share': 'አጋራ',
  'invite': 'ጋብዝ',
  'version': 'ስሪት',

  // Market
  'stocks': 'አክሲዮኖች',
  'bonds': 'ቦንዶች',
  'commodities': 'ዕቃዎች',
  'currencies': 'ምንዛሪዎች',
  'crypto': 'ክሪፕቶ',
  'indices': 'ኢንዴክሶች',
  'etfs': 'ኢቲኤፍዎች',
  'futures': 'ፊውቸርስ',
  'options': 'ኦፕሽኖች',
  'watchlist': 'የክትትል ዝርዝር',
  'add_to_watchlist': 'ወደ ክትትል ዝርዝር አክል',
  'remove_from_watchlist': 'ከክትትል ዝርዝር አስወግድ',
  'market_cap': 'የገበያ ካፒታል',
  'volume': 'መጠን',
  'open': 'መክፈቻ',
  'high': 'ከፍተኛ',
  'low': 'ዝቅተኛ',
  'close': 'መዝጊያ',
  'previous_close': 'ቀዳሚ መዝጊያ',
  'change': 'ለውጥ',
  'change_percent': 'የለውጥ መቶኛ',
  'day_range': 'የቀን ክልል',
  'year_range': 'የዓመት ክልል',
  'avg_volume': 'አማካይ መጠን',
  'pe_ratio': 'ፒኢ ጥምርታ',
  'eps': 'ኢፒኤስ',
  'dividend': 'ድርሻ',
  'yield': 'ትርፍ',
  'market_status': 'የገበያ ሁኔታ',
  'market_open': 'ገበያ ክፍት',
  'market_closed': 'ገበያ ዝግ',
  'pre_market': 'ቅድመ ገበያ',
  'after_hours': 'ከሰዓት በኋላ',
  'last_updated': 'የመጨረሻ ዝማኔ',
  'chart': 'ቻርት',
  'time_period': 'የጊዜ ወቅት',
  'day': 'ቀን',
  'week': 'ሳምንት',
  'month': 'ወር',
  'year': 'ዓመት',
  'all': 'ሁሉም',
  'price': 'ዋጋ',
  'bid': 'ጨረታ',
  'ask': 'ጠይቅ',
  'spread': 'ስፕሬድ',
  'sector': 'ዘርፍ',
  'industry': 'ኢንዱስትሪ',
  'exchange': 'ምንዛሪ',
  'currency': 'ምንዛሪ',
  'timezone': 'የሰዓት ሰቅ',
  'ipo_date': 'አይፒኦ ቀን',
  'fiscal_year_end': 'የበጀት ዓመት መጨረሻ',
  'market_hours': 'የገበያ ሰዓታት',
  'trading_hours': 'የንግድ ሰዓታት',
  'regular_hours': 'መደበኛ ሰዓታት',
  'extended_hours': 'የተራዘመ ሰዓታት',
  'search_markets': 'ገበያዎችን ፈልግ',
  'gainers': 'አትራፊዎች',
  'losers': 'ኪሳራ ያደረሱ',
  'most_active': 'ብዙ እንቅስቃሴ ያላቸው',
  'tradable_assets': 'ለንግድ የሚቀርቡ ንብረቶች',
  'view_all': 'ሁሉንም ይመልከቱ',
  'ethiopian_market': 'የኢትዮጵያ ገበያ',
  'international_market': 'ዓለም አቀፍ ገበያ',
  'ethiopian_market_index': 'የኢትዮጵያ ገበያ ኢንዴክስ',
  'international_market_index': 'ዓለም አቀፍ ገበያ ኢንዴክስ',
  'ethiopian_news': 'የኢትዮጵያ ዜናዎች',
  'markets': 'ገበያዎች',
  'no_search_results': 'ምንም የፍለጋ ውጤቶች አልተገኙም',
  'no_assets_available': 'ምንም ንብረቶች አልተገኙም',
  'no_news_available': 'ምንም ዜናዎች አልተገኙም',

  // Portfolio
  'portfolio_value': 'የፖርትፎሊዮ ዋጋ',
  'cash_balance': 'የጥሬ ገንዘብ ሚዛን',
  'total_value': 'ጠቅላላ ዋጋ',
  'total_gain': 'ጠቅላላ ትርፍ',
  'total_gain_percent': 'ጠቅላላ የትርፍ መቶኛ',
  'day_gain': 'የቀን ትርፍ',
  'day_gain_percent': 'የቀን የትርፍ መቶኛ',
  'holdings': 'ንብረቶች',
  'transactions': 'ግብይቶች',
  'history': 'ታሪክ',
  'performance': 'አፈጻጸም',
  'allocation': 'ድልድል',
  'diversification': 'ብዝሃነት',
  'risk': 'ስጋት',
  'return': 'ተመላሽ',
  'income': 'ገቢ',
  'expense': 'ወጪ',
  'tax': 'ግብር',
  'fee': 'ክፍያ',
  'interest': 'ወለድ',
  'deposit': 'ተቀማጭ',
  'withdrawal': 'ማውጫ',
  'transfer': 'ማስተላለፊያ',
  'quantity': 'ብዛት',
  'shares': 'አክሲዮኖች',
  'lots': 'ሎቶች',
  'units': 'ክፍሎች',
  'cost_basis': 'የወጪ መሰረት',
  'avg_cost': 'አማካይ ወጪ',
  'current_value': 'የአሁን ዋጋ',
  'gain_loss': 'ትርፍ/ኪሳራ',
  'gain_loss_percent': 'የትርፍ/ኪሳራ መቶኛ',
  'realized': 'የተገነዘበ',
  'unrealized': 'ያልተገነዘበ',
  'short_term': 'አጭር ጊዜ',
  'long_term': 'ረጅም ጊዜ',
  'date_acquired': 'የተገኘበት ቀን',
  'date_sold': 'የተሸጠበት ቀን',
  'holding_period': 'የመያዣ ጊዜ',
  'cost_per_share': 'ወጪ በአክሲዮን',
  'proceeds': 'ገቢዎች',
  'proceeds_per_share': 'ገቢዎች በአክሲዮን',

  // Trading
  'trade': 'ንግድ',
  'order': 'ትዕዛዝ',
  'order_type': 'የትዕዛዝ ዓይነት',
  'market_order': 'የገበያ ትዕዛዝ',
  'limit_order': 'የገደብ ትዕዛዝ',
  'stop_order': 'የማቆሚያ ትዕዛዝ',
  'stop_limit_order': 'የማቆሚያ ገደብ ትዕዛዝ',
  'trailing_stop_order': 'የተከታታይ ማቆሚያ ትዕዛዝ',
  'time_in_force': 'ጊዜ በኃይል',
  'gtc': 'እስከሚሰረዝ',
  'ioc': 'ወዲያውኑ ወይም ይሰረዝ',
  'fok': 'ሙሉ ወይም ይሰረዝ',
  'side': 'ጎን',
  'short': 'አጭር',
  'cover': 'ሸፍን',
  'stop_price': 'የማቆሚያ ዋጋ',
  'limit_price': 'የገደብ ዋጋ',
  'trailing_amount': 'የተከታታይ መጠን',
  'trailing_percent': 'የተከታታይ መቶኛ',
  'estimated_cost': 'የተገመተ ወጪ',
  'estimated_proceeds': 'የተገመተ ገቢ',
  'estimated_commission': 'የተገመተ ኮሚሽን',
  'estimated_total': 'የተገመተ ጠቅላላ',
  'available_funds': 'ያሉ ገንዘቦች',
  'available_shares': 'ያሉ አክሲዮኖች',
  'buying_power': 'የመግዛት ኃይል',
  'margin_requirement': 'የማርጂን መስፈርት',
  'margin_impact': 'የማርጂን ተጽዕኖ',
  'order_status': 'የትዕዛዝ ሁኔታ',
  'filled': 'ተሞልቷል',
  'partially_filled': 'በከፊል ተሞልቷል',
  'cancelled': 'ተሰርዟል',
  'rejected': 'ተቀባይነት አላገኘም',
  'pending': 'በመጠበቅ ላይ',
  'expired': 'ጊዜው አልፏል',
  'order_date': 'የትዕዛዝ ቀን',
  'execution_date': 'የማስፈጸሚያ ቀን',
  'order_id': 'የትዕዛዝ መታወቂያ',
  'execution_id': 'የማስፈጸሚያ መታወቂያ',
  'order_details': 'የትዕዛዝ ዝርዝሮች',
  'execution_details': 'የማስፈጸሚያ ዝርዝሮች',
  'order_history': 'የትዕዛዝ ታሪክ',
  'execution_history': 'የማስፈጸሚያ ታሪክ',
  'order_confirmation': 'የትዕዛዝ ማረጋገጫ',
  'execution_confirmation': 'የማስፈጸሚያ ማረጋገጫ',
  'order_cancelled': 'ትዕዛዝ ተሰርዟል',
  'order_rejected': 'ትዕዛዝ ተቀባይነት አላገኘም',
  'order_expired': 'ትዕዛዝ ጊዜው አልፏል',
  'order_filled': 'ትዕዛዝ ተሞልቷል',
  'order_partially_filled': 'ትዕዛዝ በከፊል ተሞልቷል',
  'order_pending': 'ትዕዛዝ በመጠበቅ ላይ',
  'order_open': 'ትዕዛዝ ክፍት',
  'preview_order': 'ትዕዛዝ ቅድመ እይታ',
  'place_order': 'ትዕዛዝ አስቀምጥ',
  'modify_order': 'ትዕዛዝ ቀይር',
  'cancel_order': 'ትዕዛዝ ሰርዝ',
  'confirm_order': 'ትዕዛዝ አረጋግጥ',
  'confirm_cancellation': 'መሰረዝ አረጋግጥ',
  'confirm_modification': 'ማሻሻያ አረጋግጥ',

  // News
  'breaking_news': 'አስቸኳይ ዜና',
  'top_stories': 'ዋና ዋና ዜናዎች',
  'latest_news': 'የቅርብ ጊዜ ዜናዎች',
  'market_news': 'የገበያ ዜናዎች',
  'company_news': 'የኩባንያ ዜናዎች',
  'economy_news': 'የኢኮኖሚ ዜናዎች',
  'finance_news': 'የፋይናንስ ዜናዎች',
  'business_news': 'የንግድ ዜናዎች',
  'technology_news': 'የቴክኖሎጂ ዜናዎች',
  'politics_news': 'የፖለቲካ ዜናዎች',
  'world_news': 'የዓለም ዜናዎች',
  'local_news': 'የአካባቢ ዜናዎች',
  'read_more': 'ተጨማሪ ያንብቡ',
  'source': 'ምንጭ',
  'published': 'የታተመው',
  'author': 'ደራሲ',
  'category': 'ምድብ',
  'tags': 'መለያዎች',
  'related': 'ተዛማጅ',
  'trending': 'ተወዳጅ',
  'popular': 'ታዋቂ',
  'recommended': 'የሚመከር',
  'featured': 'የተመረጠ',
  'sponsored': 'የተደገፈ',
  'advertisement': 'ማስታወቂያ',
  'no_news': 'ምንም ዜና የለም',
  'load_more': 'ተጨማሪ ጫን',
  'filter': 'አጣራ',
  'sort': 'ደርድር',
  'date': 'ቀን',
  'relevance': 'አግባብነት',
  'popularity': 'ታዋቂነት',
  'ascending': 'ከታች ወደ ላይ',
  'descending': 'ከላይ ወደ ታች',
  'search_news': 'ዜና ፈልግ',
  'search_results': 'የፍለጋ ውጤቶች',
  'no_results': 'ምንም ውጤቶች የሉም',
  'clear': 'አጽዳ',
  'apply': 'ተግብር',
  'reset': 'ዳግም አስጀምር',
  'done': 'ተጠናቅቋል',
  'back': 'ተመለስ',
  'next': 'ቀጣይ',
  'previous': 'ቀዳሚ',
  'first': 'መጀመሪያ',
  'last': 'መጨረሻ',
  'page': 'ገጽ',
  'of': 'ከ',
  'items': 'ንጥሎች',
  'showing': 'በማሳየት ላይ',
  'to': 'ወደ',
  'total': 'ጠቅላላ',
  'per_page': 'በገጽ',
  'go_to_page': 'ወደ ገጽ ሂድ',
  'go': 'ሂድ',

  // Buy/Sell specific
  'buy_action': 'ግዛ',
  'sell_action': 'ሽጥ',

  // Trading related terms
  'trade_asset': 'ንብረት መለዋወጥ',
  'current_price': 'የአሁኑ ዋጋ',
  'trade_type': 'የንግድ አይነት',
  'buy': 'ግዛ',
  'sell': 'ሽጥ',
  'buy_success': 'ግዢው ተሳክቷል',
  'sell_success': 'ሽያጩ ተሳክቷል',

  // Notification related terms
  'no_notifications': 'ማሳወቂያዎች የሉም',
  'clear_all': 'ሁሉንም አጽዳ',
  'mark_all_read': 'ሁሉንም እንደተነበበ ምልክት አድርግ',
  'order_executed': 'ትዕዛዝ ተፈጽሟል',
  'market_alert': 'የገበያ ማሳወቂያ',
  'price_alert': 'የዋጋ ማሳወቂያ',
  'system_notification': 'የሲስተም ማሳወቂያ',
  'view_order_details': 'የትዕዛዝ ዝርዝሮችን ይመልከቱ',

  // User action confirmations
  'saved_to_favorites': 'ወደ ተወዳጆች ተመዝግቧል',
  'removed_from_favorites': 'ከተወዳጆች ተወግዷል',
};
