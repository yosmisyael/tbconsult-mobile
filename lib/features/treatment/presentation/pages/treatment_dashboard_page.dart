import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/treatement_progress_card.dart';
import '../widgets/next_dose_card.dart';

class TreatmentDashboardPage extends StatelessWidget {
  const TreatmentDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: AppColors.primary),
          onPressed: () {},
        ),
        title: const Text(
          'TBConsult',
          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: AppColors.primaryLight,
              child: const Icon(Icons.person, color: AppColors.primary),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Greeting Section
            const Text(
              'Good Morning,\nSarah.',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, height: 1.2),
            ),
            const SizedBox(height: 12),
            // Streak Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.accentYellow,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.local_fire_department, color: Colors.orange, size: 18),
                  SizedBox(width: 8),
                  Text(
                    '14-Day Streak',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Progress Card
            const TreatmentProgressCard(progress: 0.65),

            const SizedBox(height: 24),

            // Next Dose Card
            const NextDoseCard(),
          ],
        ),
      ),
    );
  }
}