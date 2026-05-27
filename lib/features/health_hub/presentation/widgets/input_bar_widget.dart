import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:TBConsult/core/theme/app_colors.dart';

class InputBarWidget extends StatelessWidget {
  final TextEditingController textController;
  final FocusNode focusNode;
  final bool isLoading;
  final bool isListening;
  final bool isTranscribing;
  final VoidCallback onSend;
  final VoidCallback onMicTap;
  final VoidCallback onMediaTap;
  final GlobalKey mediaButtonKey;

  const InputBarWidget({
    super.key,
    required this.textController,
    required this.focusNode,
    required this.isLoading,
    required this.isListening,
    required this.isTranscribing,
    required this.onSend,
    required this.onMicTap,
    required this.onMediaTap,
    required this.mediaButtonKey,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 24),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              key: mediaButtonKey,
              icon: const Icon(
                Icons.perm_media_outlined,
                color: AppColors.primary,
              ),
              onPressed: onMediaTap,
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7F8),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: textController,
                  builder: (context, value, _) {
                    return TextField(
                      controller: textController,
                      focusNode: focusNode,
                      maxLines: 5,
                      minLines: 1,
                      textAlignVertical: TextAlignVertical.center,
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: isTranscribing
                            ? 'Transcribing...'
                            : (isListening
                                ? 'Listening...'
                                : 'Type a message...'),
                        hintStyle: (isListening || isTranscribing)
                            ? GoogleFonts.outfit(
                                color:
                                    AppColors.primary.withValues(alpha: 0.5),
                                fontStyle: FontStyle.italic,
                              )
                            : GoogleFonts.outfit(color: Colors.grey),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: InputBorder.none,
                        suffixIcon: value.text.isNotEmpty
                            ? GestureDetector(
                                onTap: () {
                                  textController.clear();
                                  focusNode.unfocus();
                                },
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.grey,
                                  size: 20,
                                ),
                              )
                            : null,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: textController,
                builder: (context, value, _) {
                  return GestureDetector(
                    onTap: value.text.isNotEmpty ? onSend : onMicTap,
                    child: CircleAvatar(
                      backgroundColor: isLoading
                          ? AppColors.textSecondary
                          : AppColors.primary,
                      radius: 20,
                      child: isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: AppColors.background,
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(
                              value.text.isNotEmpty
                                  ? Icons.send
                                  : (isListening
                                      ? Icons.pause
                                      : Icons.mic),
                              color: AppColors.background,
                              size: 20,
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
