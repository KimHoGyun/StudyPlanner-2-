// lib/services/chat_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/chat_models.dart';

class ChatService {
  static const String baseUrl = 'https://studyplanner-production-0729.up.railway.app';

  // HTTP 클라이언트 생성 (재사용)
  static final http.Client _client = http.Client();

  // 공통 헤더 생성 (Flutter Web용 최적화)
  static Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
      'User-Agent': 'Flutter-Web-Client',
      // CORS 관련 헤더는 브라우저가 자동으로 처리하므로 제거
    };
  }

  // 네트워크 요청 래퍼 (에러 처리 강화)
  static Future<http.Response> _makeRequest(
      Future<http.Response> Function() request,
      ) async {
    try {
      // 요청 타임아웃 설정
      return await request().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout after 30 seconds');
        },
      );
    } on SocketException {
      throw Exception('No internet connection');
    } on HttpException catch (e) {
      throw Exception('HTTP error: ${e.message}');
    } on FormatException {
      throw Exception('Invalid response format');
    } catch (e) {
      throw Exception('Network error: $e');
    }
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
      final url = '$baseUrl/api/chat/send';
      print('URL: $url');

      final requestData = {
        'studyGroupId': studyGroupId,
        'userId': userId,
        'content': content,
        'messageType': messageType ?? 'text',
        if (fileName != null) 'fileName': fileName,
        if (fileUrl != null) 'fileUrl': fileUrl,
      };

      print('Request data: $requestData');

      final response = await _makeRequest(() => _client.post(
        Uri.parse(url),
        headers: _getHeaders(),
        body: jsonEncode(requestData),
      ));

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          ...data,
        };
      } else {
        // 상세한 에러 정보 반환
        String errorMessage = 'HTTP ${response.statusCode}';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['message'] != null) {
            errorMessage = errorData['message'];
          }
        } catch (e) {
          errorMessage = response.body;
        }

        return {
          'success': false,
          'message': 'Failed to send message: $errorMessage',
          'statusCode': response.statusCode,
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
  static Future<List<ChatMessage>> getMessages(
      int studyGroupId, {
        int? lastMessageId,
        int limit = 50,
      }) async {
    try {
      String url = '$baseUrl/api/chat/$studyGroupId/messages?limit=$limit';
      if (lastMessageId != null) {
        url += '&lastMessageId=$lastMessageId';
      }

      print('Getting messages from: $url');

      final response = await _makeRequest(() => _client.get(
        Uri.parse(url),
        headers: _getHeaders(),
      ));

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

  // 파일 업로드 (multipart/form-data)
  static Future<Map<String, dynamic>> uploadFile({
    required File file,
    required int studyGroupId,
    required int userId,
  }) async {
    try {
      print('=== 파일 업로드 시도 ===');
      final url = '$baseUrl/api/files/upload';
      print('URL: $url');

      var request = http.MultipartRequest('POST', Uri.parse(url));

      // 필드 추가
      request.fields['studyGroupId'] = studyGroupId.toString();
      request.fields['userId'] = userId.toString();

      // 파일 추가
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      // 요청 전송 (타임아웃 포함)
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60), // 파일 업로드는 더 긴 타임아웃
        onTimeout: () {
          throw Exception('File upload timeout after 60 seconds');
        },
      );

      final response = await http.Response.fromStream(streamedResponse);
      print('Upload File Response Status: ${response.statusCode}');
      print('Upload File Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Failed to upload file: HTTP ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Upload File Error: $e');
      return {
        'success': false,
        'message': 'Upload error: $e'
      };
    }
  }

  // 파일 목록 조회
  static Future<List<FileAttachment>> getFiles(int studyGroupId) async {
    try {
      final response = await _makeRequest(() => _client.get(
        Uri.parse('$baseUrl/api/files/$studyGroupId'),
        headers: _getHeaders(),
      ));

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

  // 실시간 메시지 폴링
  static Future<List<ChatMessage>> pollNewMessages(
      int studyGroupId,
      DateTime lastCheck,
      ) async {
    try {
      final url = '$baseUrl/api/chat/$studyGroupId/poll?since=${Uri.encodeComponent(lastCheck.toIso8601String())}';

      final response = await _makeRequest(() => _client.get(
        Uri.parse(url),
        headers: _getHeaders(),
      ));

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

  // 메시지 삭제
  static Future<Map<String, dynamic>> deleteMessage(int messageId, int userId) async {
    try {
      final response = await _makeRequest(() => _client.delete(
        Uri.parse('$baseUrl/api/chat/message/$messageId?userId=$userId'),
        headers: _getHeaders(),
      ));

      print('Delete Message Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Failed to delete message: HTTP ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Delete Message Error: $e');
      return {
        'success': false,
        'message': 'Delete error: $e'
      };
    }
  }

  // 연결 테스트
  static Future<bool> testConnection() async {
    try {
      print('=== 서버 연결 테스트 ===');
      final response = await _makeRequest(() => _client.get(
        Uri.parse('$baseUrl/api/test'),
        headers: _getHeaders(),
      ));

      print('Test connection status: ${response.statusCode}');
      print('Test connection response: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      print('Connection test failed: $e');
      return false;
    }
  }

  // 리소스 정리
  static void dispose() {
    _client.close();
  }
}