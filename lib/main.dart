import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'utils/web_utils.dart';
import 'dart:async';

import 'screens/home_screen.dart';
import 'screens/market_screen.dart';
import 'screens/portfolio_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/language_provider.dart';
import 'providers/market_provider.dart';
import 'providers/news_provider.dart';
import 'providers/trading_provider.dart';
import 'providers/portfolio_provider.dart';
import 'models/asset.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (shouldInitializeApp()) {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('language')) {
      await prefs.setString('language', 'en');
    }

    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize Analytics
    final analytics = FirebaseAnalytics.instance;

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => LanguageProvider(prefs)),
          ChangeNotifierProvider(create: (_) => MarketProvider()),
          ChangeNotifierProvider(create: (_) => NewsProvider()),
          ChangeNotifierProvider(create: (_) => TradingProvider()),
          ChangeNotifierProvider(create: (_) => PortfolioProvider()),
        ],
        child: MyApp(analytics: analytics),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  final FirebaseAnalytics analytics;

  const MyApp({super.key, required this.analytics});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;
  Timer? _portfolioUpdateTimer;

  @override
  void initState() {
    super.initState();
    // Initialize providers
    _initializeProviders();
  }

  @override
  void dispose() {
    _portfolioUpdateTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeProviders() async {
    await Future.delayed(Duration.zero);
    if (!mounted) return;

    final marketProvider = Provider.of<MarketProvider>(context, listen: false);
    await marketProvider.initialize();
    if (!mounted) return;

    Provider.of<NewsProvider>(context, listen: false).initializeNews();

    // Initialize portfolio with market assets
    final portfolioProvider =
        Provider.of<PortfolioProvider>(context, listen: false);
    final assets = marketProvider.assets.fold<Map<String, Asset>>(
        {}, (map, asset) => map..[asset.symbol] = asset);

    await portfolioProvider.fetchPortfolio(marketAssets: assets);
    if (!mounted) return;

    // Setup periodic updates for portfolio based on market data
    _portfolioUpdateTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      // Always check if widget is still mounted before accessing BuildContext
      if (!mounted) return;

      // Store providers in local variables to reduce BuildContext access
      final marketProv = Provider.of<MarketProvider>(context, listen: false);
      final portfolioProv =
          Provider.of<PortfolioProvider>(context, listen: false);

      final updatedAssets = marketProv.assets.fold<Map<String, Asset>>(
          {}, (map, asset) => map..[asset.symbol] = asset);

      portfolioProv.updateWithMarketData(updatedAssets);
    });
  }

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
      routes: {
        '/': (context) => Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                return authProvider.isAuthenticated
                    ? MainScreen(onThemeChanged: _toggleTheme)
                    : const LoginScreen();
              },
            ),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
      },
      initialRoute: '/',
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
