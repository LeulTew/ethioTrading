import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options_web.dart' if (dart.library.io) 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/market_screen.dart';
import 'screens/portfolio_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/language_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  // Set default language to English if not set
  if (!prefs.containsKey('language')) {
    await prefs.setString('language', 'en');
  }

  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: FirebaseOptionsWeb.firebaseConfig['apiKey']!,
      authDomain: FirebaseOptionsWeb.firebaseConfig['authDomain']!,
      projectId: FirebaseOptionsWeb.firebaseConfig['projectId']!,
      storageBucket: FirebaseOptionsWeb.firebaseConfig['storageBucket']!,
      messagingSenderId:
          FirebaseOptionsWeb.firebaseConfig['messagingSenderId']!,
      appId: FirebaseOptionsWeb.firebaseConfig['appId']!,
      measurementId: FirebaseOptionsWeb.firebaseConfig['measurementId']!,
    ),
  );

  // Initialize Analytics
  final analytics = FirebaseAnalytics.instance;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider(prefs)),
      ],
      child: MyApp(analytics: analytics),
    ),
  );
}

class MyApp extends StatefulWidget {
  final FirebaseAnalytics analytics;

  const MyApp({super.key, required this.analytics});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void _toggleTheme(ThemeMode themeMode) {
    setState(() {
      _themeMode = themeMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ethiopian Trading App',
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: _themeMode,
      navigatorObservers: [
        FirebaseAnalyticsObserver(analytics: widget.analytics),
      ],
      home: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return authProvider.isAuthenticated
              ? MainScreen(onThemeChanged: _toggleTheme)
              : const LoginScreen();
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  final ValueChanged<ThemeMode> onThemeChanged;

  const MainScreen({super.key, required this.onThemeChanged});

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      body: _buildScreen(),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: languageProvider.translate('home'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.trending_up),
            label: languageProvider.translate('market'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.account_balance_wallet),
            label: languageProvider.translate('portfolio'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: languageProvider.translate('profile'),
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  Widget _buildScreen() {
    switch (_selectedIndex) {
      case 0:
        return const HomeScreen();
      case 1:
        return const MarketScreen();
      case 2:
        return const PortfolioScreen();
      case 3:
        return ProfileScreen(onThemeChanged: widget.onThemeChanged);
      default:
        return const HomeScreen();
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}
