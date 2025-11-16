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

  Future<void> _register() async {
    final id = idCtrl.text.trim();
    if (id.isEmpty || pwCtrl.text.isEmpty || nameCtrl.text.isEmpty) return _show('Fill id/name/password');
    setState(() => loading = true);
    try {
      final res = await Api.post('/auth/register', {
        'id': id,
        'name': nameCtrl.text,
        'password': pwCtrl.text,
        'role': role,
        'major': majorCtrl.text,
        'department': deptCtrl.text,
        'photo_url': photoCtrl.text
      });
      setState(() => loading = false);
      if (res.statusCode == 200) {
        _show('Registered — please login');
        Navigator.pop(context);
      } else {
        final err = res.body.isNotEmpty ? (jsonDecode(res.body)['error'] ?? res.body) : 'Error';
        _show(err);
      }
    } catch (e) {
      setState(() => loading = false);
      _show('Network error: $e');
    }
  }

  void _show(String s) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          TextField(controller: idCtrl, decoration: const InputDecoration(labelText: 'ID')),
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
          TextField(controller: pwCtrl, decoration: const InputDecoration(labelText: 'Password')),
          const SizedBox(height: 8),
          Row(children: [
            const Text('Role: '),
            Radio<String>(value: 'student', groupValue: role, onChanged: (v){ if (v!=null) setState(()=>role=v); }),
            const Text('Student'),
            Radio<String>(value: 'lecturer', groupValue: role, onChanged: (v){ if (v!=null) setState(()=>role=v); }),
            const Text('Lecturer'),
          ]),
          if (role=='student') TextField(controller: majorCtrl, decoration: const InputDecoration(labelText: 'Major')),
          TextField(controller: deptCtrl, decoration: const InputDecoration(labelText: 'Department')),
          TextField(controller: photoCtrl, decoration: const InputDecoration(labelText: 'Photo URL (optional)')),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: loading?null:_register, child: const Text('Register'))
        ]),
      ),
    );
  }
}
