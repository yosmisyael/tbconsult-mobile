import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:TBConsult/features/health_hub/data/models/message_model.dart';
import 'package:TBConsult/features/health_hub/domain/entities/message.dart';

void main() {
  final fixedTimestamp = DateTime.parse('2026-05-23T12:00:00.000Z');

  final tMessageModel = MessageModel(
    id: 'msg-1',
    conversationId: 'conv-1',
    role: MessageRole.assistant,
    type: MessageType.text,
    content: 'Please visit a clinic.',
    timestamp: fixedTimestamp, // We will use a fixed ISO string for test parsing
    isGrounded: true,
    riskLevel: 'Moderate',
    redFlags: const ['fever', 'cough with blood'],
    sources: const ['Source 1', 'Source 2'],
    sdui: const {
      'components': [
        {'type': 'button', 'label': 'View Map', 'action': 'visit_dots'}
      ]
    },
  );
  final tMessageModelWithFixedTime = MessageModel(
    id: 'msg-1',
    conversationId: 'conv-1',
    role: MessageRole.assistant,
    type: MessageType.text,
    content: 'Please visit a clinic.',
    timestamp: fixedTimestamp,
    isGrounded: true,
    riskLevel: 'Moderate',
    redFlags: const ['fever', 'cough with blood'],
    sources: const ['Source 1', 'Source 2'],
    sdui: const {
      'components': [
        {'type': 'button', 'label': 'View Map', 'action': 'visit_dots'}
      ]
    },
  );

  group('fromJson', () {
    test('should return a valid model when the JSON is fully populated', () {
      // arrange
      final Map<String, dynamic> jsonMap = {
        'id': 'msg-1',
        'conversationId': 'conv-1',
        'role': 'assistant',
        'type': 'text',
        'content': 'Please visit a clinic.',
        'timestamp': '2026-05-23T12:00:00.000Z',
        'isGrounded': true,
        'riskLevel': 'Moderate',
        'redFlags': ['fever', 'cough with blood'],
        'sources': ['Source 1', 'Source 2'],
        'sdui': {
          'components': [
            {'type': 'button', 'label': 'View Map', 'action': 'visit_dots'}
          ]
        },
      };

      // act
      final result = MessageModel.fromJson(jsonMap);

      // assert
      expect(result, tMessageModelWithFixedTime);
    });
  });

  group('toJson', () {
    test('should return a JSON map containing the proper data', () {
      // act
      final result = tMessageModelWithFixedTime.toJson();

      // assert
      final expectedMap = {
        'id': 'msg-1',
        'conversationId': 'conv-1',
        'role': 'assistant',
        'type': 'text',
        'content': 'Please visit a clinic.',
        'timestamp': '2026-05-23T12:00:00.000Z',
        'isGrounded': true,
        'riskLevel': 'Moderate',
        'redFlags': ['fever', 'cough with blood'],
        'sources': ['Source 1', 'Source 2'],
        'sdui': {
          'components': [
            {'type': 'button', 'label': 'View Map', 'action': 'visit_dots'}
          ]
        },
      };
      expect(result, expectedMap);
    });
  });
}
