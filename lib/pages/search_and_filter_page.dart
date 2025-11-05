import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';

class SearchAndFilterPage extends StatefulWidget {
  final String token;
  final int userId;

  const SearchAndFilterPage({
    Key? key,
    required this.token,
    required this.userId
  }) : super(key: key);

  @override
  State<SearchAndFilterPage> createState() => _SearchAndFilterPageState();
}

class _SearchAndFilterPageState extends State<SearchAndFilterPage> {
  final _searchController = TextEditingController();
  List<dynamic> searchResults = [];
  List<dynamic> allGroups = [];
  bool isLoading = false;
  bool showFilters = false;

  // 필터 옵션들
  String selectedSortBy = 'name';
  bool sortAscending = true;
  int? maxMembersFilter;
  bool showActiveOnly = true;

  @override
  void initState() {
    super.initState();
    _loadAllGroups();
  }

  Future<void> _loadAllGroups() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.studyGroups}'),
        headers: ApiConfig.getHeaders(),
      );

      if (response.statusCode == 200) {
        setState(() {
          allGroups = jsonDecode(response.body);
          searchResults = List.from(allGroups);
          _applyFiltersAndSort();
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error loading groups: $e');
    }
  }

  Future<void> _searchGroups(String query) async {
    if (query.isEmpty) {
      setState(() {
        searchResults = List.from(allGroups);
        _applyFiltersAndSort();
      });
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.studyGroups}/search?query=${Uri.encodeComponent(query)}'),
        headers: ApiConfig.getHeaders(),
      );

      if (response.statusCode == 200) {
        setState(() {
          searchResults = jsonDecode(response.body);
          _applyFiltersAndSort();
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error searching groups: $e');
    }
  }

  void _applyFiltersAndSort() {
    List<dynamic> filtered = List.from(searchResults);

    // 활성 그룹만 보기 필터
    if (showActiveOnly) {
      filtered = filtered.where((group) => group['isActive'] == true).toList();
    }

    // 최대 멤버 수 필터
    if (maxMembersFilter != null) {
      filtered = filtered.where((group) {
        final memberCount = group['memberCount'] ?? 0;
        return memberCount <= maxMembersFilter!;
      }).toList();
    }

    // 정렬
    filtered.sort((a, b) {
      int comparison = 0;

      switch (selectedSortBy) {
        case 'name':
          comparison = (a['name'] ?? '').toString().toLowerCase()
              .compareTo((b['name'] ?? '').toString().toLowerCase());
          break;
        case 'memberCount':
          comparison = (a['memberCount'] ?? 0).compareTo(b['memberCount'] ?? 0);
          break;
        case 'createdAt':
          final dateA = DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime.now();
          final dateB = DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime.now();
          comparison = dateA.compareTo(dateB);
          break;
        default:
          comparison = 0;
      }

      return sortAscending ? comparison : -comparison;
    });

    setState(() {
      searchResults = filtered;
    });
  }

  Future<void> _joinStudyGroup(int studyGroupId) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.studyGroups}/$studyGroupId/join'),
        headers: ApiConfig.getHeaders(),
        body: jsonEncode({'userId': widget.userId}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('스터디 그룹에 참여했습니다!')),
        );
        _loadAllGroups(); // 목록 새로고침
      } else {
        final errorData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorData['error'] ?? '참여 실패')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('스터디 그룹 검색'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(showFilters ? Icons.filter_list_off : Icons.filter_list),
            onPressed: () {
              setState(() {
                showFilters = !showFilters;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 검색창
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '스터디 그룹 이름으로 검색...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _searchGroups('');
                  },
                )
                    : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: _searchGroups,
            ),
          ),

          // 필터 패널
          if (showFilters) _buildFilterPanel(),

          // 결과 카운트
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '검색 결과: ${searchResults.length}개',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  '정렬: ${_getSortDisplayName()} ${sortAscending ? '↑' : '↓'}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),

          const Divider(),

          // 검색 결과 목록
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : searchResults.isEmpty
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    '검색 결과가 없습니다',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '다른 키워드로 검색해보세요',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh: _loadAllGroups,
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: searchResults.length,
                itemBuilder: (context, index) {
                  final group = searchResults[index];
                  return _buildGroupCard(group);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPanel() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.tune, size: 20),
                const SizedBox(width: 8),
                Text(
                  '필터 및 정렬',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 정렬 옵션
            Row(
              children: [
                const Text('정렬: '),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
                    value: selectedSortBy,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'name', child: Text('이름순')),
                      DropdownMenuItem(value: 'memberCount', child: Text('멤버 수')),
                      DropdownMenuItem(value: 'createdAt', child: Text('생성일')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedSortBy = value;
                          _applyFiltersAndSort();
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(sortAscending ? Icons.arrow_upward : Icons.arrow_downward),
                  onPressed: () {
                    setState(() {
                      sortAscending = !sortAscending;
                      _applyFiltersAndSort();
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 활성 그룹만 보기
            CheckboxListTile(
              title: const Text('활성 그룹만 보기'),
              value: showActiveOnly,
              onChanged: (value) {
                setState(() {
                  showActiveOnly = value ?? true;
                  _applyFiltersAndSort();
                });
              },
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
            ),

            // 최대 멤버 수 필터
            Row(
              children: [
                const Text('최대 멤버 수: '),
                const SizedBox(width: 8),
                Expanded(
                  child: Slider(
                    value: (maxMembersFilter ?? 50).toDouble(),
                    min: 1,
                    max: 50,
                    divisions: 49,
                    label: maxMembersFilter?.toString() ?? '제한 없음',
                    onChanged: (value) {
                      setState(() {
                        maxMembersFilter = value.toInt();
                        _applyFiltersAndSort();
                      });
                    },
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      maxMembersFilter = null;
                      _applyFiltersAndSort();
                    });
                  },
                  child: const Text('초기화'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupCard(Map<String, dynamic> group) {
    final memberCount = group['memberCount'] ?? 0;
    final maxMembers = group['maxMembers'] ?? 50;
    final isActive = group['isActive'] ?? false;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StudyGroupDetailPage(
                studyGroup: group,
                token: widget.token,
                userId: widget.userId,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: isActive ? Theme.of(context).primaryColor : Colors.grey,
                    child: Text(
                      group['name']?.substring(0, 1).toUpperCase() ?? 'S',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                group['name'] ?? 'Unknown',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!isActive)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  '비활성',
                                  style: TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          group['description'] ?? 'No description',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.people, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text('$memberCount/$maxMembers'),
                      const SizedBox(width: 16),
                      Icon(Icons.person, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        group['creator']?['name'] ?? 'Unknown',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (isActive && memberCount < maxMembers)
                        ElevatedButton.icon(
                          onPressed: () => _joinStudyGroup(group['id']),
                          icon: const Icon(Icons.group_add, size: 16),
                          label: const Text('참여'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios, size: 16),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => StudyGroupDetailPage(
                                studyGroup: group,
                                token: widget.token,
                                userId: widget.userId,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getSortDisplayName() {
    switch (selectedSortBy) {
      case 'name':
        return '이름';
      case 'memberCount':
        return '멤버 수';
      case 'createdAt':
        return '생성일';
      default:
        return '이름';
    }
  }
}

// StudyGroupDetailPage는 main.dart에서 이미 정의됨
class StudyGroupDetailPage extends StatelessWidget {
  final Map<String, dynamic> studyGroup;
  final String token;
  final int userId;

  const StudyGroupDetailPage({
    Key? key,
    required this.studyGroup,
    required this.token,
    required this.userId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(studyGroup['name'] ?? 'Study Group'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Study Group Detail Page'),
      ),
    );
  }
}