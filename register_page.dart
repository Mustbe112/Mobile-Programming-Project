// lib/screens/register_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final idCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  final pwCtrl = TextEditingController();
  final majorCtrl = TextEditingController();
  final deptCtrl = TextEditingController();
  final photoCtrl = TextEditingController();
  String role = 'student';
  bool loading = false;
  bool _obscurePassword = true;

  Future<void> _register() async {
    final id = idCtrl.text.trim();
    if (id.isEmpty || pwCtrl.text.isEmpty || nameCtrl.text.isEmpty)
      return _show('Fill id/name/password');
    setState(() => loading = true);
    try {
      final res = await Api.post('/auth/register', {
        'id': id,
        'name': nameCtrl.text,
        'password': pwCtrl.text,
        'role': role,
        'major': majorCtrl.text,
        'department': deptCtrl.text,
        'photo_url': photoCtrl.text,
      });
      setState(() => loading = false);
      if (res.statusCode == 200) {
        _show('Registered — please login');
        Navigator.pop(context);
      } else {
        final err = res.body.isNotEmpty
            ? (jsonDecode(res.body)['error'] ?? res.body)
            : 'Error';
        _show(err);
      }
    } catch (e) {
      setState(() => loading = false);
      _show('Network error: $e');
    }
  }

  void _show(String s) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));

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
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
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
                          'Your Digital Campus ID',
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
                        'Register',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1D2E),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Create your account.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 30),
                      _buildTextField(
                        controller: idCtrl,
                        label: 'ID',
                        hint: 'Enter your ID',
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: nameCtrl,
                        label: 'NAME',
                        hint: 'Enter your name',
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: pwCtrl,
                        label: 'PASSWORD',
                        hint: 'Enter your password',
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() => _obscurePassword = !_obscurePassword);
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Role selection
                      const Text(
                        'ROLE',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: RadioListTile<String>(
                                value: 'student',
                                groupValue: role,
                                onChanged: (v) {
                                  if (v != null) setState(() => role = v);
                                },
                                title: const Text(
                                  'Student',
                                  style: TextStyle(fontSize: 14),
                                ),
                                activeColor: const Color(0xFF2D3142),
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<String>(
                                value: 'lecturer',
                                groupValue: role,
                                onChanged: (v) {
                                  if (v != null) setState(() => role = v);
                                },
                                title: const Text(
                                  'Lecturer',
                                  style: TextStyle(fontSize: 14),
                                ),
                                activeColor: const Color(0xFF2D3142),
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (role == 'student') ...[
                        _buildTextField(
                          controller: majorCtrl,
                          label: 'MAJOR',
                          hint: 'Enter your major',
                        ),
                        const SizedBox(height: 20),
                      ],
                      _buildTextField(
                        controller: deptCtrl,
                        label: 'DEPARTMENT',
                        hint: 'Enter your department',
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: photoCtrl,
                        label: 'PHOTO URL (OPTIONAL)',
                        hint: 'Enter photo URL',
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: loading ? null : _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2D3142),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Register',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                              children: [
                                TextSpan(text: 'Already have an account? '),
                                TextSpan(
                                  text: 'Login',
                                  style: TextStyle(
                                    color: Color(0xFF2D3142),
                                    fontWeight: FontWeight.w600,
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
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
              suffixIcon: suffixIcon,
            ),
          ),
        ),
      ],
    );
  }
}