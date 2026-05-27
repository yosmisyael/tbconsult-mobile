import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'article_reader_page.dart';

// Article Model
class ArticleInfo {
  final String category;
  final String title;
  final String desc;
  final IconData icon;
  final Color bgColor;
  final Color iconColor;

  ArticleInfo({
    required this.category,
    required this.title,
    required this.desc,
    required this.icon,
    required this.bgColor,
    required this.iconColor,
  });
}

class ResourceLibraryPage extends StatefulWidget {
  const ResourceLibraryPage({super.key});

  @override
  State<ResourceLibraryPage> createState() => _ResourceLibraryPageState();
}

class _ResourceLibraryPageState extends State<ResourceLibraryPage> {
  String selectedCategory = 'All';

  final List<String> categories = [
    'All',
    'Prevention',
    'Diet',
    'Medication',
    'Mental Health'
  ];

  final List<ArticleInfo> allArticles = [
    ArticleInfo(
      category: 'Diet',
      title: 'Optimizing Nutrition During Treatment',
      desc: 'Discover essential nutrients to support your immune system...',
      icon: Icons.restaurant_menu,
      bgColor: const Color(0xFFE8F5F3), // Light teal
      iconColor: AppColors.primary,
    ),
    ArticleInfo(
      category: 'Medication',
      title: 'Understanding Your Daily Dosages',
      desc: 'A comprehensive guide to managing side effects and...',
      icon: Icons.medication,
      bgColor: AppColors.primary, // Dark teal
      iconColor: Colors.white,
    ),
    ArticleInfo(
      category: 'Prevention',
      title: 'Household Transmission Protocols',
      desc: 'Effective strategies to protect your family members and...',
      icon: Icons.masks,
      bgColor: AppColors.primaryLight, // Teal
      iconColor: Colors.white,
    ),
    ArticleInfo(
      category: 'Mental Health',
      title: 'Managing Treatment Fatigue',
      desc: 'Psychological coping mechanisms for long-term...',
      icon: Icons.psychology,
      bgColor: const Color(0xFFE0F2F1), // Very light teal
      iconColor: AppColors.primary,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Filter logic
    final filteredArticles = selectedCategory == 'All'
        ? allArticles
        : allArticles.where((a) => a.category == selectedCategory).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Custom Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.menu, color: AppColors.textPrimary),
                    onPressed: () {},
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const Text(
                    'TBC-Care',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const CircleAvatar(
                    radius: 18,
                    backgroundColor: Color(0xFFE0E0E0),
                    child: Icon(Icons.person, color: Colors.grey, size: 24),
                  ),
                ],
              ),
            ),
                        
            // Title Section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resource Library',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Curated medical knowledge for your journey.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Filter Chips List
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: categories.map((category) {
                  final isActive = selectedCategory == category;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedCategory = category;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: isActive
                              ? null
                              : Border.all(color: const Color(0xFFE0E0E0)),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            color: isActive ? Colors.white : AppColors.textSecondary,
                            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Articles List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 8.0, bottom: 24.0),
                itemCount: filteredArticles.length,
                itemBuilder: (context, index) {
                  final article = filteredArticles[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 6.0,
                    ),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ArticleReaderPage(),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Article Placeholder Image
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: article.bgColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Icon(
                                  article.icon,
                                  color: article.iconColor,
                                  size: 40,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Article Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    article.category.toUpperCase(),
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    article.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    article.desc,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
