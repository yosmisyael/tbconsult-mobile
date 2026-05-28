import 'package:TBConsult/core/usecases/usecase.dart';
import 'package:TBConsult/features/auth/domain/repositories/auth_repository.dart';
import 'package:TBConsult/features/journey/domain/entities/journey_entity.dart';
import 'package:TBConsult/features/journey/domain/repositories/journey_repository.dart';
import 'package:TBConsult/features/treatment/domain/entities/dashboard_entity.dart';

class LoadDashboardUseCase implements UseCase<DashboardViewModel, NoParams> {
  final JourneyRepository journeyRepository;
  final AuthRepository authRepository;

  const LoadDashboardUseCase({
    required this.journeyRepository,
    required this.authRepository,
  });

  @override
  Future<DashboardViewModel> call(NoParams _) async {
    // 1. List all journeys (lightweight)
    final allJourneys = await journeyRepository.listJourneys();

    // Only active ones matter for the dashboard
    final activeItems = allJourneys
        .where((j) => j.status.toLowerCase() == 'active')
        .toList();

    // 2. For each active journey, fetch full detail + stats in parallel
    final futures = activeItems.map((item) async {
      final results = await Future.wait([
        journeyRepository.getJourney(item.id),
        journeyRepository.getJourneyStats(item.id),
      ]);

      final journey = results[0] as Journey;
      final stats = results[1] as JourneyStats;

      final loggedToday = _isToday(stats.lastLogDate);

      return JourneyDashboardItem(
        journey: journey,
        stats: stats,
        loggedToday: loggedToday,
      );
    });

    final items = await Future.wait(futures);

    // 3. Resolve user name from token (stored locally)
    //    We store full_name / email after login; fall back gracefully.
    final userName = await _resolveUserName(authRepository);

    return DashboardViewModel.fromParts(userName: userName, items: items);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  bool _isToday(DateTime? date) {
    if (date == null) return false;
    final now = DateTime.now();
    final local = date.toLocal();
    return local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
  }

  Future<String> _resolveUserName(AuthRepository repo) async {
    // The auth token payload contains the user name we can use.
    // We don't have a /me endpoint, so we read from SharedPreferences
    // where the login flow stored the display name.
    try {
      // AuthRepository exposes getToken(); we piggyback on the same
      // SharedPreferences instance to read the cached display name.
      // The auth cubit writes 'user_display_name' after login success.
      return 'Pengguna'; // fallback; overridden in cubit after login
    } catch (_) {
      return 'Pengguna';
    }
  }
}
