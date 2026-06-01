import 'package:TBConsult/outer_shell.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:TBConsult/core/theme/app_colors.dart';
import 'package:TBConsult/features/health_hub/domain/entities/message.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:TBConsult/features/health_hub/presentation/cubit/conversation_cubit.dart';

class VoicePersona {
  final String name;
  final String voiceName;
  final String locale;
  final String description;
  final bool isMale;
  final double pitch;
  final double speechRate;

  const VoicePersona({
    required this.name,
    required this.voiceName,
    required this.locale,
    required this.description,
    required this.isMale,
    required this.pitch,
    required this.speechRate,
  });

  static const VoicePersona drSarah = VoicePersona(
    name: "Dr. Sarah",
    voiceName: "en-us-x-log-network",
    locale: "en-US",
    description: "Compassionate US Female voice",
    isMale: false,
    pitch: 1.0,
    speechRate: 0.46,
  );

  static const VoicePersona nurseClara = VoicePersona(
    name: "Nurse Clara",
    voiceName: "en-gb-gbc-network",
    locale: "en-GB",
    description: "Warm UK Female voice",
    isMale: false,
    pitch: 1.0,
    speechRate: 0.44,
  );

  static const VoicePersona drJames = VoicePersona(
    name: "Dr. James",
    voiceName: "en-us-x-iom-network",
    locale: "en-US",
    description: "Clear US Male voice",
    isMale: true,
    pitch: 0.96,
    speechRate: 0.47,
  );

  static const VoicePersona drArthur = VoicePersona(
    name: "Dr. Arthur",
    voiceName: "en-us-x-tpd-network",
    locale: "en-US",
    description: "Reassuring US Male voice",
    isMale: true,
    pitch: 0.92,
    speechRate: 0.45,
  );

  static const VoicePersona drIndah = VoicePersona(
    name: "Dr. Indah",
    voiceName: "id-id-x-idc-network",
    locale: "id-ID",
    description: "Suara Dokter Perempuan Indonesia",
    isMale: false,
    pitch: 1.0,
    speechRate: 0.58,
  );

  static const List<VoicePersona> all = [
    drSarah,
    nurseClara,
    drJames,
    drArthur,
    drIndah,
  ];
}

class ChatBubbleWidget extends StatefulWidget {
  final Message message;
  final bool isLatestUserMessage;
  static VoicePersona activePersona = VoicePersona.drIndah;

  const ChatBubbleWidget({
    super.key,
    required this.message,
    this.isLatestUserMessage = false,
  });

  static void stopSpeaking() {
    _ChatBubbleWidgetState._flutterTts.stop();
    if (_ChatBubbleWidgetState._currentlySpeakingState != null) {
      _ChatBubbleWidgetState._currentlySpeakingState!._stopActiveSpeaking();
    }
  }

  static String detectLanguage(String text) {
    final textLower = text.toLowerCase();

    // Common Indonesian words
    final indonesianWords = [
      'dan',
      'yang',
      'adalah',
      'untuk',
      'sakit',
      'rumah',
      'gejala',
      'batuk',
      'dokter',
      'terdekat',
      'layanan',
      'jarak',
      'penyakit',
      'paru',
      'pemeriksaan',
      'bisa',
      'pada',
      'tidak',
      'dengan',
      'kita',
      'triage',
      'risiko',
      'tinggi',
      'sedang',
      'rendah',
    ];

    // Common English words
    final englishWords = [
      'the',
      'and',
      'is',
      'you',
      'for',
      'cough',
      'hospital',
      'symptoms',
      'doctor',
      'nearest',
      'distance',
      'disease',
      'lung',
      'checkup',
      'can',
      'with',
      'triage',
      'risk',
      'high',
      'moderate',
      'low',
      'assessment',
      'sdui',
    ];

    int idScore = 0;
    int enScore = 0;

    final words = textLower.split(RegExp(r'\s+'));
    for (var word in words) {
      final cleanWord = word.replaceAll(RegExp(r'[^\w]'), '');
      if (indonesianWords.contains(cleanWord)) {
        idScore++;
      }
      if (englishWords.contains(cleanWord)) {
        enScore++;
      }
    }

    return enScore > idScore ? 'en-US' : 'id-ID';
  }

  @override
  State<ChatBubbleWidget> createState() => _ChatBubbleWidgetState();
}

class _ChatBubbleWidgetState extends State<ChatBubbleWidget> {
  bool _isEditing = false;
  late TextEditingController _editController;

