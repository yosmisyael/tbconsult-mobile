import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:TBConsult/core/theme/app_colors.dart';
import 'package:TBConsult/features/journey/domain/entities/journey_entity.dart';
import 'package:TBConsult/features/journey/presentation/cubit/journey_cubit.dart';
import 'package:TBConsult/features/medication/presentation/pages/log_medication_page.dart';
import 'package:TBConsult/features/treatment/domain/entities/dashboard_entity.dart';
import 'package:TBConsult/features/treatment/presentation/cubit/dashboard_cubit.dart';

/// Shows either:
/// • A pending-dose card per unlogged journey (scrollable if >1)
/// • An all-done celebration card when every journey is logged today
class NextDoseSection extends StatelessWidget {
  final List<JourneyDashboardItem> pendingItems;
  final bool isSubmitting;

  const NextDoseSection({
    super.key,
    required this.pendingItems,
    required this.isSubmitting,
  });

  @override
  Widget build(BuildContext context) {
    if (pendingItems.isEmpty) return const _AllDoneCard();

    return Column(
      children: pendingItems
          .map((item) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: _DoseReminderCard(
          item: item,
          isSubmitting: isSubmitting,
        ),
      ))
          .toList(),
    );
  }
}

// ── Single pending-dose card ──────────────────────────────────────────────────

class _DoseReminderCard extends StatelessWidget {
  final JourneyDashboardItem item;
  final bool isSubmitting;

  const _DoseReminderCard({
    required this.item,
    required this.isSubmitting,
  });

  @override
  Widget build(BuildContext context) {
    final doses = item.activeDoses;
    final doseNames =
    doses.map((d) => d.medicationName).toSet().join(' & ');
    final instructions = doses
        .where((d) => d.instructions != null)
        .map((d) => d.instructions!)
        .toSet()
        .join(', ');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // ── Decorative blob ────────────────────────────────────
            Positioned(
              right: -30,
              top: -30,
              child: CircleAvatar(
                radius: 80,
                backgroundColor: AppColors.primaryLight.withOpacity(0.15),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header: journey name ───────────────────────
                  Text(
                    item.journey.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ── Next dose label ────────────────────────────
                  Row(
                    children: const [
                      Icon(Icons.access_time,
                          size: 16, color: AppColors.textSecondary),
                      SizedBox(width: 8),
                      Text(
                        'Dosis Hari Ini',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // ── Dose time ──────────────────────────────────
                  Text(
                    _formatTime(DateTime.now()),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── Medication names ───────────────────────────
                  Text(
                    doseNames.isNotEmpty ? doseNames : 'Obat Aktif',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),

                  // ── Dose detail chips ──────────────────────────
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: doses.map((d) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${d.dosageMg.toInt()} mg · ${d.pillCount} tab',
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500),
                        ),
                      );
                    }).toList(),
                  ),

                  // ── Instruction ────────────────────────────────
                  if (instructions.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.accentYellow,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            instructions,
                            style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 20),

                  // ── CTA buttons ────────────────────────────────
                  Row(
                    children: [
                      // Quick-log all doses
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isSubmitting
                              ? null
                              : () => context
                              .read<DashboardCubit>()
                              .logAllDosesNow(item: item),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            disabledBackgroundColor:
                            AppColors.primary.withOpacity(0.6),
                            padding:
                            const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30)),
                            elevation: 0,
                          ),
                          child: isSubmitting
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : const Text(
                            'Log Dose Now',
                            style: TextStyle(
                                fontSize: 15,
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Detail log (full LogMedicationPage)
                      _OutlineIconButton(
                        icon: Icons.edit_outlined,
                        tooltip: 'Catat detail',
                        onTap: () => _openDetailLog(context, item.journey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openDetailLog(BuildContext context, Journey journey) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => context.read<JourneyCubit>(),
          child: LogMedicationPage(journey: journey),
        ),
      ),
    ).then((_) => context.read<DashboardCubit>().refresh());
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour < 12 ? 'AM' : 'PM';
    final h12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    return '${h12.toString().padLeft(2, '0')}:$minute $period';
  }
}

class _OutlineIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _OutlineIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.primary, width: 1.5),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
      ),
    );
  }
}

// ── All-done celebration card ─────────────────────────────────────────────────

class _AllDoneCard extends StatelessWidget {
  const _AllDoneCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primaryLight,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Emoji + animated scale
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.5, end: 1.0),
            duration: const Duration(milliseconds: 500),
            curve: Curves.elasticOut,
            builder: (_, v, child) =>
                Transform.scale(scale: v, child: child),
            child: const Text('🎉', style: TextStyle(fontSize: 48)),
          ),
          const SizedBox(height: 12),
          const Text(
            'Semua obat hari ini sudah dicatat!',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Pertahankan konsistensimu. Kamu luar biasa 💪',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.85),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
