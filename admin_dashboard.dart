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
  bool _obscurePassword = true;

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
    final body = {
      "name": _nameCtrl.text.trim(),
      "department": _deptCtrl.text.trim(),
      "major": _majorCtrl.text.trim(),
    };
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
      final res = await Api.put('/admin/user/$id/reset-password', {
        'newPassword': newPw,
      });
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
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
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
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CreateUserPage()),
    );
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
                  // Top bar
                  Positioned(
                    top: 10,
                    left: 0,
                    right: 0,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                onPressed: _logout,
                                icon: const Icon(Icons.arrow_back, color: Colors.white),
                                tooltip: 'Sign out',
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
                          TextButton.icon(
                            onPressed: _goCreateUser,
                            icon: const Icon(
                              Icons.person_add_alt_1,
                              size: 18,
                              color: Colors.white,
                            ),
                            label: const Text(
                              "Create User",
                              style: TextStyle(color: Colors.white, fontSize: 14),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
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
                          'Admin Dashboard',
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
                        'Manage Users',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1D2E),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Search and manage user accounts.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 30),
                      _buildSearchSection(),
                      const SizedBox(height: 24),
                      if (_user != null)
                        _buildUserForm()
                      else
                        _buildEmptyState(),
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

  Widget _buildSearchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SEARCH USER',
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
          child: TextField(
            controller: _searchCtrl,
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Enter user ID',
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 14,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            onSubmitted: (_) => _searchUser(),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _loading ? null : _searchUser,
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
                    'Search',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No user loaded',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Search for a user ID to view and edit their information',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserForm() {
    final role = (_user?['role'] ?? 'unknown').toString();
    final name = (_user?['name'] ?? '').toString();
    final id = (_user?['id'] ?? '').toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFF2D3142),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isNotEmpty ? name : '-',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1D2E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ID: $id',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D3142),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  role.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildInputField('NAME', _nameCtrl, 'Enter name'),
        const SizedBox(height: 16),
        _buildInputField('DEPARTMENT', _deptCtrl, 'Enter department'),
        const SizedBox(height: 16),
        _buildInputField('MAJOR', _majorCtrl, 'Enter major'),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _saving ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D3142),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 56,
              width: 56,
              child: OutlinedButton(
                onPressed: _deleting ? null : _deleteUser,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: BorderSide(color: Colors.red.shade300, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _deleting
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.red.shade300,
                        ),
                      )
                    : const Icon(Icons.delete_outline, size: 24),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Divider(color: Colors.grey.shade300, thickness: 1),
        const SizedBox(height: 32),
        const Text(
          'RESET PASSWORD',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        _buildInputField(
          'NEW PASSWORD',
          _newPwCtrl,
          'Enter new password',
          isPassword: true,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _resetting ? null : _resetPassword,
            icon: const Icon(Icons.key, size: 20),
            label: _resetting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Reset Password',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2D3142),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller,
    String hint, {
    bool isPassword = false,
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
}