import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/market_screen.dart';
import 'screens/portfolio_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/news_screen.dart';
import 'theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/language_provider.dart';
import 'providers/market_provider.dart';
import 'providers/portfolio_provider.dart';
import 'providers/news_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/trade_provider.dart';
import 'services/api_service.dart';
// Import platform-specific utilities with prefixes to avoid conflicts
import 'utils/web_utils.dart';
import 'utils/io_utils.dart' as io_utils;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize platform-specific functionality
  if (WebUtils.shouldInitializeApp()) {
    WebUtils.initPlatformSpecific();
    // Configure Google Fonts for web
    GoogleFonts.config.allowRuntimeFetching = true;
  } else {
    io_utils.initPlatformIO();
  }

  // Initialize Firebase with cross-browser support
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // Create services
  final firebaseDatabase = FirebaseDatabase.instance;
  final firebaseAuth = FirebaseAuth.instance;
  final apiService = ApiService(
    database: firebaseDatabase,
    auth: firebaseAuth,
  );

  // Create ThemeProvider instance to pass to both providers and MaterialApp
  final themeProvider = ThemeProvider();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        ChangeNotifierProvider(create: (_) => LanguageProvider(prefs)),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(
          create: (_) => MarketProvider(
            apiService: apiService,
            database: firebaseDatabase,
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => PortfolioProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => NewsProvider(apiService: apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => NotificationProvider(
            database: firebaseDatabase,
          ),
        ),
        ChangeNotifierProxyProvider<NotificationProvider, TradeProvider>(
          create: (_) => TradeProvider(),
          update: (_, notificationProvider, previousTradeProvider) =>
              TradeProvider(
            notificationProvider: notificationProvider,
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);

    return MaterialApp(
      title: languageProvider.translate('app_title'),
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      debugShowCheckedModeBanner: false,

      // Define routes
      initialRoute: '/login',
      routes: {
        '/home': (context) => const HomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/market': (context) => const MarketScreen(),
        '/portfolio': (context) => const PortfolioScreen(),
        '/profile': (context) => ProfileScreen(
              onThemeChanged: themeProvider.setThemeMode,
            ),
        '/news': (context) => const NewsScreen(), // Add the news screen route
      },
      // Fallback for unknown routes
      onUnknownRoute: (settings) => MaterialPageRoute(
        builder: (context) => const HomeScreen(),
      ),
    );
  }
}
