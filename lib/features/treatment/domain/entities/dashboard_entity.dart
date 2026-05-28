import 'package:equatable/equatable.dart';

import 'package:TBConsult/features/journey/domain/entities/journey_entity.dart';

/// One journey's full dashboard snapshot:
/// the journey detail (name, prescribed doses) + its stats
/// + whether today's log has already been submitted.
class JourneyDashboardItem extends Equatable {
  final Journey journey;
  final JourneyStats stats;

  /// True when [stats.lastLogDate] is today (local time).
  final bool loggedToday;

  const JourneyDashboardItem({
    required this.journey,
    required this.stats,
    required this.loggedToday,
  });

  /// Active prescribed doses — the ones to show in the reminder card.
  List<PrescribedDose> get activeDoses =>
      journey.prescribedDoses.where((d) => d.isActive).toList();

  /// Progress as 0.0–1.0 derived from adherence_percent.
  double get progressFraction => (stats.adherencePercent.clamp(0, 100) / 100);

  /// Phase label: simple derivation from journey name or days elapsed.
  String get phaseLabel {
    final days = stats.daysElapsed;
    if (days <= 60) return 'Fase Intensif';
    return 'Fase Lanjutan';
  }

  @override
  List<Object?> get props => [journey, stats, loggedToday];
}

/// Top-level view model for the whole dashboard screen.
class DashboardViewModel extends Equatable {
  final String userName;
  final int currentStreak;
  final List<JourneyDashboardItem> journeyItems;

  const DashboardViewModel({
    required this.userName,
    required this.currentStreak,
    required this.journeyItems,
  });

  /// Active journeys that still need a log today.
  List<JourneyDashboardItem> get pendingToday =>
      journeyItems.where((j) => !j.loggedToday).toList();

  /// Best streak across all active journeys.
  static int _bestStreak(List<JourneyDashboardItem> items) => items.isEmpty
      ? 0
      : items.map((j) => j.stats.currentStreak).reduce((a, b) => a > b ? a : b);

  factory DashboardViewModel.fromParts({
    required String userName,
    required List<JourneyDashboardItem> items,
  }) => DashboardViewModel(
    userName: userName,
    currentStreak: _bestStreak(items),
    journeyItems: items,
  );

  @override
  List<Object?> get props => [userName, currentStreak, journeyItems];
}
