// lib/screens/admin_dashboard.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api.dart';
import 'create_user_page.dart';
import 'login_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _deptCtrl = TextEditingController();
  final TextEditingController _majorCtrl = TextEditingController();
  final TextEditingController _newPwCtrl = TextEditingController();

  Map<String, dynamic>? _user;
  bool _loading = false;
  bool _saving = false;
  bool _resetting = false;
  bool _deleting = false;

  Future<void> _searchUser() async {
    final id = _searchCtrl.text.trim();
    if (id.isEmpty) return _showSnack('Please enter an ID');
    setState(() => _loading = true);
    try {
      final res = await Api.get('/admin/user/$id');
      setState(() => _loading = false);
      if (res.statusCode == 200) {
        final j = jsonDecode(res.body);
        if (j['success'] == true && j['user'] != null) {
          setState(() {
            _user = Map<String, dynamic>.from(j['user']);
            _nameCtrl.text = _user?['name'] ?? '';
            _deptCtrl.text = _user?['department'] ?? '';
            _majorCtrl.text = _user?['major'] ?? '';
            _newPwCtrl.clear();
          });
        } else {
          setState(() => _user = null);
          _showSnack(j['message'] ?? 'User not found');
        }
      } else {
        _showSnack('Search failed: ${res.statusCode}');
      }
    } catch (e) {
      setState(() => _loading = false);
      _showSnack('Error: $e');
    }
  }

  Future<void> _saveChanges() async {
    if (_user == null) return _showSnack('No user loaded');
    final id = _user!['id'];
    final body = {"name": _nameCtrl.text.trim(), "department": _deptCtrl.text.trim(), "major": _majorCtrl.text.trim()};
    setState(() => _saving = true);
    try {
      final res = await Api.put('/admin/user/$id', body);
      setState(() => _saving = false);
      if (res.statusCode == 200) {
        final j = jsonDecode(res.body);
        if (j['success'] == true) {
          _showSnack('User updated');
          await _searchUser();
        } else {
          _showSnack(j['message'] ?? 'Update failed');
        }
      } else {
        _showSnack('Update failed: ${res.statusCode}');
      }
    } catch (e) {
      setState(() => _saving = false);
      _showSnack('Network error: $e');
    }
  }

  Future<void> _resetPassword() async {
    if (_user == null) return _showSnack('No user loaded');
    final newPw = _newPwCtrl.text.trim();
    if (newPw.isEmpty) return _showSnack('Enter new password');
    final id = _user!['id'];
    setState(() => _resetting = true);
    try {
      final res = await Api.put('/admin/user/$id/reset-password', {'newPassword': newPw});
      setState(() => _resetting = false);
      if (res.statusCode == 200) {
        final j = jsonDecode(res.body);
        if (j['success'] == true) {
          _newPwCtrl.clear();
          _showSnack('Password reset');
        } else {
          _showSnack(j['message'] ?? 'Reset failed');
        }
      } else {
        _showSnack('Reset failed: ${res.statusCode}');
      }
    } catch (e) {
      setState(() => _resetting = false);
      _showSnack('Network error: $e');
    }
  }

  Future<void> _deleteUser() async {
    if (_user == null) return _showSnack('No user loaded');
    final id = _user!['id'];
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm delete'),
        content: Text('Delete user $id (${_user!['name'] ?? ''})?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (yes != true) return;
    setState(() => _deleting = true);
    try {
      final res = await Api.delete('/admin/user/$id');
      setState(() => _deleting = false);
      if (res.statusCode == 200) {
        final j = jsonDecode(res.body);
        if (j['success'] == true) {
          setState(() {
            _user = null;
            _searchCtrl.clear();
            _nameCtrl.clear();
            _deptCtrl.clear();
            _majorCtrl.clear();
            _newPwCtrl.clear();
          });
          _showSnack('User deleted');
        } else {
          _showSnack(j['message'] ?? 'Delete failed');
        }
      } else {
        _showSnack('Delete failed: ${res.statusCode}');
      }
    } catch (e) {
      setState(() => _deleting = false);
      _showSnack('Network error: $e');
    }
  }

  void _goCreateUser() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => CreateUserPage()));
  }

  // LOGOUT now clears SharedPreferences
  Future<void> _logout() async {
    final sp = await SharedPreferences.getInstance();
    await sp.clear();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginPage()), (route) => false);
  }

  void _showSnack(String s) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _nameCtrl.dispose();
    _deptCtrl.dispose();
    _majorCtrl.dispose();
    _newPwCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        foregroundColor: Colors.black87,
        title: const Text("Admin Dashboard", style: TextStyle(color: Colors.black87)),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ElevatedButton.icon(
              onPressed: _goCreateUser,
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text("Create"),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1a1d2e)),
            ),
          ),
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout), tooltip: 'Sign out'),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(controller: _searchCtrl, decoration: const InputDecoration(border: InputBorder.none, hintText: "Search user by ID"), onSubmitted: (_) => _searchUser()),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(onPressed: _loading ? null : _searchUser, child: _loading ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text("Search")),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_user != null) _userCard() else _emptyCard(),
          ],
        ),
      ),
    );
  }

  Widget _emptyCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [const Icon(Icons.search_off, size: 48, color: Colors.grey), const SizedBox(height: 8), Text("No user loaded", style: TextStyle(color: Colors.grey.shade700)), const SizedBox(height: 4), Text("Use the search box above to find a student or lecturer by ID.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600))])),
    );
  }

  Widget _userCard() {
    final role = (_user?['role'] ?? 'unknown').toString();
    final name = (_user?['name'] ?? '').toString();
    final id = (_user?['id'] ?? '').toString();
    final avatarLetter = name.isNotEmpty ? name[0].toUpperCase() : (id.isNotEmpty ? id[0].toUpperCase() : '?');

    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            CircleAvatar(radius: 28, backgroundColor: Colors.grey.shade200, child: Text(avatarLetter, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name.isNotEmpty ? name : '-', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text("ID: $id", style: TextStyle(color: Colors.grey.shade600))])),
            const SizedBox(width: 8),
            Chip(label: Text(role.toUpperCase())),
          ]),
          const SizedBox(height: 16),
          TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: "Name")),
          const SizedBox(height: 8),
          TextField(controller: _deptCtrl, decoration: const InputDecoration(labelText: "Department")),
          const SizedBox(height: 8),
          TextField(controller: _majorCtrl, decoration: const InputDecoration(labelText: "Major (optional)")),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: ElevatedButton(onPressed: _saving ? null : _saveChanges, child: _saving ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text("Save"))),
            const SizedBox(width: 10),
            Expanded(child: ElevatedButton(onPressed: _deleting ? null : _deleteUser, style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: _deleting ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text("Delete"))),
          ]),
          const SizedBox(height: 18),
          const Divider(),
          const SizedBox(height: 8),
          TextField(controller: _newPwCtrl, decoration: const InputDecoration(labelText: "New Password")),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: _resetting ? null : _resetPassword, icon: const Icon(Icons.key), label: _resetting ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text("Reset Password"))),
        ]),
      ),
    );
  }
}
