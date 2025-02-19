import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'screens/market_screen.dart';
import 'screens/portfolio_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';
import 'providers/auth_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

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
      title: 'Ethio Trading App',
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: _themeMode,
      home: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          if (authProvider.isAuthenticated) {
            return MainScreen(onThemeChanged: _toggleTheme);
          }
          return const LoginScreen();
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

  List<Widget> get _screens => [
        const HomeScreen(),
        const MarketScreen(),
        const PortfolioScreen(),
        ProfileScreen(onThemeChanged: widget.onThemeChanged)
      ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'መነሻ', // Home in Amharic
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up),
            label: 'ገበያ', // Market in Amharic
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'ፖርትፎሊዮ', // Portfolio in Amharic
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'መገለጫ', // Profile in Amharic
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
