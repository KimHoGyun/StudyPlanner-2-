// lib/services/api_service.dart (완전한 버전)
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // 배포된 백엔드 URL로 변경 (Railway 배포 후 받은 URL)
  static const String baseUrl = 'http://studyplanner-production-0729.up.railway.app/api';  // 로컬 테스트용
  // 배포 후: 'https://your-app-name.railway.app/api'

  // 로그인 API
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      print('Login Response Status: ${response.statusCode}');
      print('Login Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return {
          'success': responseData['success'] ?? false,
          'user': responseData['user'],
          'token': responseData['token'],
          'message': responseData['message'] ?? '',
        };
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Login Error: $e');
      return {
        'success': false,
        'message': 'Network error: $e'
      };
    }
  }

  // 회원가입 API
  static Future<Map<String, dynamic>> signup(String email, String password, String name) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/signup'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
          'name': name,
        }),
      );

      print('Signup Response Status: ${response.statusCode}');
      print('Signup Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return {
          'success': responseData['success'] ?? false,
          'message': responseData['message'] ?? 'Success',
        };
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Signup Error: $e');
      return {
        'success': false,
        'message': 'Network error: $e'
      };
    }
  }

  // 스터디 그룹 목록 조회 API
  static Future<List<dynamic>> getStudyGroups() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/study-groups'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('Get Study Groups Response Status: ${response.statusCode}');
      print('Get Study Groups Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return [];
      }
    } catch (e) {
      print('Get Study Groups Error: $e');
      return [];
    }
  }

  // 스터디 그룹 검색 API
  static Future<List<dynamic>> searchStudyGroups(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/study-groups/search?query=$query'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('Search Study Groups Response Status: ${response.statusCode}');
      print('Search Study Groups Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return [];
      }
    } catch (e) {
      print('Search Study Groups Error: $e');
      return [];
    }
  }

  // 스터디 그룹 생성 API
  static Future<Map<String, dynamic>> createStudyGroup(String name, String description, int creatorId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/study-groups'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'description': description,
          'creatorId': creatorId,
        }),
      );

      print('Create Study Group Response Status: ${response.statusCode}');
      print('Create Study Group Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Create Study Group Error: $e');
      return {
        'success': false,
        'message': 'Network error: $e'
      };
    }
  }

  // 스터디 그룹 참여 API
  static Future<String> joinStudyGroup(int studyGroupId, int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/study-groups/$studyGroupId/join'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'userId': userId,
        }),
      );

      print('Join Study Group Response Status: ${response.statusCode}');
      print('Join Study Group Response Body: ${response.body}');

      return response.body;
    } catch (e) {
      print('Join Study Group Error: $e');
      return 'Network error: $e';
    }
  }

  // 스터디 그룹 탈퇴 API
  static Future<String> leaveStudyGroup(int studyGroupId, int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/study-groups/$studyGroupId/leave'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'userId': userId,
        }),
      );

      print('Leave Study Group Response Status: ${response.statusCode}');
      print('Leave Study Group Response Body: ${response.body}');

      return response.body;
    } catch (e) {
      print('Leave Study Group Error: $e');
      return 'Network error: $e';
    }
  }

  // 출석 체크 API
  static Future<String> markAttendance(int userId, int studyGroupId, String date, bool present) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/attendance'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'userId': userId,
          'studyGroupId': studyGroupId,
          'date': date,
          'present': present,
        }),
      );

      print('Mark Attendance Response Status: ${response.statusCode}');
      print('Mark Attendance Response Body: ${response.body}');

      return response.body;
    } catch (e) {
      print('Mark Attendance Error: $e');
      return 'Network error: $e';
    }
  }

  // 출석 조회 API
  static Future<List<dynamic>> getAttendance(int studyGroupId, String date) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/attendance/$studyGroupId?date=$date'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('Get Attendance Response Status: ${response.statusCode}');
      print('Get Attendance Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return [];
      }
    } catch (e) {
      print('Get Attendance Error: $e');
      return [];
    }
  }

  // 사용자 출석 현황 조회 API
  static Future<List<dynamic>> getUserAttendance(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/attendance/user/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('Get User Attendance Response Status: ${response.statusCode}');
      print('Get User Attendance Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return [];
      }
    } catch (e) {
      print('Get User Attendance Error: $e');
      return [];
    }
  }
}