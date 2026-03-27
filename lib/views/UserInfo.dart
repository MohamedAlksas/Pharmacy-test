import 'package:flutter/material.dart';
import 'package:graduation_project/Models/UserRoleModel.dart';

class UserInfoPage extends StatefulWidget {
  const UserInfoPage({super.key});

  @override
  State<UserInfoPage> createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<UserInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _roleController = TextEditingController();

  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final user = AuthService.currentUser;
    _nameController.text = user?.fullName ?? '';
    _emailController.text = user?.email ?? '';
    _phoneController.text = user?.phoneNumber ?? '';
    _roleController.text = AuthService.isWarehouseManager
        ? 'Warehouse Manager'
        : 'Supervisor';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  void _toggleEdit() => setState(() => _isEditing = !_isEditing);

  void _saveChanges() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? const Color(0xFF0A1A1F) : const Color(0xFFF5F9FA);
    final cardColor = isDark ? const Color(0xFF1A2F35) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('User Profile',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87)),
                const Spacer(),
                if (!_isEditing)
                  ElevatedButton.icon(
                    onPressed: _toggleEdit,
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Profile'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white),
                  ),
              ],
            ),
            const SizedBox(height: 32),
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.blueAccent.withOpacity(0.2),
                    child: const Icon(Icons.person,
                        size: 60, color: Colors.blueAccent),
                  ),
                  const SizedBox(height: 16),
                  if (!_isEditing)
                    TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Change Photo'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2))
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Personal Information',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87)),
                    const SizedBox(height: 24),
                    _buildTextField(
                        controller: _nameController,
                        label: 'Full Name',
                        icon: Icons.person_outline,
                        enabled: _isEditing,
                        isDark: isDark),
                    const SizedBox(height: 16),
                    _buildTextField(
                        controller: _emailController,
                        label: 'Email',
                        icon: Icons.email_outlined,
                        enabled: _isEditing,
                        isDark: isDark,
                        keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 16),
                    _buildTextField(
                        controller: _phoneController,
                        label: 'Phone Number',
                        icon: Icons.phone_outlined,
                        enabled: _isEditing,
                        isDark: isDark,
                        keyboardType: TextInputType.phone),
                    const SizedBox(height: 16),
                    _buildTextField(
                        controller: _roleController,
                        label: 'Role',
                        icon: Icons.work_outline,
                        enabled: false,
                        isDark: isDark),
                  ],
                ),
              ),
            ),
            if (_isEditing) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _loadUserData();
                        _toggleEdit();
                      },
                      style: OutlinedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 16)),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveChanges,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 16)),
                      child: const Text('Save Changes'),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Account Settings',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87)),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.lock_outline,
                        color: Colors.blueAccent),
                    title: const Text('Change Password'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.notifications_outlined,
                        color: Colors.blueAccent),
                    title: const Text('Notifications'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.security_outlined,
                        color: Colors.blueAccent),
                    title: const Text('Privacy & Security'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                ],
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
    required IconData icon,
    required bool enabled,
    required bool isDark,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      style:
          TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blueAccent),
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
              color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
              color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
        ),
        filled: !enabled,
        fillColor: enabled
            ? null
            : (isDark ? Colors.grey[850] : Colors.grey[100]),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Please enter $label';
        return null;
      },
    );
  }
}