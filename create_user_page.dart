// lib/screens/create_user_page.dart
import 'package:flutter/material.dart';
import '../services/api.dart';
import 'dart:convert';

class CreateUserPage extends StatefulWidget {
  const CreateUserPage({super.key});

  @override
  State<CreateUserPage> createState() => _CreateUserPageState();
}

class _CreateUserPageState extends State<CreateUserPage> {
  final id = TextEditingController();
  final name = TextEditingController();
  final password = TextEditingController();
  final department = TextEditingController();
  final major = TextEditingController();
  final photoUrl = TextEditingController();
  String role = "student";
  bool _loading = false;
  bool _obscurePassword = true;

  Future<void> createUser() async {
    final sId = id.text.trim();
    final sName = name.text.trim();
    final sPassword = password.text;
    final sDept = department.text.trim();
    final sMajor = major.text.trim();
    final sPhoto = photoUrl.text.trim();

    if (sId.isEmpty || sName.isEmpty || sPassword.isEmpty || role.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please fill required fields (ID, Name, Password, Role)",
          ),
        ),
      );
      return;
    }

    setState(() => _loading = true);
    final res = await Api.post('/admin/create-user', {
      "id": sId,
      "name": sName,
      "password": sPassword,
      "department": sDept.isEmpty ? null : sDept,
      "major": sMajor.isEmpty ? null : sMajor,
      "photo_url": sPhoto.isEmpty ? null : sPhoto,
      "role": role,
    });
    setState(() => _loading = false);

    try {
      final body = json.decode(res.body);
      if (res.statusCode == 200 && body['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User created successfully")),
        );
        // Clear input
        id.clear();
        name.clear();
        password.clear();
        department.clear();
        major.clear();
        photoUrl.clear();
        setState(() => role = "student");
      } else {
        final msg = body['message'] ?? body['error'] ?? 'Failed to create user';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unexpected response: ${res.body}')),
      );
    }
  }

  @override
  void dispose() {
    id.dispose();
    name.dispose();
    password.dispose();
    department.dispose();
    major.dispose();
    photoUrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1D2E),
      body: SafeArea(
        child: Column(
          children: [
            // Header with decorative circles
            Container(
              height: 200,
              child: Stack(
                children: [
                  // Decorative circles
                  Positioned(
                    top: -30,
                    left: 20,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue.withOpacity(0.3),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 40,
                    right: 40,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.purple.withOpacity(0.3),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 60,
                    left: 100,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue.withOpacity(0.2),
                      ),
                    ),
                  ),
                  // Back button
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Text(
                          'Back',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // UNIPASS text
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        RichText(
                          text: const TextSpan(
                            children: [
                              TextSpan(
                                text: 'UNI',
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4A90E2),
                                ),
                              ),
                              TextSpan(
                                text: 'PASS',
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF9B59B6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Create New Account',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Form container
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Create User',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1D2E),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Fill in the details to create a new user.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 30),
                      _buildInputField('ID', id, 'Enter user ID', isRequired: true),
                      const SizedBox(height: 16),
                      _buildInputField('NAME', name, 'Enter full name', isRequired: true),
                      const SizedBox(height: 16),
                      _buildInputField(
                        'PASSWORD',
                        password,
                        'Enter password',
                        isPassword: true,
                        isRequired: true,
                      ),
                      const SizedBox(height: 16),
                      _buildInputField('DEPARTMENT', department, 'Enter department'),
                      const SizedBox(height: 16),
                      _buildInputField('MAJOR', major, 'Enter major'),
                      const SizedBox(height: 16),
                      _buildInputField('PHOTO URL', photoUrl, 'Enter photo URL'),
                      const SizedBox(height: 16),
                      _buildRoleDropdown(),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _loading ? null : createUser,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2D3142),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Create User',
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller,
    String hint, {
    bool isPassword = false,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
                letterSpacing: 0.5,
              ),
            ),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.red,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword && _obscurePassword,
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 14,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'ROLE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
                letterSpacing: 0.5,
              ),
            ),
            const Text(
              ' *',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: role,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF1A1D2E),
              ),
              dropdownColor: const Color(0xFFF5F5F5),
              items: const [
                DropdownMenuItem(
                  value: "student",
                  child: Text("Student"),
                ),
                DropdownMenuItem(
                  value: "lecturer",
                  child: Text("Lecturer"),
                ),
              ],
              onChanged: (v) => setState(() => role = v ?? "student"),
            ),
          ),
        ),
      ],
    );
  }
}