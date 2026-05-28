import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:TBConsult/core/usecases/usecase.dart';
import 'package:TBConsult/features/medication/domain/usecases/medication_usecases.dart';
import 'package:TBConsult/features/treatment/domain/entities/dashboard_entity.dart';
import 'package:TBConsult/features/treatment/domain/usecases/load_dashboard_usecase.dart';
import 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final LoadDashboardUseCase loadDashboardUseCase;
  final CreateMedicationLogUseCase createLogUseCase;
  final SharedPreferences prefs;

  DashboardCubit({
    required this.loadDashboardUseCase,
    required this.createLogUseCase,
    required this.prefs,
  }) : super(const DashboardInitial());

  // ── Load ──────────────────────────────────────────────────────────────────

  Future<void> load() async {
    emit(const DashboardLoading());
    try {
      final vm = await loadDashboardUseCase(const NoParams());

      // Inject stored user name (written by AuthCubit on login success).
      final userName = prefs.getString('user_display_name') ?? 'Pengguna';
      final withName = DashboardViewModel(
        userName: userName,
        currentStreak: vm.currentStreak,
        journeyItems: vm.journeyItems,
      );

      emit(DashboardLoaded(viewModel: withName));
    } catch (e) {
      emit(DashboardError(message: e.toString()));
    }
  }

  // ── Quick-log all active doses for a journey ──────────────────────────────

  Future<void> logAllDosesNow({
    required JourneyDashboardItem item,
  }) async {
    final current = state;
    if (current is! DashboardLoaded) return;

    emit(DashboardLogSubmitting(viewModel: current.viewModel));
    try {
      final entries = item.activeDoses
          .map((d) => {'prescribed_dose_id': d.id, 'taken': true})
          .toList();

      await createLogUseCase(CreateLogParams(
        journeyId: item.journey.id,
        timeTaken: DateTime.now(),
        entries: entries,
      ));

      // Refresh the whole dashboard so the card disappears.
      await load();
    } catch (e) {
      // Restore previous state and show error via listener.
      emit(current);
      emit(DashboardError(message: e.toString()));
    }
  }

  void refresh() => load();
}
