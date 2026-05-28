import 'package:equatable/equatable.dart';

import 'package:TBConsult/features/treatment/domain/entities/dashboard_entity.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

class DashboardLoaded extends DashboardState {
  final DashboardViewModel viewModel;

  const DashboardLoaded({required this.viewModel});

  @override
  List<Object?> get props => [viewModel];
}

/// Emitted after the user taps "Log Dose Now" and the log is submitted.
/// We refresh the dashboard automatically after this.
class DashboardLogSubmitting extends DashboardState {
  final DashboardViewModel viewModel; // keep showing existing data
  const DashboardLogSubmitting({required this.viewModel});

  @override
  List<Object?> get props => [viewModel];
}

class DashboardError extends DashboardState {
  final String message;
  const DashboardError({required this.message});

  @override
  List<Object?> get props => [message];
}
