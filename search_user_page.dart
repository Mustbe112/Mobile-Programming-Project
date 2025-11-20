import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'edit_user_page.dart';

class SearchUserPage extends StatefulWidget {
  @override
  State<SearchUserPage> createState() => _SearchUserPageState();
}

class _SearchUserPageState extends State<SearchUserPage> {
  final idController = TextEditingController();
  Map<String, dynamic>? user;

  Future<void> searchUser() async {
    final id = idController.text;
    final response = await http.get(
        Uri.parse("https://10.0.2.2:3000/admin/user/$id"));

    final data = json.decode(response.body);

    if (data['success']) {
      setState(() => user = data['user']);
    } else {
      user = null;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("User not found")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Search User")),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: idController,
              decoration: InputDecoration(labelText: "Enter User ID"),
            ),
            SizedBox(height: 10),
            ElevatedButton(onPressed: searchUser, child: Text("Search")),
            SizedBox(height: 20),
            if (user != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Name: ${user!['name']}"),
                  Text("Department: ${user!['department']}"),
                  Text("Role: ${user!['role']}"),
                  SizedBox(height: 20),
                  ElevatedButton(
                    child: Text("Edit User"),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => EditUserPage(user: user!)),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
