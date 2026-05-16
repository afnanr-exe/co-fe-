import 'package:flutter/material.dart';

import 'screens/puzzle_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/word_of_the_day_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await NotificationService.init();
  } catch (_) {}
  runApp(const VocabApp());
}

class VocabApp extends StatelessWidget {
  const VocabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/home': (context) => const HomeShell(),
      },
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() =>
      _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;
  int _statsRefreshKey = 0;

  late PageController _pageController;

  @override
  void initState() {
    super.initState();

    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();

    super.dispose();
  }

  void _onNavTapped(int index) {
    setState(() {
      _currentIndex = index;
      if (index == 2) _statsRefreshKey++;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
      if (index == 2) _statsRefreshKey++;
    });
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const SettingsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFF0A0A0A),

      appBar: AppBar(
        backgroundColor:
            const Color(0xFF0A0A0A),
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: _openSettings,
            icon: const Icon(
              Icons.settings_outlined,
              color: Colors.grey,
            ),
          ),
        ],
      ),

      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: [
          const WordOfTheDayScreen(),
          const PuzzleScreen(),
          StatsScreen(key: ValueKey(_statsRefreshKey)),
        ],
      ),

      bottomNavigationBar:
          BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onNavTapped,
        backgroundColor:
            const Color(0xFF0A0A0A),
        selectedItemColor:
            Colors.white,
        unselectedItemColor:
            Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.lightbulb_outline,
            ),
            label: 'Word of the Day',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.extension),
            label: 'Daily Puzzle',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insights),
            label: 'Stats',
          ),
        ],
      ),
    );
  }
}