/*import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl {
    // 웹 환경에서는 배포된 백엔드 URL 사용
    if (kIsWeb) {
      // TODO: 실제 백엔드 배포 URL로 변경
      // 예: 'https://your-backend.herokuapp.com'
      return 'http://studyplanner-production-0729.up.railway.app'; // 개발 중에는 로컬 사용
    }
    // 모바일 환경 (Android/iOS)
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080'; // Android 에뮬레이터
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'http://localhost:8080'; // iOS 시뮬레이터
    }
    return 'http://localhost:8080';
  }

  // API 엔드포인트
  static const String login = '/api/auth/login';
  static const String signup = '/api/auth/signup';
  static const String studyGroups = '/api/study-groups';
  static const String attendance = '/api/attendance';

  // 헤더 설정
  static Map<String, String> getHeaders({String? token}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }
}*/
import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl {
    // 웹 환경에서는 배포된 백엔드 URL 사용
    if (kIsWeb) {
      return 'http://studyplanner-production-0729.up.railway.app';
    }
    // 모바일 환경 (Android/iOS)
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080'; // Android 에뮬레이터
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'http://localhost:8080'; // iOS 시뮬레이터
    }
    return 'http://localhost:8080';
  }

  // API 엔드포인트
  static const String login = '/api/auth/login';
  static const String signup = '/api/auth/signup';
  static const String studyGroups = '/api/study-groups';
  static const String attendance = '/api/attendance';

  // 헤더 설정
  static Map<String, String> getHeaders({String? token}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }
}