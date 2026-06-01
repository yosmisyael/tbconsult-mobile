import 'dart:async';
import 'package:TBConsult/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:TBConsult/features/auth/presentation/cubit/auth_state.dart';
import 'package:TBConsult/features/auth/presentation/pages/login_page.dart';
import 'package:TBConsult/features/journey/presentation/cubit/journey_cubit.dart';
import 'package:TBConsult/features/maps/presentation/cubit/map_cubit.dart';
import 'package:TBConsult/features/treatment/presentation/cubit/dashboard_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:TBConsult/core/di/injection_container.dart';
import 'package:TBConsult/features/journey/presentation/pages/journey_page.dart';
import 'package:TBConsult/features/maps/presentation/pages/map_page.dart';
import 'core/theme/app_colors.dart';
import 'core/widgets/custom_toast.dart';
import 'features/treatment/presentation/pages/treatment_dashboard_page.dart';
import 'features/health_hub/presentation/pages/tbconsult_hub_page.dart';
import 'features/health_hub/presentation/cubit/health_hub_cubit.dart';
import 'features/literacy/presentation/pages/resource_library_page.dart';
import 'package:TBConsult/core/network/dio_client.dart';
import 'package:url_launcher/url_launcher.dart';

class OuterShell extends StatefulWidget {
  final int initialIndex;
  final String? facilityId;
  
  static final GlobalKey<OuterShellState> navKey = GlobalKey<OuterShellState>();

  OuterShell({int? initialIndex, this.facilityId, Key? key})
      : initialIndex = initialIndex ?? 0,
        super(key: key ?? navKey);

  @override
  State<OuterShell> createState() => OuterShellState();
}

class OuterShellState extends State<OuterShell> {
  late int _selectedIndex;
  final List<int> _navigationHistory = [];
  DateTime? _lastPressedBack;
  Timer? _sessionPingTimer;

  late final MapCubit _mapCubit = sl<MapCubit>();

  late final List<Widget> _pages = [
    BlocProvider<DashboardCubit>(
      create: (_) => sl<DashboardCubit>(),
      child: const TreatmentDashboardPage(),
    ),
    BlocProvider<HealthHubCubit>(
      create: (_) => sl<HealthHubCubit>()..loadRecentConversations(),
      child: const TBConsultHubPage(),
    ),
    BlocProvider<MapCubit>.value(
      value: _mapCubit,
      child: const MapPage(),
    ),
    BlocProvider<JourneyCubit>(
      create: (_) => sl<JourneyCubit>()..loadJourneys(),
      child: const JourneyPage(),
    ),
    const ResourceLibraryPage(),
  ];

  void setSelectedIndex(int index) {
    if (_selectedIndex != index) {
      _navigationHistory.add(_selectedIndex);
      setState(() => _selectedIndex = index);
    }
  }

  void navigateToMap({String? facilityId}) {
    setSelectedIndex(2);
    if (facilityId != null) {
      Future.delayed(const Duration(milliseconds: 150), () {
        _mapCubit.selectFacilityById(facilityId);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _checkSessionValidity();
    _startSessionPingTimer();

    if (widget.facilityId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigateToMap(facilityId: widget.facilityId);
      });
    }
  }

  @override
  void dispose() {
    _sessionPingTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkSessionValidity() async {
    try {
      final dio = sl<DioClient>().dio;
      await dio.get('/auth/me');
    } catch (_) {
      // The interceptor in DioClient handles 401 by calling logout()
      // which triggers the BlocListener to redirect to login.
    }
  }

  void _startSessionPingTimer() {
    // Send a session ping to the backend every 5 minutes to prevent token expiration
    _sessionPingTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      if (!mounted) return;
      final authState = context.read<AuthCubit>().state;
      if (authState is AuthAuthenticated || authState is AuthLoginSuccess) {
        debugPrint('OuterShell: Performing background session ping...');
        await sl<DioClient>().pingAndRefreshToken();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<AuthCubit>(),
                child: const LoginPage(),
              ),
            ),
            (_) => false,
          );
        }
      },
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;

          if (_navigationHistory.isNotEmpty) {
            final prevIndex = _navigationHistory.removeLast();
            setState(() {
              _selectedIndex = prevIndex;
            });
            return;
          }

          // Double back press exit logic
          final now = DateTime.now();
          if (_lastPressedBack == null ||
              now.difference(_lastPressedBack!) > const Duration(seconds: 2)) {
            _lastPressedBack = now;
            CustomToast.show(context, 'Tekan sekali lagi untuk keluar');
          } else {
            await SystemNavigator.pop();
          }
        },
        child: Scaffold(
          backgroundColor: const Color(0xFFF5F7F6),
          drawer: Drawer(
            child: ListView(
              children: [
                const DrawerHeader(
                  decoration: BoxDecoration(color: AppColors.primary),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('TBConsult',
                          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text('Sistem Pendampingan TB',
                          style: TextStyle(color: Colors.white70, fontSize: 14)),
                    ],
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline, color: AppColors.primary),
                  title: const Text('About'),
                  onTap: () {
                    Navigator.pop(context);
                    _showAboutDialog(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.attribution_outlined, color: AppColors.primary),
                  title: const Text('Credit'),
                  onTap: () {
                    Navigator.pop(context);
                    _showCreditDialog(context);
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Logout', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    context.read<AuthCubit>().logout();
                  },
                ),
              ],
            ),
          ),
          body: IndexedStack(
            index: _selectedIndex,
            children: _pages,
          ),
          bottomNavigationBar: NavigationBarTheme(
            data: NavigationBarThemeData(
              indicatorColor: AppColors.accentYellow,
              labelTextStyle: WidgetStateProperty.all(
                const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary),
              ),
            ),
            child: NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setSelectedIndex(index);
                _checkSessionValidity();
              },
              backgroundColor: const Color(0xFFF5F7F6),
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
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.primary),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Tentang TBConsult',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const Text(
          'TBConsult adalah aplikasi pendampingan pengobatan Tuberkulosis (TB) yang cerdas. '
          'Aplikasi ini dirancang untuk membantu pasien melacak jadwal minum obat, '
          'menemukan faskes terdekat, serta berkonsultasi secara mandiri dengan asisten triage medis berbasis AI.',
          textAlign: TextAlign.justify,
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showCreditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.attribution_outlined, color: AppColors.primary),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Credit',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pengembang',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 16),
            ),
            const SizedBox(height: 12),
            _buildContributorRow(context, 'Misyael', 'https://github.com/yosmisyael/'),
            const SizedBox(height: 12),
            _buildContributorRow(context, 'Fahroldhi', 'https://github.com/acalypha9'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildContributorRow(BuildContext context, String name, String githubUrl) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        OutlinedButton.icon(
          onPressed: () async {
            final url = Uri.parse(githubUrl);
            try {
              await launchUrl(
                url,
                mode: LaunchMode.externalApplication,
              );
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Gagal membuka link: $e')),
                );
              }
            }
          },
          icon: Image.asset(
            'assets/images/github_logo.png',
            width: 16,
            height: 16,
            color: AppColors.primary,
            colorBlendMode: BlendMode.srcIn,
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.code, size: 16, color: AppColors.primary),
          ),
          label: const Text(
            'GitHub',
            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.primary),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ],
    );
  }
}
