// lib/screens/student_home.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api.dart';
import 'login_page.dart';

class StudentHome extends StatefulWidget {
  final String id;
  const StudentHome({super.key, required this.id});
  @override State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {
  int index = 0;
  Map profile = {};
  List courses = [];
  final enrollCourseId = TextEditingController();
  final enrollCourseName = TextEditingController();
  final attendanceCourseId = TextEditingController();
  final attendanceCode = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final res = await Api.get('/student/profile/${widget.id}');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) setState(()=> { profile = data['profile'] ?? {}, courses = data['courses'] ?? [] });
      } else {
        _show('Failed to load');
      }
    } catch (e) {
      _show('Network error');
    }
  }

  Future<void> _enroll() async {
    final cid = enrollCourseId.text.trim();
    final cname = enrollCourseName.text.trim();
    if (cid.isEmpty || cname.isEmpty) return _show('fill course id & name');
    try {
      final res = await Api.post('/student/enroll', {'student_id': widget.id, 'course_id': cid, 'course_name': cname});
      if (res.statusCode == 200) {
        enrollCourseId.clear(); enrollCourseName.clear();
        _loadProfile(); _show('Enrolled');
      } else _show(res.body);
    } catch (e) {
      _show('Network error');
    }
  }

  Future<void> _unenroll(String cid) async {
    try {
      final res = await Api.post('/student/unenroll', {'student_id': widget.id, 'course_id': cid});
      if (res.statusCode == 200) { _show('Unenrolled'); _loadProfile(); } else _show(res.body);
    } catch (e) { _show('Network error'); }
  }

  Future<void> _submitAttendance() async {
    final cid = attendanceCourseId.text.trim();
    final code = attendanceCode.text.trim();
    if (cid.isEmpty || code.isEmpty) return _show('fill course & code');
    try {
      final res = await Api.post('/attendance/submit', {'student_id': widget.id, 'course_id': cid, 'code': code});
      if (res.statusCode == 200) _show('Attendance submitted');
      else {
        final err = res.body.isNotEmpty ? jsonDecode(res.body)['error'] ?? res.body : 'Error';
        _show(err);
      }
    } catch (e) { _show('Network error'); }
  }

  Future<void> _logout() async {
    final sp = await SharedPreferences.getInstance();
    await sp.clear();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
}


  void _show(String s) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));

  @override
  Widget build(BuildContext context) {
    final tabs = ['Profile','QR','Attendance'];
    final pages = [_profileTab(), _qrTab(), _attendanceTab()];
    return Scaffold(
      appBar: AppBar(title: Text('Student — ${profile['name'] ?? widget.id}'), actions: [IconButton(icon: const Icon(Icons.logout), onPressed: _logout)]),
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: BottomNavigationBar(currentIndex: index, items: tabs.map((t)=>BottomNavigationBarItem(icon: const Icon(Icons.circle), label: t)).toList(), onTap: (i)=>setState(()=>index=i)),
    );
  }

  Widget _profileTab() => RefreshIndicator(
    onRefresh: () async => _loadProfile(),
    child: ListView(padding: const EdgeInsets.all(16), children: [
      Center(child: Column(children: [
        profile['photo_url'] != null && (profile['photo_url'] as String).isNotEmpty
            ? Image.network(profile['photo_url'], height: 100, width: 100, errorBuilder: (_,__,___)=>const Icon(Icons.person, size:100))
            : const Icon(Icons.person, size: 100),
        const SizedBox(height:8),
        Text(profile['name'] ?? '', style: const TextStyle(fontSize:18,fontWeight: FontWeight.bold)),
        Text('ID: ${profile['id'] ?? ''}'),
        Text('Major: ${profile['major'] ?? ''}'),
        Text('Department: ${profile['department'] ?? ''}'),
        const SizedBox(height: 12),
        const Text('Enrolled courses', style: TextStyle(fontWeight: FontWeight.bold)),
        ...courses.map((c) => ListTile(
          title: Text(c['course_name'] ?? ''),
          subtitle: Text(c['course_id'] ?? ''),
          trailing: IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: ()=>_unenroll(c['course_id'])),
        )),
        const Divider(),
        TextField(controller: enrollCourseId, decoration: const InputDecoration(labelText: 'Course id')),
        TextField(controller: enrollCourseName, decoration: const InputDecoration(labelText: 'Course name')),
        const SizedBox(height:8),
        ElevatedButton(onPressed: _enroll, child: const Text('Enroll'))
      ]))
    ]),
  );

  Widget _qrTab(){
    final payload = jsonEncode({'id': profile['id'] ?? widget.id, 'name': profile['name'] ?? '', 'major': profile['major'] ?? '', 'department': profile['department'] ?? ''});
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [QrImageView(data: payload, size: 220), const SizedBox(height:12), const Text('This QR contains your id, name, major, department')]));
  }

  Widget _attendanceTab() => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(children: [
      TextField(controller: attendanceCourseId, decoration: const InputDecoration(labelText: 'Course id')),
      TextField(controller: attendanceCode, decoration: const InputDecoration(labelText: 'Attendance code (from lecturer)')),
      const SizedBox(height:12),
      ElevatedButton(onPressed: _submitAttendance, child: const Text('Submit Attendance')),
      const SizedBox(height:10),
      const Text('Today\'s date will be used to prevent duplicate submissions')
    ]),
  );
}
