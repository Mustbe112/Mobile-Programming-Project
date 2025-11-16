// lib/screens/login_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api.dart';
import 'register_page.dart';
import 'student_home.dart';
import 'lecturer_home.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final idCtrl = TextEditingController();
  final pwCtrl = TextEditingController();
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _tryAutoLogin();
  }

  Future<void> _tryAutoLogin() async {
    final sp = await SharedPreferences.getInstance();
    final id = sp.getString('id');
    final role = sp.getString('role');
    if (id != null && role != null) {
      if (!mounted) return;
      if (role == 'student') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => StudentHome(id: id)));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LecturerHome(id: id)));
      }
    }
  }

  Future<void> _login() async {
    final id = idCtrl.text.trim();
    final pw = pwCtrl.text;
    if (id.isEmpty || pw.isEmpty) return _show('Enter id & password');

    setState(() => loading = true);
    try {
      final res = await Api.post('/auth/login', {'id': id, 'password': pw});
      setState(() => loading = false);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final sp = await SharedPreferences.getInstance();
        await sp.setString('id', data['id']);
        await sp.setString('role', data['role']);
        await sp.setString('name', data['name'] ?? '');
        if (!mounted) return;
        if (data['role'] == 'student') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => StudentHome(id: data['id'])));
        } else {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LecturerHome(id: data['id'])));
        }
      } else {
        final err = res.body.isNotEmpty ? (jsonDecode(res.body)['error'] ?? res.body) : 'Login failed';
        _show(err);
      }
    } catch (e) {
      setState(() => loading = false);
      _show('Network error: $e');
    }
  }

  void _show(String s) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
  void _goRegister() => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage()));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login — Digital ID')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          TextField(controller: idCtrl, decoration: const InputDecoration(labelText: 'ID')),
          TextField(controller: pwCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: loading ? null : _login, child: loading ? const SizedBox(width:18,height:18,child:CircularProgressIndicator(color:Colors.white,strokeWidth:2)) : const Text('Login')),
          TextButton(onPressed: _goRegister, child: const Text('Create account'))
        ]),
      ),
    );
  }
}
