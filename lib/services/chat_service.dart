// lib/services/chat_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/chat_models.dart';

class ChatService {
  static const String baseUrl = 'https://studyplanner-production-0729.up.railway.app';

  // 채팅 메시지 전송
  static Future<Map<String, dynamic>> sendMessage({
    required int studyGroupId,
    required int userId,
    required String content,
    String? messageType,
    String? fileName,
    String? fileUrl,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/chat/send'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'studyGroupId': studyGroupId,
          'userId': userId,
          'content': content,
          'messageType': messageType ?? 'text',
          'fileName': fileName,
          'fileUrl': fileUrl,
        }),
      );

      print('Send Message Response Status: ${response.statusCode}');
      print('Send Message Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Failed to send message: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Send Message Error: $e');
      return {
        'success': false,
        'message': 'Network error: $e'
      };
    }
  }

  // 채팅 메시지 목록 조회
  static Future<List<ChatMessage>> getMessages(int studyGroupId, {int? lastMessageId, int limit = 50}) async {
    try {
      String url = '$baseUrl/api/chat/$studyGroupId/messages?limit=$limit';
      if (lastMessageId != null) {
        url += '&lastMessageId=$lastMessageId';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('Get Messages Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => ChatMessage.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('Get Messages Error: $e');
      return [];
    }
  }

  // 파일 업로드
  static Future<Map<String, dynamic>> uploadFile({
    required File file,
    required int studyGroupId,
    required int userId,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/files/upload'),
      );

      request.fields['studyGroupId'] = studyGroupId.toString();
      request.fields['userId'] = userId.toString();

      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      print('Upload File Response Status: ${response.statusCode}');
      print('Upload File Response Body: $responseBody');

      if (response.statusCode == 200) {
        return jsonDecode(responseBody);
      } else {
        return {
          'success': false,
          'message': 'Failed to upload file: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Upload File Error: $e');
      return {
        'success': false,
        'message': 'Network error: $e'
      };
    }
  }

  // 파일 목록 조회
  static Future<List<FileAttachment>> getFiles(int studyGroupId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/files/$studyGroupId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('Get Files Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => FileAttachment.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('Get Files Error: $e');
      return [];
    }
  }

  // 메시지 삭제
  static Future<Map<String, dynamic>> deleteMessage(int messageId, int userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/chat/message/$messageId?userId=$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('Delete Message Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Failed to delete message: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Delete Message Error: $e');
      return {
        'success': false,
        'message': 'Network error: $e'
      };
    }
  }

  // 실시간 메시지 폴링 (WebSocket 대신 간단한 폴링)
  static Future<List<ChatMessage>> pollNewMessages(int studyGroupId, DateTime lastCheck) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/chat/$studyGroupId/poll?since=${lastCheck.toIso8601String()}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => ChatMessage.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('Poll Messages Error: $e');
      return [];
    }
  }
}