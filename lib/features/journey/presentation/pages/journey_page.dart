import 'package:flutter/material.dart';
import '../widgets/month_card.dart';
import '../widgets/achievement_card.dart';
import '../../domain/entities/achievement_entity.dart';

class JourneyPage extends StatelessWidget {
  const JourneyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Journey"), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Tracking your 6-month progress.", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),

            // Section 1: Treatment Calendar
            const Text("Treatment Calendar", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const MonthCard(monthTitle: "Month 1", takenDays: [1, 2, 3, 4, 5]),
            const MonthCard(monthTitle: "Month 2", takenDays: [1, 2]),

            const SizedBox(height: 32),

            // Section 2: Achievements
            const Text("Achievements", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                AchievementCard(achievement: AchievementEntity(title: "First Week", description: "7 Day Streak", isLocked: false, iconType: 'medal')),
                AchievementCard(achievement: AchievementEntity(title: "Perfect Month", description: "30 Day Streak", isLocked: false, iconType: 'star')),
                AchievementCard(achievement: AchievementEntity(title: "Quarter Way", description: "90 Day Streak", iconType: 'lock')),
                AchievementCard(achievement: AchievementEntity(title: "Halfway Hero", description: "Month 3", iconType: 'lock')),
              ],
            )
          ],
        ),
      ),
    );
  }
}