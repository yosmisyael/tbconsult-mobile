import 'package:flutter/material.dart';
import 'package:tbcare/core/theme/app_colors.dart';
import 'package:tbcare/features/journey/domain/entities/achievement_entity.dart';

class AchievementCard extends StatelessWidget {
  final AchievementEntity achievement;

  const AchievementCard({super.key, required this.achievement});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: Opacity(
        opacity: achievement.isLocked ? 0.4 : 1.0,
        child: Column(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: achievement.isLocked ? Colors.grey[200] : AppColors.accentYellow,
              child: Icon(
                achievement.isLocked ? Icons.lock : Icons.star,
                color: achievement.isLocked ? Colors.grey : AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(achievement.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(achievement.description, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}