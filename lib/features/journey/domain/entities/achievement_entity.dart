class AchievementEntity {
  final String title;
  final String description;
  final bool isLocked;
  final String iconType;

  AchievementEntity({
    required this.title,
    required this.description,
    this.isLocked = true,
    required this.iconType,
  });
}