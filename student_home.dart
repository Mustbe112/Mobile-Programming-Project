// lib/screens/student_home.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api.dart';
import 'login_page.dart';

class StudentHome extends StatefulWidget {
  final String id;
  const StudentHome({super.key, required this.id});
  @override
  State<StudentHome> createState() => _StudentHomeState();
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
        if (mounted)
          setState(
            () => {
              profile = data['profile'] ?? {},
              courses = data['courses'] ?? [],
            },
          );
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
      final res = await Api.post('/student/enroll', {
        'student_id': widget.id,
        'course_id': cid,
        'course_name': cname,
      });
      if (res.statusCode == 200) {
        enrollCourseId.clear();
        enrollCourseName.clear();
        _loadProfile();
        _show('Enrolled');
      } else
        _show(res.body);
    } catch (e) {
      _show('Network error');
    }
  }

  Future<void> _unenroll(String cid) async {
    try {
      final res = await Api.post('/student/unenroll', {
        'student_id': widget.id,
        'course_id': cid,
      });
      if (res.statusCode == 200) {
        _show('Unenrolled');
        _loadProfile();
      } else
        _show(res.body);
    } catch (e) {
      _show('Network error');
    }
  }

  Future<void> _submitAttendance() async {
    final cid = attendanceCourseId.text.trim();
    final code = attendanceCode.text.trim();
    if (cid.isEmpty || code.isEmpty) return _show('fill course & code');
    try {
      final res = await Api.post('/attendance/submit', {
        'student_id': widget.id,
        'course_id': cid,
        'code': code,
      });
      if (res.statusCode == 200)
        _show('Attendance submitted');
      else {
        final err = res.body.isNotEmpty
            ? jsonDecode(res.body)['error'] ?? res.body
            : 'Error';
        _show(err);
      }
    } catch (e) {
      _show('Network error');
    }
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

  void _show(String s) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));

  @override
  Widget build(BuildContext context) {
    final pages = [_profileTab(), _qrTab(), _attendanceTab(), _emergencyTab()];
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F0),
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2C3E2E),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: index,
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFF2C3E2E),
          selectedItemColor: const Color(0xFFD4A574),
          unselectedItemColor: const Color(0xFF9BA89C),
          elevation: 0,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline, size: 26),
              activeIcon: Icon(Icons.person, size: 26),
              label: 'Profile',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_2_outlined, size: 26),
              activeIcon: Icon(Icons.qr_code_2, size: 26),
              label: 'QR',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.check_circle_outline, size: 26),
              activeIcon: Icon(Icons.check_circle, size: 26),
              label: 'Attendance',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.emergency_outlined, size: 26),
              activeIcon: Icon(Icons.emergency, size: 26),
              label: 'Emergency',
            ),
          ],
          onTap: (i) => setState(() => index = i),
        ),
      ),
    );
  }

  Widget _profileTab() => Container(
    color: const Color(0xFFFAF7F0),
    child: RefreshIndicator(
      onRefresh: () async => _loadProfile(),
      child: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF3D4F3F),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'My Profile',
                style: TextStyle(
                  color: Color(0xFFFAF7F0),
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF3D4F3F), Color(0xFF2C3E2E)],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout, color: Color(0xFFFAF7F0)),
                onPressed: _logout,
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Profile Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C3E2E),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Profile Photo
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF3D4F3F),
                            border: Border.all(
                              color: const Color(0xFFD4A574),
                              width: 3,
                            ),
                          ),
                          child:
                              profile['photo_url'] != null &&
                                  (profile['photo_url'] as String).isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(50),
                                  child: Image.network(
                                    profile['photo_url'],
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.person,
                                      size: 50,
                                      color: Color(0xFF9BA89C),
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Color(0xFF9BA89C),
                                ),
                        ),
                        const SizedBox(height: 16),
                        // Name
                        Text(
                          profile['name'] ?? 'N/A',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFAF7F0),
                          ),
                        ),
                        const SizedBox(height: 4),
                        // ID
                        Text(
                          'ID: ${profile['id'] ?? widget.id}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFFD4A574),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Divider(color: const Color(0xFF3D4F3F)),
                        const SizedBox(height: 16),
                        // Info Rows
                        _buildModernInfoRow(
                          Icons.school,
                          'Department',
                          profile['department'] ?? 'N/A',
                        ),
                        const SizedBox(height: 12),
                        _buildModernInfoRow(
                          Icons.book,
                          'Major',
                          profile['major'] ?? 'N/A',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Enrolled Courses Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'My Courses',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E2E),
                        ),
                      ),
                      Text(
                        '${courses.length} enrolled',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF3D4F3F),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (courses.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C3E2E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.school_outlined,
                            size: 48,
                            color: const Color(0xFF3D4F3F),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No courses enrolled yet',
                            style: TextStyle(
                              color: Color(0xFF9BA89C),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...courses.map(
                      (c) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C3E2E),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFD4A574).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.book,
                              color: Color(0xFFD4A574),
                              size: 24,
                            ),
                          ),
                          title: Text(
                            c['course_name'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: Color(0xFFFAF7F0),
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              c['course_id'] ?? '',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF9BA89C),
                              ),
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Color(0xFFD98B8B),
                              size: 20,
                            ),
                            onPressed: () => _unenroll(c['course_id']),
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Enroll Section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C3E2E),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Enroll in New Course',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFAF7F0),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: enrollCourseId,
                          style: const TextStyle(color: Color(0xFFFAF7F0)),
                          decoration: InputDecoration(
                            labelText: 'Course ID',
                            labelStyle: const TextStyle(
                              color: Color(0xFF9BA89C),
                            ),
                            prefixIcon: const Icon(
                              Icons.tag,
                              size: 20,
                              color: Color(0xFFD4A574),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFF3D4F3F),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFF3D4F3F),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFFD4A574),
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: const Color(0xFF3D4F3F),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: enrollCourseName,
                          style: const TextStyle(color: Color(0xFFFAF7F0)),
                          decoration: InputDecoration(
                            labelText: 'Course Name',
                            labelStyle: const TextStyle(
                              color: Color(0xFF9BA89C),
                            ),
                            prefixIcon: const Icon(
                              Icons.school,
                              size: 20,
                              color: Color(0xFFD4A574),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFF3D4F3F),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFF3D4F3F),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFFD4A574),
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: const Color(0xFF3D4F3F),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _enroll,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD4A574),
                              foregroundColor: const Color(0xFF2C3E2E),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Enroll Course',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildModernInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFD4A574).withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFFD4A574)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9BA89C),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFFFAF7F0),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _qrTab() {
    final payload = jsonEncode({
      'id': profile['id'] ?? widget.id,
      'name': profile['name'] ?? '',
      'major': profile['major'] ?? '',
      'department': profile['department'] ?? '',
    });
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF3D4F3F), Color(0xFF2C3E2E)],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Header
            const Text(
              'Student QR Code',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFAF7F0),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              profile['name'] ?? 'N/A',
              style: const TextStyle(fontSize: 16, color: Color(0xFFD4A574)),
            ),
            const SizedBox(height: 40),
            // QR Code Container
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF7F0),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  QrImageView(
                    data: payload,
                    size: 250,
                    backgroundColor: const Color(0xFFFAF7F0),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'ID: ${profile['id'] ?? widget.id}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C3E2E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Scan for identification',
                    style: TextStyle(fontSize: 13, color: Color(0xFF3D4F3F)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            // Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Text(
                'This QR code contains your student information including ID, name, major, and department',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: const Color(0xFFFAF7F0).withOpacity(0.8),
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _attendanceTab() {
    return Container(
      color: const Color(0xFFFAF7F0),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 100,
              floating: false,
              pinned: true,
              backgroundColor: const Color(0xFF3D4F3F),
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'Attendance',
                  style: TextStyle(
                    color: Color(0xFFFAF7F0),
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF3D4F3F), Color(0xFF2C3E2E)],
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // Icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4A574).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_outline,
                        color: Color(0xFFD4A574),
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Submit Your Attendance',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E2E),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Enter the code provided by your lecturer',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Color(0xFF3D4F3F)),
                    ),
                    const SizedBox(height: 32),
                    // Form Container
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C3E2E),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: attendanceCourseId,
                            style: const TextStyle(color: Color(0xFFFAF7F0)),
                            decoration: InputDecoration(
                              labelText: 'Course ID',
                              labelStyle: const TextStyle(
                                color: Color(0xFF9BA89C),
                              ),
                              prefixIcon: const Icon(
                                Icons.book,
                                size: 20,
                                color: Color(0xFFD4A574),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: Color(0xFF3D4F3F),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: Color(0xFF3D4F3F),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: Color(0xFFD4A574),
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: const Color(0xFF3D4F3F),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: attendanceCode,
                            style: const TextStyle(color: Color(0xFFFAF7F0)),
                            decoration: InputDecoration(
                              labelText: 'Attendance Code',
                              labelStyle: const TextStyle(
                                color: Color(0xFF9BA89C),
                              ),
                              prefixIcon: const Icon(
                                Icons.confirmation_number,
                                size: 20,
                                color: Color(0xFFD4A574),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: Color(0xFF3D4F3F),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: Color(0xFF3D4F3F),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: Color(0xFFD4A574),
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: const Color(0xFF3D4F3F),
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _submitAttendance,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFD4A574),
                                foregroundColor: const Color(0xFF2C3E2E),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                'Submit Attendance',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emergencyTab() {
    return Container(
      color: const Color(0xFFFAF7F0),
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 100,
            floating: false,
            pinned: true,
            backgroundColor: const Color.fromARGB(255, 61, 79, 63),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Emergency',
                style: TextStyle(
                  color: Color(0xFFFAF7F0),
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.fromARGB(255, 61, 79, 63),
                      Color.fromARGB(255, 61, 79, 63),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    'University Contacts',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E2E),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildModernEmergencyContact(
                    'Campus Security',
                    '+66 xxx xxx xxx',
                    Icons.security,
                    const Color.fromARGB(255, 212, 165, 116),
                  ),
                  _buildModernEmergencyContact(
                    'Medical Unit',
                    '+66 xxx xxx xxx',
                    Icons.local_hospital,
                    const Color.fromARGB(255, 212, 165, 116),
                  ),
                  _buildModernEmergencyContact(
                    'Fire & Safety',
                    '+66 xxx xxx xxx',
                    Icons.fire_extinguisher,
                    const Color.fromARGB(255, 212, 165, 116),
                  ),
                  _buildModernEmergencyContact(
                    'Student Support',
                    '+66 xxx xxx xxx',
                    Icons.psychology,
                    const Color(0xFFD4A574),
                  ),
                  _buildModernEmergencyContact(
                    'IT Support',
                    '+66 xxx xxx xxx',
                    Icons.computer,
                    const Color(0xFFD4A574),
                  ),
                  const SizedBox(height: 16),
                  // Email Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C3E2E),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4A574).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.email,
                            color: Color(0xFFD4A574),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Email Support',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: Color(0xFFFAF7F0),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'helpdesk@youruniversity.edu',
                                style: TextStyle(
                                  color: Color(0xFF9BA89C),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernEmergencyContact(
    String title,
    String phone,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2C3E2E),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: Color(0xFFFAF7F0),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            phone,
            style: const TextStyle(color: Color(0xFF9BA89C), fontSize: 13),
          ),
        ),
        trailing: IconButton(
          icon: Icon(Icons.phone, color: color, size: 22),
          onPressed: () {
            final url = Uri.parse('tel:$phone');
            launchUrl(url);
          },
        ),
      ),
    );
  }
}
