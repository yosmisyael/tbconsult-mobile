import 'package:flutter/material.dart';
import 'package:tbcare/features/journey/presentation/pages/journey_page.dart';
import 'package:tbcare/features/maps/presentation/pages/map_page.dart';
import 'core/theme/app_colors.dart';
import 'features/treatment/presentation/pages/treatment_dashboard_page.dart';

class OuterShell extends StatefulWidget {
  const OuterShell({super.key});

  @override
  State<OuterShell> createState() => _OuterShellState();
}

class _OuterShellState extends State<OuterShell> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const TreatmentDashboardPage(),
    const Center(child: Text('Health Screening')),
    const MapPage(),
    const JourneyPage(),
    const Center(child: Text('Library')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _pages[_selectedIndex]),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          indicatorColor: AppColors.accentYellow,
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) => setState(() => _selectedIndex = index),
          backgroundColor: Colors.white,
          elevation: 10,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_filled),
              label: 'HOME',
            ),
            NavigationDestination(
              icon: Icon(Icons.add_moderator),
              label: 'HEALTH',
            ),
            NavigationDestination(
              icon: Icon(Icons.map_outlined),
              label: 'MAP',
            ),
            NavigationDestination(
              icon: Icon(Icons.auto_graph_rounded),
              label: 'JOURNEY',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_book_rounded),
              label: 'LIBRARY',
            ),
          ],
        ),
      ),
    );
  }
}