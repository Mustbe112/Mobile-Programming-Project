import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EditUserPage extends StatefulWidget {
  final Map<String, dynamic> user;

  EditUserPage({required this.user});

  @override
  State<EditUserPage> createState() => _EditUserPageState();
}

class _EditUserPageState extends State<EditUserPage> {
  late TextEditingController name;
  late TextEditingController dept;
  late TextEditingController major;
  late TextEditingController newPassword;

  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: widget.user['name']);
    dept = TextEditingController(text: widget.user['department']);
    major = TextEditingController(text: widget.user['major'] ?? "");
    newPassword = TextEditingController();
  }

  Future<void> saveChanges() async {
    final response = await http.put(
      Uri.parse("https://your-backend-url/admin/user/${widget.user['id']}"),
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        "name": name.text,
        "department": dept.text,
        "major": major.text,
      }),
    );

    final data = json.decode(response.body);

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(data['message'])));
  }

  Future<void> resetPassword() async {
    final response = await http.put(
      Uri.parse("https://your-backend-url/admin/user/${widget.user['id']}/reset-password"),
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        "newPassword": newPassword.text,
      }),
    );

    final data = json.decode(response.body);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(data['message'])));
  }

  Future<void> deleteUser() async {
    final response = await http.delete(
      Uri.parse("https://your-backend-url/admin/user/${widget.user['id']}"),
    );

    final data = json.decode(response.body);

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(data['message'])));

    Navigator.pop(context);
    Navigator.pop(context); // back twice
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Edit User")),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: ListView(
          children: [
            TextField(controller: name, decoration: InputDecoration(labelText: "Name")),
            TextField(controller: dept, decoration: InputDecoration(labelText: "Department")),
            TextField(controller: major, decoration: InputDecoration(labelText: "Major")),
            SizedBox(height: 20),
            ElevatedButton(onPressed: saveChanges, child: Text("Save Changes")),

            Divider(),

            TextField(
              controller: newPassword,
              decoration: InputDecoration(labelText: "New Password"),
            ),
            ElevatedButton(
              onPressed: resetPassword,
              child: Text("Reset Password"),
            ),

            Divider(),
            ElevatedButton(
              onPressed: deleteUser,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text("Delete User"),
            ),
          ],
        ),
      ),
    );
  }
}
