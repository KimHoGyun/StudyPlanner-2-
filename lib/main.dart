import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config/api_config.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Study Planner',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isSignup = false;
  bool _isLoading = false;

  Future<void> _handleSubmit() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final endpoint = _isSignup ? ApiConfig.signup : ApiConfig.login;
      final body = _isSignup
          ? {
        'email': _emailController.text,
        'password': _passwordController.text,
        'name': _nameController.text,
      }
          : {
        'email': _emailController.text,
        'password': _passwordController.text,
      };

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}$endpoint'),
        headers: ApiConfig.getHeaders(),
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        if (!_isSignup) {
          // 로그인 성공 - 메인 화면으로 이동
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MainScreen(
                user: data['user'],
                token: data['token'],
              ),
            ),
          );
        } else {
          // 회원가입 성공 - 로그인 화면으로 전환
          setState(() {
            _isSignup = false;
            _emailController.clear();
            _passwordController.clear();
            _nameController.clear();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('회원가입 성공! 로그인해주세요.')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? '오류가 발생했습니다.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('서버 연결 실패: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade400, Colors.purple.shade400],
          ),
        ),
        child: Center(
          child: Card(
            margin: const EdgeInsets.all(20),
            elevation: 8,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.school,
                    size: 64,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isSignup ? '회원가입' : '로그인',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 32),
                  if (_isSignup)
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: '이름',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  if (_isSignup) const SizedBox(height: 16),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: '이메일',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: '비밀번호',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(_isSignup ? '가입하기' : '로그인'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isSignup = !_isSignup;
                        _emailController.clear();
                        _passwordController.clear();
                        _nameController.clear();
                      });
                    },
                    child: Text(
                      _isSignup
                          ? '이미 계정이 있으신가요? 로그인'
                          : '계정이 없으신가요? 회원가입',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final String token;

  const MainScreen({Key? key, required this.user, required this.token})
      : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      StudyGroupsPage(token: widget.token, userId: widget.user['id']),
      AttendancePage(token: widget.token, userId: widget.user['id']),
      ProfilePage(user: widget.user),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Planner'),
        elevation: 2,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.groups),
            label: '스터디 그룹',
          ),
          NavigationDestination(
            icon: Icon(Icons.check_circle),
            label: '출석 체크',
          ),
          NavigationDestination(
            icon: Icon(Icons.person),
            label: '프로필',
          ),
        ],
      ),
    );
  }
}

class StudyGroupsPage extends StatefulWidget {
  final String token;
  final int userId;

  const StudyGroupsPage({Key? key, required this.token, required this.userId})
      : super(key: key);

  @override
  State<StudyGroupsPage> createState() => _StudyGroupsPageState();
}

class _StudyGroupsPageState extends State<StudyGroupsPage> {
  List<dynamic> studyGroups = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudyGroups();
  }

  Future<void> _loadStudyGroups() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.studyGroups}'),
        headers: ApiConfig.getHeaders(),
      );

      if (response.statusCode == 200) {
        setState(() {
          studyGroups = jsonDecode(response.body);
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error loading study groups: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadStudyGroups,
      child: studyGroups.isEmpty
          ? const Center(
        child: Text('스터디 그룹이 없습니다.\n새로운 그룹을 만들어보세요!',
            textAlign: TextAlign.center),
      )
          : ListView.builder(
        itemCount: studyGroups.length,
        padding: const EdgeInsets.all(8),
        itemBuilder: (context, index) {
          final group = studyGroups[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor,
                child: Text(
                  group['name']?.substring(0, 1).toUpperCase() ?? 'S',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(group['name'] ?? 'Unknown'),
              subtitle: Text(
                '${group['description'] ?? 'No description'}\n'
                    '멤버: ${group['memberCount'] ?? 0}/${group['maxMembers'] ?? 50}',
              ),
              isThreeLine: true,
              trailing: IconButton(
                icon: const Icon(Icons.arrow_forward_ios),
                onPressed: () {
                  // 상세 페이지로 이동
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class AttendancePage extends StatelessWidget {
  final String token;
  final int userId;

  const AttendancePage({Key? key, required this.token, required this.userId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 100,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 16),
          const Text(
            '출석 체크 기능',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('준비 중입니다'),
        ],
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  final Map<String, dynamic> user;

  const ProfilePage({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 32),
          CircleAvatar(
            radius: 50,
            backgroundColor: Theme.of(context).primaryColor,
            child: Text(
              user['name']?.substring(0, 1).toUpperCase() ?? 'U',
              style: const TextStyle(fontSize: 36, color: Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user['name'] ?? 'Unknown User',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            user['email'] ?? 'No email',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 32),
          Card(
            child: ListTile(
              leading: const Icon(Icons.email),
              title: const Text('이메일'),
              subtitle: Text(user['email'] ?? 'No email'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('가입일'),
              subtitle: Text(user['createdAt'] ?? 'Unknown'),
            ),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            icon: const Icon(Icons.logout),
            label: const Text('로그아웃'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ),
    );
  }
}