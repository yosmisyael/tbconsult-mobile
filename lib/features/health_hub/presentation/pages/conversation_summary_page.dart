import 'package:flutter/material.dart';

import 'package:TBConsult/core/theme/app_colors.dart';
import 'package:TBConsult/features/health_hub/domain/entities/conversation.dart';

class ConversationSummaryPage extends StatelessWidget {
  final Conversation conversation;

  const ConversationSummaryPage({super.key, required this.conversation});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Conversation Summary',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildTimestampRow(),
                    const SizedBox(height: 24),
                    if (conversation.summaryText != null) ...[
                      _buildSummaryCard(),
                      const SizedBox(height: 16),
                    ],
                    _buildKeyInsightsCard(),
                    const SizedBox(height: 16),
                    _buildRecommendationsCard(),
                    const SizedBox(height: 24),
                    _buildActionButtons(context),
                    const SizedBox(height: 24),
                    _buildFeedbackSection(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
          left: 16.0, right: 20.0, top: 12.0, bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          const Text(
            'TBConsult',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildTimestampRow() {
    final date = conversation.startedAt;
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    final formatted =
        '${months[date.month - 1]} ${date.day}, ${date.year} at $hour:$minute';

    return Row(
      children: [
        const Icon(Icons.calendar_today, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(
          formatted,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.description_outlined,
                    color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 12),
              const Text(
                'Summary',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            conversation.summaryText!,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyInsightsCard() {
    final insights = conversation.keyInsights.isNotEmpty
        ? conversation.keyInsights
        : ['Conversation reviewed by TBConsult AI'];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF8E1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.monitor_heart,
                    color: Colors.amber, size: 18),
              ),
              const SizedBox(width: 12),
              const Text(
                'Key Insights',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...insights.map((insight) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.circular(8),
                    border: const Border(
                      left: BorderSide(color: AppColors.primary, width: 4),
                    ),
                  ),
                  child: Text(
                    insight,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      height: 1.5,
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildRecommendationsCard() {
    final recommendations = conversation.recommendations.isNotEmpty
        ? conversation.recommendations
        : [
            'Continue following your treatment plan',
            'Consult your healthcare provider for specific concerns',
          ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.checklist,
                    color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 12),
              const Text(
                'Recommendations',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...recommendations.map((text) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildRecommendationItem(text),
              )),
        ],
      ),
    );
  }

  Widget _buildRecommendationItem(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2.0),
            child: Icon(Icons.check_circle, color: Color(0xFFC6A84E), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Summary saved successfully!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.background,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
              ),
              elevation: 0,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bookmark_border, size: 20),
                SizedBox(width: 8),
                Text(
                  'Save Summary',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF0F0F0),
              foregroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
              ),
              elevation: 0,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.arrow_back, size: 20),
                SizedBox(width: 8),
                Text(
                  'Back to Conversation',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackSection() {
    return Center(
      child: Column(
        children: [
          const Text(
            'Was this helpful?',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildFeedbackButton(Icons.thumb_up_outlined),
              const SizedBox(width: 16),
              _buildFeedbackButton(Icons.thumb_down_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackButton(IconData icon) {
    return Container(
      width: 48,
      height: 48,
      decoration: const BoxDecoration(
        color: AppColors.background,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: AppColors.textSecondary, size: 20),
        onPressed: () {},
      ),
    );
  }
}
