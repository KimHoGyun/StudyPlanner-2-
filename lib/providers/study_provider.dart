import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/study_group.dart';

class StudyProvider with ChangeNotifier {
  List<StudyGroup> _studyGroups = [];
  bool _isLoading = false;

  List<StudyGroup> get studyGroups => _studyGroups;
  bool get isLoading => _isLoading;

  Future<void> loadStudyGroups() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.getStudyGroups();
      _studyGroups = response.map((json) => StudyGroup.fromJson(json)).toList();
    } catch (e) {
      print('Load study groups error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> searchStudyGroups(String query) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.searchStudyGroups(query);
      _studyGroups = response.map((json) => StudyGroup.fromJson(json)).toList();
    } catch (e) {
      print('Search study groups error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createStudyGroup(String name, String description, int creatorId) async {
    try {
      await ApiService.createStudyGroup(name, description, creatorId);
      await loadStudyGroups(); // Refresh the list
      return true;
    } catch (e) {
      print('Create study group error: $e');
      return false;
    }
  }
}