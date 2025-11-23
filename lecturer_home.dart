// lib/screens/lecturer_home.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api.dart';
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
        'course_name': cname,
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
        'course_id': cid,
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
      final res = await Api.post('/attendance/generate', {
        'lecturer_id': widget.id,
        'course_id': cid,
      });

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

  void _show(String s) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(s),
        backgroundColor: const Color(0xFF2C3E2E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _callEmergencyContact(String phone) async {
    final url = Uri.parse('tel:$phone');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        _show('Cannot make call');
      }
    } catch (e) {
      _show('Error making call');
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _profileTab(),
      _qrTab(),
      _genTab(),
      _viewTab(),
      _emergencyTab(),
    ];

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
              icon: Icon(Icons.lock_clock_outlined, size: 26),
              activeIcon: Icon(Icons.lock_clock, size: 26),
              label: 'Generate',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assessment_outlined, size: 26),
              activeIcon: Icon(Icons.assessment, size: 26),
              label: 'View',
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

  // ------------------ TABS ------------------

  Widget _profileTab() => Container(
    color: const Color(0xFFFAF7F0),
    child: RefreshIndicator(
      onRefresh: _loadProfile,
      color: const Color(0xFFD4A574),
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
                          profile['name'] ?? 'Lecturer',
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
                        // Info Row
                        _buildModernInfoRow(
                          Icons.business,
                          'Department',
                          profile['department'] ?? 'N/A',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Courses Section
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
                        '${courses.length} courses',
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
                            'No courses added yet',
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
                            onPressed: () => _deleteCourse(c['course_id']),
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Add Course Section
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
                          'Add New Course',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFAF7F0),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: addCourseId,
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
                          controller: addCourseName,
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
                            onPressed: _addCourse,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD4A574),
                              foregroundColor: const Color(0xFF2C3E2E),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Add Course',
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
              'Lecturer QR Code',
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
                  const SizedBox(height: 4),
                  Text(
                    profile['department'] ?? 'N/A',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF3D4F3F)),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Share with students',
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
                'This QR code contains your lecturer information including ID, name, and department',
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

  Widget _genTab() {
    return Container(
      color: const Color(0xFFFAF7F0),
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 100,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF3D4F3F),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Generate',
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Colored Header Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  decoration: const BoxDecoration(
                    color: Color(0xFF3D4F3F),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4A574).withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.lock_clock,
                          color: Color(0xFFD4A574),
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Generate Attendance Code',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFAF7F0),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create a unique code for students',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: const Color(0xFFFAF7F0).withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
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
                              controller: genCourseId,
                              style: const TextStyle(color: Color(0xFFFAF7F0)),
                              decoration: InputDecoration(
                                labelText: 'Course ID',
                                labelStyle: const TextStyle(
                                  color: Color(0xFF9BA89C),
                                ),
                                prefixIcon: const Icon(
                                  Icons.class_outlined,
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
                                onPressed: _generateCode,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFD4A574),
                                  foregroundColor: const Color(0xFF2C3E2E),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  'Generate Code',
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
                      if (lastGenerated.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(32),
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
                              const Text(
                                'Generated Code',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF9BA89C),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                lastGenerated,
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFD4A574),
                                  letterSpacing: 8,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD4A574).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Share with students',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFFD4A574),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _viewTab() {
    return Container(
      color: const Color(0xFFFAF7F0),
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 100,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF3D4F3F),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'View',
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
          
          // Content
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section with Icon
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  decoration: const BoxDecoration(
                    color: Color(0xFF3D4F3F),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4A574).withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.assessment,
                          color: Color(0xFFD4A574),
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Attendance Records',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFAF7F0),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'View student attendance',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: const Color(0xFFFAF7F0).withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),

                // Form Section
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const SizedBox(height: 32),
                      
                      // Input Fields Container
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
                            // Course ID Input
                            TextField(
                              controller: viewCourseId,
                              style: const TextStyle(color: Color(0xFFFAF7F0)),
                              decoration: InputDecoration(
                                labelText: 'Course ID',
                                labelStyle: const TextStyle(
                                  color: Color(0xFF9BA89C),
                                ),
                                prefixIcon: const Icon(
                                  Icons.class_outlined,
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
                            
                            // Date Input
                            TextField(
                              controller: viewDate,
                              style: const TextStyle(color: Color(0xFFFAF7F0)),
                              decoration: InputDecoration(
                                labelText: 'Date (YYYY-MM-DD)',
                                labelStyle: const TextStyle(
                                  color: Color(0xFF9BA89C),
                                ),
                                prefixIcon: const Icon(
                                  Icons.calendar_today_outlined,
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
                            const SizedBox(height: 20),
                            
                            // View Button
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: _viewAttendance,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFD4A574),
                                  foregroundColor: const Color(0xFF2C3E2E),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  'View Attendance',
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

                      // Attendance Results Section
                      if (attendanceRows.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        
                        // Total Count Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4A574),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFD4A574).withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.people_rounded,
                                color: Color(0xFF2C3E2E),
                                size: 32,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Total Students: ',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2C3E2E),
                                ),
                              ),
                              Text(
                                '$total',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2C3E2E),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Student Attendance List
                        ...attendanceRows.map(
                          (r) => Container(
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
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.person_rounded,
                                  color: Color(0xFFD4A574),
                                  size: 24,
                                ),
                              ),
                              title: Text(
                                r['student_name'] ?? 'N/A',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: Color(0xFFFAF7F0),
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.badge_outlined,
                                          size: 14,
                                          color: Color(0xFF9BA89C),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          r['student_id'] ?? 'N/A',
                                          style: const TextStyle(
                                            color: Color(0xFF9BA89C),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.access_time_rounded,
                                          size: 14,
                                          color: Color(0xFF9BA89C),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          r['submitted_at'] ?? 'N/A',
                                          style: const TextStyle(
                                            color: Color(0xFF9BA89C),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD4A574).withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_circle_rounded,
                                  color: Color(0xFFD4A574),
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ] else if (viewCourseId.text.isNotEmpty && viewDate.text.isNotEmpty)
                        // Empty State
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(40),
                          margin: const EdgeInsets.only(top: 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2C3E2E),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.inbox_outlined,
                                size: 64,
                                color: const Color(0xFF3D4F3F),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No attendance records found',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF9BA89C),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Try a different date or course',
                                style: TextStyle(fontSize: 14, color: Color(0xFF9BA89C)),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
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
            backgroundColor: const Color(0xFF3D4F3F),
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
                    const Color(0xFFD4A574),
                  ),
                  _buildModernEmergencyContact(
                    'Medical Unit',
                    '+66 xxx xxx xxx',
                    Icons.local_hospital,
                    const Color(0xFFD4A574),
                  ),
                  _buildModernEmergencyContact(
                    'Fire & Safety',
                    '+66 xxx xxx xxx',
                    Icons.fire_extinguisher,
                    const Color(0xFFD4A574),
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
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Email Support',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: Color(0xFFFAF7F0),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
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
          onPressed: () => _callEmergencyContact(phone),
        ),
      ),
    );
  }
}