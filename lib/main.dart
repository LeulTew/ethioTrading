import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
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
import 'theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/language_provider.dart';
import 'providers/market_provider.dart';
import 'providers/portfolio_provider.dart';
import 'providers/news_provider.dart';
import 'services/api_service.dart';

// Conditional import for web
import 'utils/web_utils.dart' if (dart.library.io) 'utils/io_utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Google Fonts
  GoogleFonts.config.allowRuntimeFetching = true;

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize web-specific functionality
  initPlatformSpecific();

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // Create services
  final apiService = ApiService();
  final firebaseDatabase = FirebaseDatabase.instance;

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
      },
      // Fallback for unknown routes
      onUnknownRoute: (settings) => MaterialPageRoute(
        builder: (context) => const HomeScreen(),
      ),
    );
  }
}
