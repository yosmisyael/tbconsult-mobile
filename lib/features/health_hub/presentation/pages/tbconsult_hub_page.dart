import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:TBConsult/core/di/injection_container.dart';
import 'package:TBConsult/core/theme/app_colors.dart';
import 'package:TBConsult/features/health_hub/domain/entities/conversation.dart';
import 'package:TBConsult/features/health_hub/presentation/cubit/health_hub_cubit.dart';
import 'package:TBConsult/features/health_hub/presentation/cubit/health_hub_state.dart';
import 'package:TBConsult/features/health_hub/presentation/cubit/conversation_cubit.dart';
import 'tbconsult_conversation_page.dart';

class TBConsultHubPage extends StatelessWidget {
  const TBConsultHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    _buildHeroSection(),
                    const SizedBox(height: 32),
                    _buildNewConversationButton(context),
                    const SizedBox(height: 32),
                    _buildSuggestedTopics(context),
                    const SizedBox(height: 32),
                    _buildRecentChats(context),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
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
            icon: const Icon(Icons.menu, color: AppColors.textPrimary),
            onPressed: () {},
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

  Widget _buildHeroSection() {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x33006A60),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.smart_toy,
              size: 60, color: AppColors.background),
        ),
        const SizedBox(height: 24),
        const Text(
          'Hello!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          "I'm here to support your journey.",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          "How are you feeling today? I'm ready to assist with your medical questions and daily care tracking.",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildNewConversationButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _navigateToNewConversation(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.background,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(100),
        ),
        elevation: 0,
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add, size: 20),
          SizedBox(width: 8),
          Text(
            'Start New Conversation',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedTopics(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Suggested Topics',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildTopicChip(context, 'Symptom Check',
                Icons.medical_services_outlined,
                'I want to check my symptoms'),
            _buildTopicChip(context, 'Medication Help',
                Icons.medication_outlined,
                'I need help with my TB medication'),
            _buildTopicChip(context, 'Dietary Tips',
                Icons.restaurant_outlined,
                'What foods should I eat during TB treatment?'),
          ],
        ),
      ],
    );
  }

  Widget _buildTopicChip(
    BuildContext context,
    String label,
    IconData icon,
    String initialMessage,
  ) {
    return GestureDetector(
      onTap: () =>
          _navigateToNewConversation(context, initialMessage: initialMessage),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border.all(color: const Color(0xFFE0E5E4)),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentChats(BuildContext context) {
    return BlocBuilder<HealthHubCubit, HealthHubState>(
      builder: (context, state) {
        if (state is HealthHubLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        if (state is HealthHubError) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                'Could not load conversations.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          );
        }

        if (state is HealthHubLoaded) {
          final conversations = state.recentConversations;

          if (conversations.isEmpty) {
            return Column(
              children: [
                const Row(
                  children: [
                    Text(
                      'Recent Chats',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.chat_bubble_outline,
                          color: AppColors.textSecondary, size: 32),
                      SizedBox(height: 8),
                      Text(
                        'No conversations yet',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }

          return Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Chats',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (conversations.length > 3)
                    TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'View All',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              ...conversations.take(5).map(
                    (conv) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildChatCard(context, conv),
                    ),
                  ),
            ],
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildChatCard(BuildContext context, Conversation conversation) {
    final timeLabel = _formatTimeLabel(conversation.lastMessageAt);
    final preview = conversation.lastMessage?.content ?? 'No messages yet';

    return GestureDetector(
      onTap: () => _navigateToExistingConversation(context, conversation.id),
      child: Container(
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.chat_bubble_outline,
                  color: AppColors.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          conversation.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    preview,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToNewConversation(
    BuildContext context, {
    String? initialMessage,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider<ConversationCubit>(
          create: (_) => sl<ConversationCubit>()..startNewConversation(),
          child: TBConsultConversationPage(initialMessage: initialMessage),
        ),
      ),
    ).then((_) {
      if (context.mounted) {
        context.read<HealthHubCubit>().refresh();
      }
    });
  }

  void _navigateToExistingConversation(
    BuildContext context,
    String conversationId,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider<ConversationCubit>(
          create: (_) => sl<ConversationCubit>()
            ..loadExistingConversation(conversationId),
          child: const TBConsultConversationPage(),
        ),
      ),
    ).then((_) {
      if (context.mounted) {
        context.read<HealthHubCubit>().refresh();
      }
    });
  }

  String _formatTimeLabel(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return 'Today, $hour:$minute';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