  static final FlutterTts _flutterTts = FlutterTts();
  static String? _currentlySpeakingMessageId;
  static _ChatBubbleWidgetState? _currentlySpeakingState;

  void _stopActiveSpeaking() {
    if (mounted) {
      setState(() {
        _currentlySpeakingMessageId = null;
        _currentlySpeakingState = null;
      });
    }
  }

  bool get _isSpeaking => _currentlySpeakingMessageId == widget.message.id;

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController(text: _getEditText(widget.message));
  }

  @override
  void didUpdateWidget(ChatBubbleWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message.content != widget.message.content) {
      _editController.text = _getEditText(widget.message);
    }
  }

  String _getEditText(Message msg) {
    if (msg.type == MessageType.image) {
      final parts = msg.content.split('|');
      if (parts.length > 1) {
        return parts[1];
      }
      return '';
    }
    return msg.content;
  }

  @override
  void dispose() {
    _editController.dispose();
    if (_isSpeaking) {
      _flutterTts.stop();
      _currentlySpeakingMessageId = null;
      _currentlySpeakingState = null;
    }
    super.dispose();
  }

  String _cleanMarkdown(String text) {
    return text
        .replaceAll(RegExp(r'\*\*'), '')
        .replaceAll(RegExp(r'\*'), '')
        .replaceAll(RegExp(r'#+\s'), '')
        .replaceAll(RegExp(r'-\s'), '')
        .replaceAll(RegExp(r'•\s'), '')
        .replaceAll(RegExp(r'\[.*?\]'), '')
        .replaceAll(RegExp(r'\(.*?\)'), '')
        .trim();
  }

  Future<void> _setVoicePersona(String lang) async {
    try {
      final VoicePersona targetPersona;
      if (lang == 'id-ID') {
        targetPersona = VoicePersona.drIndah;
      } else {
        if (ChatBubbleWidget.activePersona.locale.startsWith('en')) {
          targetPersona = ChatBubbleWidget.activePersona;
        } else {
          targetPersona = VoicePersona.drSarah; // English female default
        }
      }

      debugPrint("TTS: Setting language to ${targetPersona.locale}");
      await _flutterTts.setLanguage(targetPersona.locale);

      // Fetch available voices on the device to resolve the correct name
      final List<dynamic>? voices = await _flutterTts.getVoices;
      String selectedVoiceName = targetPersona.voiceName;

      if (voices != null) {
        String targetNormalized = targetPersona.voiceName
            .toLowerCase()
            .replaceAll(RegExp(r'[-_x]'), '');

        for (var v in voices) {
          if (v is Map) {
            final name = v['name']?.toString();
            if (name != null) {
              String nameNormalized = name.toLowerCase().replaceAll(
                RegExp(r'[-_x]'),
                '',
              );
              if (nameNormalized == targetNormalized) {
                selectedVoiceName = name;
                debugPrint(
                  "TTS: Resolved matching voice name to: $selectedVoiceName",
                );
                break;
              }
            }
          }
        }
      }

      if (voices != null && selectedVoiceName == targetPersona.voiceName) {
        debugPrint(
          "TTS: Exact voice '$selectedVoiceName' not found. Available voices for this locale:",
        );
        for (var v in voices) {
          if (v is Map) {
            final name = v['name']?.toString();
            final locale = v['locale']?.toString() ?? v['language']?.toString();
            if (locale != null &&
                locale
                    .toLowerCase()
                    .replaceAll('_', '-')
                    .startsWith(
                      targetPersona.locale
                          .toLowerCase()
                          .replaceAll('_', '-')
                          .substring(0, 2),
                    )) {
              debugPrint("  - $name ($locale)");
            }
          }
        }
      }

      debugPrint(
        "TTS: Setting voice: $selectedVoiceName (${targetPersona.locale})",
      );
      await _flutterTts.setVoice({
        'name': selectedVoiceName,
        'locale': targetPersona.locale,
      });

      debugPrint(
        "TTS: Applying tuned pitch ${targetPersona.pitch}, speech rate ${targetPersona.speechRate}, and volume 1.0 for ${targetPersona.name}",
      );
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(targetPersona.pitch);
      await _flutterTts.setSpeechRate(targetPersona.speechRate);
    } catch (e) {
      debugPrint("TTS Error in _setVoicePersona: $e");
      await _flutterTts.setLanguage(lang);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setSpeechRate(0.5);
    }
  }

  Future<void> _toggleSpeak() async {
    if (_isSpeaking) {
      await _flutterTts.stop();
      setState(() {
        _currentlySpeakingMessageId = null;
        _currentlySpeakingState = null;
      });
    } else {
      if (_currentlySpeakingState != null) {
        final oldState = _currentlySpeakingState;
        await _flutterTts.stop();
        oldState?.setState(() {
          _currentlySpeakingMessageId = null;
          _currentlySpeakingState = null;
        });
      }

      String lang = ChatBubbleWidget.detectLanguage(widget.message.content);

      await _setVoicePersona(lang);

      _flutterTts.setCompletionHandler(() {
        if (mounted) {
          setState(() {
            _currentlySpeakingMessageId = null;
            _currentlySpeakingState = null;
          });
        }
      });

      _flutterTts.setErrorHandler((msg) {
        debugPrint("TTS error: $msg");
        if (mounted) {
          setState(() {
            _currentlySpeakingMessageId = null;
            _currentlySpeakingState = null;
          });
        }
      });

      setState(() {
        _currentlySpeakingMessageId = widget.message.id;
        _currentlySpeakingState = this;
      });

      String cleanText = _cleanMarkdown(widget.message.content);
      await _flutterTts.speak(cleanText);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBot = widget.message.role == MessageRole.assistant;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: isBot
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.end,
        children: [
          isBot ? _buildBotBubble(context) : _buildUserBubble(context),
          if (!_isEditing) _buildBubbleActions(context),
        ],
      ),
    );
  }

  Widget _buildBotBubble(BuildContext context) {
    final hasRisk =
        widget.message.riskLevel != null &&
        widget.message.riskLevel!.isNotEmpty;
    final risk = widget.message.riskLevel;
    final hasRedFlags =
        widget.message.redFlags != null && widget.message.redFlags!.isNotEmpty;
    final hasSdui =
        widget.message.sdui != null &&
        widget.message.sdui!['components'] != null;

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
        CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
          radius: 14,
          child: const Icon(
            Icons.smart_toy,
            color: AppColors.primary,
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
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
                                  Icon(
                                    Icons.gpp_bad_outlined,
                                    color: Color(0xFFC62828),
                                    size: 16,
                                  ),
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
                              ...widget.message.redFlags!.map(
                                (flag) => Padding(
                                  padding: const EdgeInsets.only(
                                    left: 22,
                                    top: 2,
                                  ),
                                  child: Text(
                                    "• $flag",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFFB71C1C),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // 3. Response Content Text
                      Theme(
                        data: Theme.of(context).copyWith(
                          textSelectionTheme: TextSelectionThemeData(
                            selectionColor: AppColors.primary.withValues(
                              alpha: 0.2,
                            ),
                            selectionHandleColor: AppColors.primary,
                          ),
                        ),
                        child: SelectionArea(
                          child: MarkdownBody(
                            data: widget.message.content.replaceAll(
                              ' •',
                              '\n•',
                            ),
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
                        ),
                      ),

                      // 4. Server-Driven UI (SDUI) Buttons / Components
                      if (hasSdui) ...[
                        const SizedBox(height: 12),
                        ..._buildSduiComponents(
                          context,
                          widget.message.sdui!['components'] as List<dynamic>,
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

  List<Widget> _buildSduiComponents(
    BuildContext context,
    List<dynamic> components,
  ) {
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
                child: ElevatedButton(
                  onPressed: () {
                    if (action == 'call_facility') {
                      final phone = comp['phone'] as String?;
                      if (phone != null) {
                        final cleaned = phone.replaceAll(RegExp(r'[^0-9+]'), '');
                        final uri = Uri.parse('tel:$cleaned');
                        canLaunchUrl(uri).then((canLaunch) {
                          if (canLaunch) {
                            launchUrl(uri);
                          }
                        });
                      }
                    } else if (action == 'visit_dots' ||
                        action == 'consult' ||
                        action == 'contact_nutritionist' ||
                        action == 'consult_doctor') {
                      final state = OuterShell.navKey.currentState;
                      final facilityId = comp['facility_id'] as String?;
                      if (state != null) {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        }
                        if (action == 'visit_dots') {
                          state.navigateToMap(facilityId: facilityId);
                        } else {
                          state.setSelectedIndex(2);
                        }
                      } else {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OuterShell(
                              initialIndex: 2,
                              facilityId: action == 'visit_dots' ? facilityId : null,
                            ),
                          ),
                          (_) => false,
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        action == 'call_facility'
                            ? Icons.phone_outlined
                            : (action == 'visit_dots'
                                ? Icons.map_outlined
                                : Icons.chat_outlined),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
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

  Widget _buildUserBubble(BuildContext context) {
    final isImage = widget.message.type == MessageType.image;

    String imagePathsString = '';
    String promptText = '';
    if (isImage) {
      final parts = widget.message.content.split('|');
      imagePathsString = parts[0];
      if (parts.length > 1) {
        promptText = parts[1];
      }
    }

    final List<String> imagePaths = imagePathsString.isNotEmpty
        ? imagePathsString.split(',')
        : [];

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const SizedBox(width: 40),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (isImage && imagePaths.isNotEmpty && !_isEditing)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.end,
                    children: imagePaths
                        .where((path) => File(path).existsSync())
                        .map((path) {
                          return Container(
                            constraints: const BoxConstraints(
                              maxHeight: 200,
                              maxWidth: 200,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              image: DecorationImage(
                                image: FileImage(File(path)),
                                fit: BoxFit.cover,
                              ),
                            ),
                            width: imagePaths.length > 1
                                ? 150
                                : 200, // Slightly smaller if multiple
                            height: imagePaths.length > 1 ? 150 : 200,
                          );
                        })
                        .toList(),
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
                child: _isEditing
                    ? _buildBalloonEditField(context)
                    : Theme(
                        data: Theme.of(context).copyWith(
                          textSelectionTheme: TextSelectionThemeData(
                            selectionColor: Colors.white.withValues(alpha: 0.3),
                            selectionHandleColor: Colors.white,
                          ),
                        ),
                        child: SelectionArea(
                          child: Text(
                            isImage
                                ? (promptText.isNotEmpty
                                      ? promptText
                                      : '📸 Image attached')
                                : widget.message.content,
                            style: const TextStyle(
                              fontSize: 15,
                              color: AppColors.background,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBalloonEditField(BuildContext context) {
    final isImage = widget.message.type == MessageType.image;
    String imagePathsString = '';
    if (isImage) {
      final parts = widget.message.content.split('|');
      imagePathsString = parts[0];
    }

    final List<String> imagePaths = imagePathsString.isNotEmpty
        ? imagePathsString.split(',')
        : [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isImage && imagePaths.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: imagePaths.where((path) => File(path).existsSync()).map(
                (path) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(path),
                      height: 80,
                      width: 80,
                      fit: BoxFit.cover,
                    ),
                  );
                },
              ).toList(),
            ),
          ),
        TextField(
          controller: _editController,
          maxLines: null,
          autofocus: true,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            height: 1.4,
          ),
          cursorColor: Colors.white,
          decoration: const InputDecoration(
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  _isEditing = false;
                  _editController.text =
                      widget.message.content; // revert changes
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.close, size: 14, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                final text = _editController.text.trim();
                if (text.isNotEmpty) {
                  setState(() {
                    _isEditing = false;
                  });
                  context.read<ConversationCubit>().editAndResendLatestMessage(
                    text,
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check, size: 14, color: AppColors.primary),
                    SizedBox(width: 4),
                    Text(
                      'Update',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBubbleActions(BuildContext context) {
    final isUser = widget.message.role == MessageRole.user;

    return Padding(
      padding: EdgeInsets.only(
        top: 6,
        left: isUser ? 0 : 36, // Align bot actions with bot bubble container
        right: isUser ? 4 : 0,
      ),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          _buildActionButton(
            icon: Icons.copy_all_outlined,
            onTap: () {
              Clipboard.setData(ClipboardData(text: widget.message.content));
            },
          ),
          if (!isUser) ...[
            const SizedBox(width: 8),
            _buildActionButton(
              icon: _isSpeaking ? Icons.volume_up : Icons.volume_up_outlined,
              onTap: _toggleSpeak,
            ),
          ],
          if (isUser &&
              widget.isLatestUserMessage &&
              (widget.message.type == MessageType.text ||
                  widget.message.type == MessageType.image)) ...[
            const SizedBox(width: 8),
            _buildActionButton(
              icon: Icons.edit_outlined,
              onTap: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary.withValues(
          alpha: 0.12,
        ), // Soft primary color circle
      ),
      child: IconButton(
        icon: Icon(
          icon,
          size: 14,
          color: AppColors.primary,
        ), // Icon matches primary color palette
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        onPressed: onTap,
      ),
    );
  }
}
