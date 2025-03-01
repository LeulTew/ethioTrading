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

    // For display purposes, replace underscores with spaces
    // This ensures clean text in the UI while maintaining underscore keys in code
    return translatedText;
  }

  // Format display text by removing underscores and properly capitalizing
  String formatDisplayText(String text) {
    // Replace underscores with spaces for display
    return text.replaceAll('_', ' ');
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
};

const Map<String, String> amharicTranslations = {
  // Error Messages
  'error_occurred': 'ስህተት ተከስቷል',
  'try_again': 'እባክዎ እንደገና ይሞክሩ',
  'connection_error': 'የግንኙነት ስህተት',
  'validation_error': 'እባክዎ ግብዓትዎን ያረጋግጡ',
  'insufficient_funds': 'በቂ ሂሳብ የለም',
  'invalid_quantity': 'ልክ ያልሆነ መጠን',
  'invalid_price': 'ልክ ያልሆነ ዋጋ',

  // Trading Levels
  'trading_level': 'የንግድ ደረጃ',
  'beginner': 'ጀማሪ',
  'intermediate': 'መካከለኛ',
  'advanced': 'የላቀ',
  'current_level': 'የአሁኑ ደረጃ',
  'daily_limit': 'የዕለት የንግድ ገደብ',
  'available_balance': 'ያለው ሂሳብ',
  'upgrade_level': 'የንግድ ደረጃዎን ያሻሽሉ',
  'request_upgrade': 'ማሻሻያ ይጠይቁ',

  // Settings & Preferences
  'preferences': 'ምርጫዎች',
  'theme': 'ገጽታ',
  'light_mode': 'ብሩህ ሁነታ',
  'dark_mode': 'ጨለማ ሁነታ',
  'system_default': 'የስርዓት ነባሪ',

  // Market Data
  'market_index': 'የገበያ ማውጫ',
  'volume': 'መጠን',
  'change': 'ለውጥ',
  'market_cap': 'የገበያ ካፒታል',
  'price': 'ዋጋ',
  'open': 'መክፈቻ',
  'high': 'ከፍተኛ',
  'low': 'ዝቅተኛ',
  'close': 'መዝጊያ',

  // Additional Market Terms
  'gainers': 'አትራፊዎች',
  'losers': 'ኪሳራ የደረሰባቸው',
  'market_breadth': 'የገበያ ስፋት',
  'combined': 'የተዋሃደ',
  'bids': 'ጨማሪዎች',
  'asks': 'ሻጮች',
  'order_book': 'የትዕዛዝ መዝገብ',
  'technical_analysis': 'ቴክኒካዊ ትንተና',
  'market_order': 'የገበያ ትዕዛዝ',
  'limit_order': 'የገደብ ትዕዛዝ',
  'buy': 'ግዛ',
  'sell': 'ሽጥ',
  'commission': 'ኮሚሽን',
  'vat': 'ተጨማሪ እሴት ታክስ',
  'capital_gains_tax': 'የካፒታል ትርፍ ግብር',
  'order_executed_successfully': 'ትዕዛዝ በተሳካ ሁኔታ ተፈጽሟል',
  'order_execution_failed': 'ትዕዛዝ ማስፈጸም አልተሳካም',
  'overview': 'አጠቃላይ እይታ',
  'chart': 'ቻርት',
  'analysis': 'ትንተና',
  'news': 'ዜና',
  'loading_data': 'መረጃ በመጫን ላይ',
  'trade': 'ንግድ',
  'company_info': 'የኩባንያ መረጃ',
  'key_statistics': 'ቁልፍ ስታትስቲክስ',
  'technical_indicators': 'ቴክኒካዊ አመልካቾች',
  'app_title': 'የኢትዮጵያ የገበያ መተግበሪያ',
  'home': 'መነሻ',
  'market': 'ገበያ',
  'portfolio': 'ፖርትፎሊዮ',
  'profile': 'መገለጫ',
  'login': 'ግባ',
  'register': 'ተመዝገብ',
  'email': 'ኢሜይል',
  'password': 'የይለፍ ቃል',
  'forgot_password': 'የይለፍ ቃል ረስተዋል?',
  'new_user': 'አዲስ ተጠቃሚ? እዚህ ይመዝገቡ',
  'already_member': 'አባል ከሆኑ? ግባ',
  'please_enter_email': 'እባክዎ ኢሜይልዎን ያስገቡ',
  'enter_valid_email': 'እባክዎ ትክክለኛ ኢሜይል ያስገቡ',
  'please_enter_password': 'እባክዎ የይለፍ ቃልዎን ያስገቡ',
  'password_too_short': 'የይለፍ ቃል ቢያንስ 6 ፊደላት መሆን አለበት',
  'password_reset_sent': 'የይለፍ ቃል ዳግም ማስጀመሪያ መመሪያዎች ወደ ኢሜይልዎ ተልከዋል',
  'edit_profile': 'መገለጫ ያስተካክሉ',
  'save_changes': 'ለውጦችን አስቀምጥ',
  'cancel': 'ሰርዝ',
  'profile_updated': 'መገለጫው በተሳካ ሁኔታ ተዘምኗል',
  'update_error': 'መገለጫውን በማዘመን ላይ ስህተት ተከስቷል',
  'username': 'የተጠቃሚ ስም',
  'phone_number': 'ስልክ ቁጥር',
  'address': 'አድራሻ',
  'bank_account': 'የባንክ ሒሳብ ቁጥር',
  'verified_account': 'የተረጋገጠ መለያ',
  'verification_required': 'ማረጋገጫ ያስፈልጋል',
  'verify_now': 'አሁን ያረጋግጡ',
  'account_verified': 'መለያዎ ሙሉ በሙሉ ተረጋግጧል',
  'complete_verification': 'ሙሉ የንግድ ባህሪያትን ለመክፈት ማረጋገጫን ያጠናቅቁ',
  'upload_photo': 'ፎቶ ይስቀሉ',
  'security': 'ደህንነት',
  'change_password': 'የይለፍ ቃል ይቀይሩ',
  'two_factor': 'ሁለት ደረጃ ማረጋገጫ',
  'trusted_devices': 'የታመኑ መሣሪያዎች',
  'login_history': 'የመግቢያ ታሪክ',
  'security_notifications': 'የደህንነት ማሳወቂያዎች',
  'activity_log': 'የእንቅስቃሴ ምዝግብ ማስታወሻ',
  'market_overview': 'የገበያ አጠቃላይ እይታ',
  'top_movers': 'ከፍተኛ እንቅስቃሴ ያላቸው',
  'sector_performance': 'የዘርፍ አፈጻጸም',
  'search_stocks': 'አክሲዮኖችን ይፈልጉ',
  'all_sectors': 'ሁሉም ዘርፎች',
  'Bank': 'ባንክ',
  'Transport': 'ትራንስፖርት',
  'Telecom': 'ቴሌኮም',
  'Utility': 'አገልግሎት',
  'Agriculture': 'እርሻ',
  'Manufacturing': 'ማምረቻ',
  'order_type': 'የትእዛዝ አይነት',
  'quantity': 'ብዛት',
  'total': 'ጠቅላላ',
  'place_order': 'ትእዛዝ አስገባ',
  'confirm_order': 'ትእዛዝን አረጋግጥ',
  'order_success': 'ትእዛዝ በተሳካ ሁኔታ ተስተናግዷል',
  'order_error': 'ትእዛዙን በማስገባት ላይ ስህተት ተከስቷል',
  'notifications': 'ማሳወቂያዎች',
  'notification_settings': 'የማሳወቂያ ቅንብሮች',
  'price_alerts': 'የዋጋ ማሳወቂያዎች',
  'news_alerts': 'የዜና ማሳወቂያዎች',
  'trade_confirmations': 'የንግድ ማረጋገጫዎች',
  'market_status': 'የገበያ ሁኔታ',
  'market_open': 'ገበያ ክፍት',
  'market_closed': 'ገበያ ተዘግቷል',
  'next_opening': 'ቀጣይ መክፈቻ',
  'pre_market': 'ቅድመ-ገበያ',
  'after_hours': 'ከሰዓታት በኋላ',

  // Enhanced Login Screen
  'welcome_back': 'እንኳን በደህና መጡ',
  'login_subtitle': 'በኢትዮጵያ ዋና የንግድ መድረክ ለመገበያየት ይግቡ',
  'remember_me': 'አስታውሰኝ',
  'new_user_prompt': 'አካውንት የለዎትም?',
  'login_success': 'በተሳካ ሁኔታ ገብተዋል',
  'email_hint': 'ኢሜይል አድራሻዎን ያስገቡ',
  'password_hint': 'የይለፍ ቃል ያስገቡ',
  'invalid_credentials': 'ትክክል ያልሆነ ኢሜይል ወይም የይለፍ ቃል',
  'network_error': 'የኔትዎርክ ግንኙነት ስህተት',
  'server_error': 'የサーバー ስህተት ተከስቷል',
  'Summary': 'ማጠቃለያ',
};
