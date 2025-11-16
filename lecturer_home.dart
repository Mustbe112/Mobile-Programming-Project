// lib/screens/lecturer_home.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api.dart';
import '../services/api.dart'; // contains API_BASE
import 'login_page.dart';

class LecturerHome extends StatefulWidget {
  final String id;
  const LecturerHome({super.key, required this.id});

  @override
  State<LecturerHome> createState() => _LecturerHomeState();
}

class _LecturerHomeState extends State<LecturerHome> {
  int index = 0;
  Map profile = {};
  List courses = [];

  final addCourseId = TextEditingController();
  final addCourseName = TextEditingController();
  final genCourseId = TextEditingController();
  String lastGenerated = '';
  final viewCourseId = TextEditingController();
  final viewDate = TextEditingController();
  List attendanceRows = [];
  int total = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final res = await Api.get('/lecturer/profile/${widget.id}');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (!mounted) return;
        setState(() {
          profile = data['profile'] ?? {};
          courses = data['courses'] ?? [];
        });
      } else {
        _show('Failed to load profile');
      }
    } catch (e) {
      _show('Network error');
    }
  }

  Future<void> _addCourse() async {
    final cid = addCourseId.text.trim();
    final cname = addCourseName.text.trim();
    if (cid.isEmpty || cname.isEmpty) return _show('Fill all fields');

    try {
      final res = await Api.post('/lecturer/add-course', {
        'lecturer_id': widget.id,
        'course_id': cid,
        'course_name': cname
      });

      if (res.statusCode == 200) {
        addCourseId.clear();
        addCourseName.clear();
        await _loadProfile();
        _show('Course added');
      } else {
        _show('Error: ${res.body}');
      }
    } catch (e) {
      _show('Network error');
    }
  }

  Future<void> _deleteCourse(String cid) async {
    try {
      final res = await Api.post('/lecturer/delete-course', {
        'lecturer_id': widget.id,
        'course_id': cid
      });

      if (res.statusCode == 200) {
        await _loadProfile();
        _show('Deleted');
      } else {
        _show('Error: ${res.body}');
      }
    } catch (e) {
      _show('Network error');
    }
  }

  Future<void> _generateCode() async {
    final cid = genCourseId.text.trim();
    if (cid.isEmpty) return _show('Enter course ID');

    try {
      final res =
          await Api.post('/attendance/generate', {'lecturer_id': widget.id, 'course_id': cid});

      if (res.statusCode == 200) {
        final d = jsonDecode(res.body);
        setState(() => lastGenerated = d['code'] ?? '');
        _show('Code generated: $lastGenerated');
      } else {
        _show('Error generating code');
      }
    } catch (e) {
      _show('Network error');
    }
  }

  Future<void> _viewAttendance() async {
    final cid = viewCourseId.text.trim();
    final date = viewDate.text.trim();
    if (cid.isEmpty || date.isEmpty) return _show('Fill all fields');

    try {
      final res = await Api.get('/attendance/view?course_id=$cid&date=$date');
      if (res.statusCode == 200) {
        final d = jsonDecode(res.body);
        setState(() {
          attendanceRows = d['rows'] ?? [];
          total = d['total'] ?? attendanceRows.length;
        });
      } else {
        _show('Error loading attendance');
      }
    } catch (e) {
      _show('Network error');
    }
  }

  Future<void> _exportExcel() async {
    final cid = viewCourseId.text.trim();
    final date = viewDate.text.trim();
    if (cid.isEmpty || date.isEmpty) return _show('Fill all fields');

    final url = Uri.parse(
        '$API_BASE/attendance/export?course_id=$cid&date=$date');

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        _show('Cannot launch export link');
      }
    } catch (e) {
      _show('Could not open URL');
    }
  }

  Future<void> _logout() async {
    final sp = await SharedPreferences.getInstance();
    await sp.clear();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false);
  }

  void _show(String s) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _profileTab(),
      _qrTab(),
      _genTab(),
      _viewTab()
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Lecturer — ${profile['name'] ?? widget.id}'),
        actions: [
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout))
        ],
      ),
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (i) => setState(() => index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.qr_code), label: 'QR'),
          BottomNavigationBarItem(icon: Icon(Icons.lock_clock), label: 'Generate'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'View'),
        ],
      ),
    );
  }

  // ------------------ TABS ------------------

  Widget _profileTab() => RefreshIndicator(
        onRefresh: _loadProfile,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: Column(
                children: [
                  profile['photo_url'] != null &&
                          (profile['photo_url'] as String).isNotEmpty
                      ? CircleAvatar(
                          radius: 50,
                          backgroundImage: NetworkImage(profile['photo_url']),
                        )
                      : const CircleAvatar(
                          radius: 50,
                          child: Icon(Icons.person),
                        ),
                  const SizedBox(height: 10),
                  Text(profile['name'] ?? '',
                      style:
                          const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('ID: ${profile['id'] ?? ''}'),
                  Text('Department: ${profile['department'] ?? ''}'),
                  const SizedBox(height: 14),
                  const Text('Courses you teach',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  ...courses.map((c) => ListTile(
                        title: Text(c['course_name'] ?? ''),
                        subtitle: Text(c['course_id'] ?? ''),
                        trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteCourse(c['course_id'])),
                      )),
                  const Divider(),
                  TextField(
                      controller: addCourseId,
                      decoration:
                          const InputDecoration(labelText: 'New course ID')),
                  TextField(
                      controller: addCourseName,
                      decoration:
                          const InputDecoration(labelText: 'New course name')),
                  const SizedBox(height: 8),
                  ElevatedButton(
                      onPressed: _addCourse, child: const Text('Add Course'))
                ],
              ),
            )
          ],
        ),
      );

  Widget _qrTab() {
    final payload = jsonEncode({
      'id': profile['id'] ?? widget.id,
      'name': profile['name'] ?? '',
      'department': profile['department'] ?? ''
    });

    return Center(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        QrImageView(data: payload, size: 220),
        const SizedBox(height: 12),
        const Text('This QR contains lecturer id, name, department')
      ],
    ));
  }

  Widget _genTab() => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          TextField(
              controller: genCourseId,
              decoration: const InputDecoration(labelText: 'Course ID')),
          const SizedBox(height: 8),
          ElevatedButton(
              onPressed: _generateCode,
              child: const Text('Generate Attendance Code')),
          if (lastGenerated.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text('Last code: $lastGenerated',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            )
        ]),
      );

  Widget _viewTab() => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          TextField(
              controller: viewCourseId,
              decoration: const InputDecoration(labelText: 'Course ID')),
          TextField(
              controller: viewDate,
              decoration:
                  const InputDecoration(labelText: 'Date (YYYY-MM-DD)')),
          const SizedBox(height: 8),
          Row(children: [
            ElevatedButton(
                onPressed: _viewAttendance, child: const Text('View')),
            const SizedBox(width: 8),
            ElevatedButton(
                onPressed: _exportExcel, child: const Text('Export Excel')),
          ]),
          const SizedBox(height: 12),
          Text('Total: $total'),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
                children: attendanceRows
                    .map((r) => ListTile(
                          title: Text(r['student_name'] ?? ''),
                          subtitle: Text(
                              '${r['student_id'] ?? ''} — ${r['submitted_at'] ?? ''}'),
                        ))
                    .toList()),
          )
        ]),
      );
}
