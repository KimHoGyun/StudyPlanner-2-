// lib/services/chat_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/chat_models.dart';

class ChatService {
  static const String baseUrl = 'https://studyplanner-production-0729.up.railway.app';

  // 공통 헤더 생성
  static Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    };
  }

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
      print('=== 메시지 전송 시도 ===');
      print('URL: $baseUrl/api/chat/send');
      print('Data: studyGroupId=$studyGroupId, userId=$userId, content=$content');

      final body = jsonEncode({
        'studyGroupId': studyGroupId,
        'userId': userId,
        'content': content,
        'messageType': messageType ?? 'text',
        'fileName': fileName,
        'fileUrl': fileUrl,
      });

      print('Request body: $body');

      final response = await http.post(
        Uri.parse('$baseUrl/api/chat/send'),
        headers: _getHeaders(),
        body: body,
      );

      print('Response status: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          ...data,
        };
      } else {
        print('Error response: ${response.statusCode} - ${response.body}');
        return {
          'success': false,
          'message': 'Failed to send message: HTTP ${response.statusCode}',
          'error': response.body,
        };
      }
    } catch (e) {
      print('Send Message Exception: $e');
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

      print('Getting messages from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: _getHeaders(),
      );

      print('Get Messages Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => ChatMessage.fromJson(json)).toList();
      } else {
        print('Failed to get messages: ${response.statusCode} - ${response.body}');
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

      // 헤더 추가
      request.headers.addAll({
        'Accept': 'application/json',
        'Access-Control-Allow-Origin': '*',
      });

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
        headers: _getHeaders(),
      );

      print('Get Files Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => FileAttachment.fromJson(json)).toList();
      } else {
        print('Failed to get files: ${response.statusCode}');
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
        headers: _getHeaders(),
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
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => ChatMessage.fromJson(json)).toList();
      } else {
        print('Poll messages failed: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Poll Messages Error: $e');
      return [];
    }
  }
}