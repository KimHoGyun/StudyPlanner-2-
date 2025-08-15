import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/study_group.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'attendance_screen.dart';

class StudyDetailScreen extends StatefulWidget {
  final StudyGroup studyGroup;

  StudyDetailScreen({required this.studyGroup});

  @override
  _StudyDetailScreenState createState() => _StudyDetailScreenState();
}

class _StudyDetailScreenState extends State<StudyDetailScreen> {
  bool _isMember = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: Container(
          width: 400,
          height: 600,
          padding: EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 5,
                blurRadius: 7,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.arrow_back),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Study Detail',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 32),

              Text(
                widget.studyGroup.name,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 8),

              Text(
                widget.studyGroup.description,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),

              SizedBox(height: 32),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _handleJoinLeave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        _isMember ? 'Leave' : 'Join',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isMember ? null : _handleJoinLeave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isMember ? Colors.blue : Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Leave',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 32),

              ListTile(
                leading: Icon(Icons.announcement),
                title: Text('Announcements'),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // Navigate to announcements
                },
              ),

              Divider(),

              ListTile(
                leading: Icon(Icons.check_circle),
                title: Text('Attendance'),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AttendanceScreen(studyGroup: widget.studyGroup),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleJoinLeave() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      if (_isMember) {
        await ApiService.leaveStudyGroup(widget.studyGroup.id, authProvider.user!.id);
        setState(() {
          _isMember = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Left study group successfully')),
        );
      } else {
        await ApiService.joinStudyGroup(widget.studyGroup.id, authProvider.user!.id);
        setState(() {
          _isMember = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Joined study group successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Operation failed')),
      );
    }
  }
}
