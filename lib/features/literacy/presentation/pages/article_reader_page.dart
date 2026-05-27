import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ArticleReaderPage extends StatelessWidget {
  const ArticleReaderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_border, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Section
            Container(
              width: double.infinity,
              height: 250,
              decoration: const BoxDecoration(
                color: Color(0xFF2C3E50), // Dark teal/grey placeholder bg
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Stack(
                children: [
                  const Center(
                    child: Icon(
                      Icons.book,
                      size: 80,
                      color: Colors.white24,
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text(
                            'NUTRITION',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.timer_outlined,
                                color: Colors.white,
                                size: 12,
                              ),
                              SizedBox(width: 4),
                              Text(
                                '5 min read',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content Section
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Understanding Your Nutritional Needs During Treatment',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 20,
                        backgroundColor: Color(0xFFE0E0E0),
                        child: Icon(Icons.person, color: Colors.grey),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Dr. Sarah Jenkins',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Clinical Nutritionist • Oct 12, 2023',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Proper nutrition plays a critical role in supporting your body's recovery process. Understanding what to eat can help mitigate side effects and improve your overall energy levels.",
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'The Foundation of Recovery',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "When undergoing long-term treatment, your body enters a state of increased metabolic demand. This means you require more energy, protein, and specific micronutrients than you normally would just to maintain your current baseline.",
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Key Takeaway Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5F3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.lightbulb,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Key Takeaway',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Focus on nutrient-dense foods rather than simply increasing caloric intake. Every meal is an opportunity to provide your body with the building blocks it needs for cellular repair.",
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  const Text(
                    'Essential Nutrients',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Certain vitamins and minerals become particularly important during your recovery phase. Here are the primary components to focus on:",
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Nutrients List
                  _buildNutrientItem(
                    'High-Quality Protein',
                    'Crucial for repairing tissue and maintaining immune function. Lean meats, legumes, and dairy are excellent sources.',
                  ),
                  const SizedBox(height: 16),
                  _buildNutrientItem(
                    'Iron and Vitamin C',
                    'Vital for preventing anemia, a common complication. Vitamin C helps your body absorb plant-based iron more effectively.',
                  ),
                  const SizedBox(height: 16),
                  _buildNutrientItem(
                    'Complex Carbohydrates',
                    'Provide sustained energy without causing rapid spikes and crashes in blood sugar levels.',
                  ),
                  const SizedBox(height: 24),
                  
                  // Log Your Daily Intake Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Log Your Daily Intake',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Keep track of your meals to ensure you're meeting your nutritional goals today.",
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              '+ Open Nutrition Tracker',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  const Text(
                    'Managing Side Effects',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "It's normal to experience changes in appetite or taste during treatment. If you find eating difficult, try having smaller, more frequent meals throughout the day rather than three large ones.\n\nRemember to stay adequately hydrated. Water is essential for helping your liver and kidneys process medications efficiently.",
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Feedback Section
                  Center(
                    child: Column(
                      children: [
                        const Text(
                          'Was this article helpful?',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () {},
                              icon: const Icon(
                                Icons.thumb_up_outlined,
                                size: 18,
                                color: AppColors.textPrimary,
                              ),
                              label: const Text(
                                'Yes',
                                style: TextStyle(color: AppColors.textPrimary),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFE0E0E0)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton.icon(
                              onPressed: () {},
                              icon: const Icon(
                                Icons.thumb_down_outlined,
                                size: 18,
                                color: AppColors.textPrimary,
                              ),
                              label: const Text(
                                'No',
                                style: TextStyle(color: AppColors.textPrimary),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFE0E0E0)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientItem(String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2.0),
          child: Icon(
            Icons.check_circle,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
