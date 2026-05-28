import 'package:TBConsult/features/journey/presentation/cubit/journey_cubit.dart';
import 'package:TBConsult/features/maps/presentation/cubit/map_cubit.dart';
import 'package:TBConsult/features/treatment/presentation/cubit/dashboard_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:TBConsult/core/di/injection_container.dart';
import 'package:TBConsult/features/journey/presentation/pages/journey_page.dart';
import 'package:TBConsult/features/maps/presentation/pages/map_page.dart';
import 'core/theme/app_colors.dart';
import 'features/treatment/presentation/pages/treatment_dashboard_page.dart';
import 'features/health_hub/presentation/pages/tbconsult_hub_page.dart';
import 'features/health_hub/presentation/cubit/health_hub_cubit.dart';
import 'features/literacy/presentation/pages/resource_library_page.dart';

class OuterShell extends StatefulWidget {
  const OuterShell({super.key});

  @override
  State<OuterShell> createState() => _OuterShellState();
}

class _OuterShellState extends State<OuterShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _buildPage(_selectedIndex)),
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

  Widget _buildPage(int index) {
    switch (index) {
      case 1:
        return BlocProvider<HealthHubCubit>(
          create: (_) => sl<HealthHubCubit>()..loadRecentConversations(),
          child: const TBConsultHubPage(),
        );
      case 0:
        return BlocProvider<DashboardCubit>(
          create: (_) => sl<DashboardCubit>(),
          child: const TreatmentDashboardPage(),
        );
      case 2:
        return BlocProvider(
          create: (_) => sl<MapCubit>(),
          child: const MapPage(),
        );
      case 3:
        return BlocProvider<JourneyCubit>(
          create: (_) => sl<JourneyCubit>()..loadJourneys(),
          child: const JourneyPage(),
        );
      case 4:
        return const ResourceLibraryPage();
      default:
        return const TreatmentDashboardPage();
    }
  }
}
