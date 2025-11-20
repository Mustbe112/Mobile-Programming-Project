// lib/screens/login_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api.dart';
import 'register_page.dart';
import 'student_home.dart';
import 'lecturer_home.dart';
import 'admin_dashboard.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final idCtrl = TextEditingController();
  final pwCtrl = TextEditingController();
  bool loading = false;
  bool hidePassword = true;

  // ❌ Removed auto-login (_tryAutoLogin)
  // ❌ Removed initState auto navigation
  // This page ALWAYS opens normally now.

  Future<void> _login() async {
    final id = idCtrl.text.trim();
    final pw = pwCtrl.text;

    if (id.isEmpty || pw.isEmpty) return _show('Enter ID & password');

    // ---------------------------------------
    // LOCAL ADMIN LOGIN (fallback option)
    // ---------------------------------------
    if (id == "admin123" && pw == "pass123") {
      final sp = await SharedPreferences.getInstance();
      await sp.setString('id', id);
      await sp.setString('role', 'admin');
      await sp.setString('name', 'Administrator');

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AdminDashboard()),
        (route) => false,
      );
      return;
    }

    // ---------------------------------------
    // NORMAL API LOGIN
    // ---------------------------------------
    setState(() => loading = true);

    try {
      final res = await Api.post('/auth/login', {
        'id': id,
        'password': pw,
      });

      setState(() => loading = false);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        final sp = await SharedPreferences.getInstance();
        await sp.setString('id', data['id']);
        await sp.setString('role', data['role']);
        await sp.setString('name', data['name'] ?? '');

        if (!mounted) return;

        // navigation based on role
        if (data['role'] == 'student') {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => StudentHome(id: data['id'])),
            (route) => false,
          );
        } else if (data['role'] == 'lecturer') {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => LecturerHome(id: data['id'])),
            (route) => false,
          );
        } else if (data['role'] == 'admin') {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const AdminDashboard()),
            (route) => false,
          );
        }
      } else {
        final body = res.body.isNotEmpty ? jsonDecode(res.body) : null;
        final err = body?['error'] ?? 'Login failed';
        _show(err);
      }
    } catch (e) {
      setState(() => loading = false);
      _show('Network error: $e');
    }
  }

  void _show(String s) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s)),
    );
  }

  void _goRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: const Color(0xFF1a1d2e),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                flex: 2,
                child: Stack(
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFF1a1d2e),
                      ),
                      child: CustomPaint(painter: CirclePatternPainter()),
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CustomPaint(
                            size: const Size(120, 120),
                            painter: UniPassLogoPainter(),
                          ),
                          const SizedBox(height: 15),
                          const Text(
                            'UniPass',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'Your Digital Campus ID',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ----------------------------
              // Login Form
              // ----------------------------
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        const Center(
                          child: Text(
                            "Login",
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            "Sign in to continue.",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        const SizedBox(height: 40),

                        // ID FIELD
                        Text(
                          "ID",
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            controller: idCtrl,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 20),
                              hintText: "Enter your ID",
                            ),
                          ),
                        ),

                        const SizedBox(height: 25),

                        // PASSWORD FIELD
                        Text(
                          "PASSWORD",
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            controller: pwCtrl,
                            obscureText: hidePassword,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              hintText: "••••••",
                              suffixIcon: IconButton(
                                icon: Icon(
                                  hidePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: Colors.grey.shade600,
                                ),
                                onPressed: () =>
                                    setState(() => hidePassword = !hidePassword),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 35),

                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: loading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1a1d2e),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: loading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text(
                                    "Log In",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 25),
                        Center(
                          child: TextButton(
                            onPressed: _goRegister,
                            child: Text(
                              "Sign-up !",
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Keep your custom painters below
class CirclePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2d3454).withOpacity(0.6)
      ..style = PaintingStyle.fill;

    final positions = [
      Offset(size.width * 0.15, size.height * 0.2),
      Offset(size.width * 0.85, size.height * 0.15),
      Offset(size.width * 0.1, size.height * 0.6),
      Offset(size.width * 0.75, size.height * 0.65),
      Offset(size.width * 0.5, size.height * 0.3),
      Offset(size.width * 0.3, size.height * 0.8),
      Offset(size.width * 0.9, size.height * 0.5),
    ];

    for (var pos in positions) {
      canvas.drawCircle(pos, 40, paint);
      canvas.drawCircle(
        pos,
        25,
        paint..color = const Color(0xFF3d4564).withOpacity(0.4),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class UniPassLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final shieldPath = Path();
    shieldPath.moveTo(w * 0.5, 0);
    shieldPath.cubicTo(
        w * 0.2, h * 0.05, w * 0.05, h * 0.15, w * 0.05, h * 0.4);
    shieldPath.cubicTo(
        w * 0.05, h * 0.7, w * 0.3, h * 0.9, w * 0.5, h);
    shieldPath.cubicTo(
        w * 0.7, h * 0.9, w * 0.95, h * 0.7, w * 0.95, h * 0.4);
    shieldPath.cubicTo(
        w * 0.95, h * 0.15, w * 0.8, h * 0.05, w * 0.5, 0);
    shieldPath.close();

    final shieldGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFF1E88E5),
        const Color(0xFF5E35B1),
        const Color(0xFF8E24AA),
      ],
    );

    final shieldPaint = Paint()
      ..shader = shieldGradient.createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    canvas.drawPath(shieldPath, shieldPaint);

    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final whiteRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.2, h * 0.45, w * 0.6, h * 0.35),
      const Radius.circular(8),
    );

    canvas.drawRRect(whiteRect, whitePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
