// lib/pages/advanced_attendance_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';

class AdvancedAttendancePage extends StatefulWidget {
  final Map<String, dynamic> studyGroup;
  final String token;
  final int userId;

  const AdvancedAttendancePage({
    Key? key,
    required this.studyGroup,
    required this.token,
    required this.userId,
  }) : super(key: key);

  @override
  State<AdvancedAttendancePage> createState() => _AdvancedAttendancePageState();
}

class _AdvancedAttendancePageState extends State<AdvancedAttendancePage> with TickerProviderStateMixin {
  late TabController _tabController;
  DateTime selectedDate = DateTime.now();
  List<dynamic> attendanceHistory = [];
  Map<String, dynamic> attendanceStats = {};
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAttendanceData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAttendanceData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // 사용자의 전체 출석 기록 로드
      final historyResponse = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.attendance}/user/${widget.userId}'),
        headers: ApiConfig.getHeaders(),
      );

      if (historyResponse.statusCode == 200) {
        attendanceHistory = jsonDecode(historyResponse.body);
        _calculateStats();
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error loading attendance data: $e');
    }
  }

  void _calculateStats() {
    final groupHistory = attendanceHistory
        .where((record) => record['studyGroup']?['id'] == widget.studyGroup['id'])
        .toList();

    final totalDays = groupHistory.length;
    final presentDays = groupHistory.where((record) => record['present'] == true).length;
    final absentDays = totalDays - presentDays;
    final attendanceRate = totalDays > 0 ? (presentDays / totalDays * 100).round() : 0;

    // 최근 7일 출석률
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final recentHistory = groupHistory.where((record) {
      final date = DateTime.tryParse(record['attendanceDate'] ?? '');
      return date != null && date.isAfter(weekAgo);
    }).toList();

    final recentTotal = recentHistory.length;
    final recentPresent = recentHistory.where((record) => record['present'] == true).length;
    final recentRate = recentTotal > 0 ? (recentPresent / recentTotal * 100).round() : 0;

    // 연속 출석일
    int streakDays = 0;
    final sortedHistory = List.from(groupHistory)
      ..sort((a, b) {
        final dateA = DateTime.tryParse(a['attendanceDate'] ?? '') ?? DateTime.now();
        final dateB = DateTime.tryParse(b['attendanceDate'] ?? '') ?? DateTime.now();
        return dateB.compareTo(dateA); // 최신순 정렬
      });

    for (final record in sortedHistory) {
      if (record['present'] == true) {
        streakDays++;
      } else {
        break;
      }
    }

    setState(() {
      attendanceStats = {
        'totalDays': totalDays,
        'presentDays': presentDays,
        'absentDays': absentDays,
        'attendanceRate': attendanceRate,
        'recentRate': recentRate,
        'streakDays': streakDays,
      };
    });
  }

  Future<void> _markAttendance(bool present) async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.attendance}'),
        headers: ApiConfig.getHeaders(),
        body: jsonEncode({
          'userId': widget.userId,
          'studyGroupId': widget.studyGroup['id'],
          'date': selectedDate.toIso8601String().split('T')[0],
          'present': present,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(present ? '출석 체크 완료!' : '결석 처리 완료!'),
            backgroundColor: present ? Colors.green : Colors.orange,
          ),
        );
        await _loadAttendanceData(); // 데이터 새로고침
      } else {
        final errorData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorData['error'] ?? '출석 체크 실패')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.studyGroup['name']} - 출석'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.check_circle), text: '출석 체크'),
            Tab(icon: Icon(Icons.analytics), text: '통계'),
            Tab(icon: Icon(Icons.history), text: '기록'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAttendanceTab(),
          _buildStatsTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildAttendanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 날짜 선택 카드
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        '출석 날짜 선택',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${selectedDate.year}년 ${selectedDate.month}월 ${selectedDate.day}일',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime.now().subtract(const Duration(days: 30)),
                              lastDate: DateTime.now().add(const Duration(days: 1)),
                              locale: const Locale('ko', 'KR'),
                            );
                            if (picked != null) {
                              setState(() {
                                selectedDate = picked;
                              });
                            }
                          },
                          icon: const Icon(Icons.edit_calendar),
                          label: const Text('변경'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 출석 상태 선택 카드
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.how_to_reg, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        '출석 상태 선택',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildAttendanceButton(
                          label: '출석',
                          icon: Icons.check_circle,
                          color: Colors.green,
                          onTap: () => _markAttendance(true),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildAttendanceButton(
                          label: '결석',
                          icon: Icons.cancel,
                          color: Colors.orange,
                          onTap: () => _markAttendance(false),
                        ),
                      ),
                    ],
                  ),
                  if (isLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: CircularProgressIndicator(),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 빠른 통계 카드
          if (attendanceStats.isNotEmpty)
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.trending_up, color: Colors.purple),
                        const SizedBox(width: 8),
                        Text(
                          '빠른 통계',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildQuickStat(
                          '출석률',
                          '${attendanceStats['attendanceRate']}%',
                          Icons.pie_chart,
                          Colors.blue,
                        ),
                        _buildQuickStat(
                          '연속 출석',
                          '${attendanceStats['streakDays']}일',
                          Icons.local_fire_department,
                          Colors.orange,
                        ),
                        _buildQuickStat(
                          '총 출석',
                          '${attendanceStats['presentDays']}일',
                          Icons.event_available,
                          Colors.green,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),

          // 안내 메시지
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '출석 체크는 하루에 한 번만 가능합니다.\n기존 기록이 있는 경우 업데이트됩니다.',
                      style: TextStyle(color: Colors.blue.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color),
        ),
        child: Column(
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsTab() {
    if (attendanceStats.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              '통계 데이터가 없습니다',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              '출석 체크를 시작해보세요!',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 전체 출석률 카드
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    '전체 출석률',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: CircularProgressIndicator(
                          value: attendanceStats['attendanceRate'] / 100,
                          strokeWidth: 12,
                          backgroundColor: Colors.grey.shade300,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            attendanceStats['attendanceRate'] >= 80
                                ? Colors.green
                                : attendanceStats['attendanceRate'] >= 60
                                ? Colors.orange
                                : Colors.red,
                          ),
                        ),
                      ),
                      Text(
                        '${attendanceStats['attendanceRate']}%',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('총 일수', '${attendanceStats['totalDays']}'),
                      _buildStatItem('출석', '${attendanceStats['presentDays']}'),
                      _buildStatItem('결석', '${attendanceStats['absentDays']}'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 상세 통계 카드들
          Row(
            children: [
              Expanded(
                child: Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(
                          Icons.local_fire_department,
                          size: 32,
                          color: Colors.orange.shade600,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${attendanceStats['streakDays']}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text('연속 출석일'),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(
                          Icons.trending_up,
                          size: 32,
                          color: Colors.blue.shade600,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${attendanceStats['recentRate']}%',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text('최근 7일'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 월별 출석 현황 (간단한 버전)
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '월별 출석 현황',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  _buildMonthlyChart(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyChart() {
    // 간단한 막대 차트 형태로 월별 출석률 표시
    final now = DateTime.now();
    final months = <String>[];
    final rates = <double>[];

    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthStr = '${month.month}월';
      months.add(monthStr);

      // 해당 월의 출석 기록 필터링
      final monthRecords = attendanceHistory.where((record) {
        final date = DateTime.tryParse(record['attendanceDate'] ?? '');
        return date != null &&
            date.year == month.year &&
            date.month == month.month &&
            record['studyGroup']?['id'] == widget.studyGroup['id'];
      }).toList();

      final totalDays = monthRecords.length;
      final presentDays = monthRecords.where((r) => r['present'] == true).length;
      final rate = totalDays > 0 ? presentDays / totalDays : 0.0;
      rates.add(rate);
    }

    return SizedBox(
      height: 200,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(months.length, (index) {
          final rate = rates[index];
          final height = (rate * 150).clamp(10.0, 150.0);

          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '${(rate * 100).round()}%',
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 4),
              Container(
                width: 30,
                height: height,
                decoration: BoxDecoration(
                  color: rate >= 0.8
                      ? Colors.green
                      : rate >= 0.6
                      ? Colors.orange
                      : Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                months[index],
                style: const TextStyle(fontSize: 12),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildHistoryTab() {
    final groupHistory = attendanceHistory
        .where((record) => record['studyGroup']?['id'] == widget.studyGroup['id'])
        .toList()
      ..sort((a, b) {
        final dateA = DateTime.tryParse(a['attendanceDate'] ?? '') ?? DateTime.now();
        final dateB = DateTime.tryParse(b['attendanceDate'] ?? '') ?? DateTime.now();
        return dateB.compareTo(dateA); // 최신순 정렬
      });

    if (groupHistory.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              '출석 기록이 없습니다',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              '첫 출석을 체크해보세요!',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAttendanceData,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: groupHistory.length,
        itemBuilder: (context, index) {
          final record = groupHistory[index];
          final isPresent = record['present'] == true;
          final date = DateTime.tryParse(record['attendanceDate'] ?? '');
          final formattedDate = date != null
              ? '${date.year}년 ${date.month}월 ${date.day}일'
              : 'Unknown Date';

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isPresent ? Colors.green : Colors.orange,
                child: Icon(
                  isPresent ? Icons.check : Icons.close,
                  color: Colors.white,
                ),
              ),
              title: Text(
                formattedDate,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                isPresent ? '출석' : '결석',
                style: TextStyle(
                  color: isPresent ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.w500,
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  _showEditAttendanceDialog(record, date);
                },
              ),
            ),
          );
        },
      ),
    );
  }

  void _showEditAttendanceDialog(Map<String, dynamic> record, DateTime? date) {
    if (date == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('출석 기록 수정 - ${date.month}/${date.day}'),
        content: Text('${date.year}년 ${date.month}월 ${date.day}일의 출석 상태를 변경하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _markAttendance(true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('출석으로 변경'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _markAttendance(false);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('결석으로 변경'),
          ),
        ],
      ),
    );
  }
}