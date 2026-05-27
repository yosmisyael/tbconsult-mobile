import 'package:flutter/material.dart';
import 'package:TBConsult/features/journey/presentation/pages/adjust_journey_page.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/medication_plan_entity.dart';

class PlanCard extends StatelessWidget {
  final MedicationPlanEntity plan;

  const PlanCard({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    final isActive = plan.status == PlanStatus.active;
    final accentColor = isActive ? AppColors.primary : Colors.grey[400]!;
    final badgeBgColor = isActive ? AppColors.primaryLight : Colors.grey[200]!;
    final badgeTextColor = isActive ? AppColors.primary : Colors.grey[600]!;

    return GestureDetector(
      onTap: () {
        if (isActive) {
          Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AdjustJourneyPage())
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        clipBehavior: Clip.antiAlias, // Biar radius sudutnya rapi nutupin garis aksen
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Garis tebal di kiri
              Container(width: 8, color: accentColor),

              // Isi Card
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Badge Active/Completed
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: badgeBgColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isActive ? Icons.circle : Icons.check_circle_outline,
                                      size: 12,
                                      color: badgeTextColor,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      isActive ? 'Active' : 'Completed',
                                      style: TextStyle(
                                        color: badgeTextColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Tombol Arrow Kanan
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: Colors.grey[200],
                                child: const Icon(Icons.chevron_right, color: Colors.black54, size: 20),
                              )
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            plan.title,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text(plan.dateRange, style: const TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Bagian Bawah Khusus untuk "Active"
                    if (isActive && plan.trackStatus != null) ...[
                      Divider(height: 1, color: Colors.grey[200]),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'STATUS',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1),
                            ),
                            Text(
                              plan.trackStatus!,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ],
                        ),
                      )
                    ]
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}