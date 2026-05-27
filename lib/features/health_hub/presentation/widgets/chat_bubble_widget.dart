import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import 'package:TBConsult/core/theme/app_colors.dart';
import 'package:TBConsult/features/health_hub/domain/entities/message.dart';
import 'package:TBConsult/features/maps/presentation/pages/map_page.dart';

class ChatBubbleWidget extends StatelessWidget {
  final Message message;

  const ChatBubbleWidget({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: message.role == MessageRole.assistant
          ? _buildBotBubble(context)
          : _buildUserBubble(),
    );
  }

  Widget _buildBotBubble(BuildContext context) {
    final hasRisk = message.riskLevel != null;
    final risk = message.riskLevel;
    final hasRedFlags = message.redFlags != null && message.redFlags!.isNotEmpty;
    final hasSources = message.sources != null && message.sources!.isNotEmpty;
    final hasSdui = message.sdui != null && message.sdui!['components'] != null;

    Color riskColor = Colors.grey;
    IconData riskIcon = Icons.info_outline;
    String riskLabel = "Low Risk";

    if (risk == "High") {
      riskColor = const Color(0xFFD32F2F);
      riskIcon = Icons.warning_rounded;
      riskLabel = "High Risk Assessment";
    } else if (risk == "Moderate") {
      riskColor = const Color(0xFFF57C00);
      riskIcon = Icons.error_outline_rounded;
      riskLabel = "Moderate Risk Assessment";
    } else if (risk == "Low") {
      riskColor = const Color(0xFF388E3C);
      riskIcon = Icons.check_circle_outline_rounded;
      riskLabel = "Low Risk Assessment";
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const CircleAvatar(
          backgroundColor: Color(0xFFE0E5E4),
          radius: 14,
          child: Icon(
            Icons.smart_toy,
            color: AppColors.textSecondary,
            size: 16,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Risk Level Banner
                if (hasRisk)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    color: riskColor.withAlpha(25),
                    child: Row(
                      children: [
                        Icon(riskIcon, color: riskColor, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          riskLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: riskColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 2. Red Flags Warnings
                      if (hasRedFlags)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFFCDD2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.gpp_bad_outlined, color: Color(0xFFC62828), size: 16),
                                  SizedBox(width: 6),
                                  Text(
                                    "Red Flags Detected:",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: Color(0xFFC62828),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              ...message.redFlags!.map((flag) => Padding(
                                    padding: const EdgeInsets.only(left: 22, top: 2),
                                    child: Text(
                                      "• $flag",
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFFB71C1C),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  )),
                            ],
                          ),
                        ),

                      // 3. Response Content Text
                      MarkdownBody(
                        data: message.content,
                        styleSheet: MarkdownStyleSheet(
                          p: const TextStyle(
                            fontSize: 15,
                            color: AppColors.textPrimary,
                            height: 1.4,
                          ),
                          listBullet: const TextStyle(
                            fontSize: 15,
                            color: AppColors.textPrimary,
                            height: 1.4,
                          ),
                        ),
                      ),

                      // 4. Server-Driven UI (SDUI) Buttons / Components
                      if (hasSdui) ...[
                        const SizedBox(height: 12),
                        ..._buildSduiComponents(context, message.sdui!['components'] as List<dynamic>),
                      ],

                      // 5. Sources / Citations
                      if (hasSources) ...[
                        const SizedBox(height: 12),
                        const Divider(height: 1, color: Colors.black12),
                        const SizedBox(height: 8),
                        const Text(
                          "Sources:",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: message.sources!.map((source) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withAlpha(20),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: AppColors.primary.withAlpha(50)),
                                ),
                                child: Text(
                                  source,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              )).toList(),
                        ),
                      ],

                    ],
                  ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      );
  }

  List<Widget> _buildSduiComponents(BuildContext context, List<dynamic> components) {
    final List<Widget> list = [];
    for (final comp in components) {
      if (comp is Map<String, dynamic>) {
        final type = comp['type'] as String?;
        final label = comp['label'] as String? ?? 'Action';
        final action = comp['action'] as String?;

        if (type == 'button') {
          list.add(
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (action == 'visit_dots' || action == 'consult') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MapPage()),
                      );
                    }
                  },
                  icon: const Icon(Icons.map_outlined, size: 16),
                  label: Text(label),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
          );
        }
      }
    }
    return list;
  }

  Widget _buildUserBubble() {
    final isImage = message.type == MessageType.image;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const SizedBox(width: 40),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (isImage && File(message.content).existsSync())
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  constraints:
                      const BoxConstraints(maxHeight: 200, maxWidth: 200),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: FileImage(File(message.content)),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(4),
                  ),
                ),
                child: Text(
                  isImage ? '📸 Image attached' : message.content,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.background,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
