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

  Future<void> createUser() async {
    final sId = id.text.trim();
    final sName = name.text.trim();
    final sPassword = password.text;
    final sDept = department.text.trim();
    final sMajor = major.text.trim();
    final sPhoto = photoUrl.text.trim();

    if (sId.isEmpty || sName.isEmpty || sPassword.isEmpty || role.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill required fields (ID, Name, Password, Role)")));
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User created successfully")));
        // Clear input optionally
        id.clear();
        name.clear();
        password.clear();
        department.clear();
        major.clear();
        photoUrl.clear();
        setState(() => role = "student");
      } else {
        final msg = body['message'] ?? body['error'] ?? 'Failed to create user';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Unexpected response: ${res.body}')));
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
      appBar: AppBar(title: const Text("Create User")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            TextField(controller: id, decoration: const InputDecoration(labelText: "ID (required)")),
            const SizedBox(height: 8),
            TextField(controller: name, decoration: const InputDecoration(labelText: "Name (required)")),
            const SizedBox(height: 8),
            TextField(controller: password, decoration: const InputDecoration(labelText: "Password (required)"), obscureText: true),
            const SizedBox(height: 8),
            TextField(controller: department, decoration: const InputDecoration(labelText: "Department (optional)")),
            const SizedBox(height: 8),
            TextField(controller: major, decoration: const InputDecoration(labelText: "Major (optional)")),
            const SizedBox(height: 8),
            TextField(controller: photoUrl, decoration: const InputDecoration(labelText: "Photo URL (optional)")),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: role,
              items: const [
                DropdownMenuItem(value: "student", child: Text("student")),
                DropdownMenuItem(value: "lecturer", child: Text("lecturer")),
              ],
              onChanged: (v) => setState(() => role = v ?? "student"),
              decoration: const InputDecoration(labelText: "Role"),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _loading ? null : createUser,
                child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text("Create User"),
              ),
            )
          ],
        ),
      ),
    );
  }
}
