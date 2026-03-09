import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:graduation_project/Models/UserRoleModel.dart';
import 'package:graduation_project/main.dart';
import 'package:graduation_project/widgets/SidebarWidget.dart';

// ─── App wrapper (keeps theme) ────────────────────────────────────────────────

class Loginview extends StatelessWidget {
  const Loginview({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Pharmacy Logistics',
          themeMode: mode,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF2F7F8),
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0A6B6E)),
            textTheme: const TextTheme(
              bodyMedium: TextStyle(fontFamily: 'Inter', color: Colors.black87),
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF0E1418),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF18B6B6),
              brightness: Brightness.dark,
            ),
            textTheme: const TextTheme(
              bodyMedium: TextStyle(fontFamily: 'Inter', color: Colors.white70),
            ),
          ),
          home: const LoginPage(),
        );
      },
    );
  }
}

// ─── Login Page ───────────────────────────────────────────────────────────────

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  late final AnimationController _entranceController;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _fadeAnim;

  bool _loading = false;
  bool _obscurePassword = true;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic),
    );
    _fadeAnim =
        CurvedAnimation(parent: _entranceController, curve: Curves.easeIn);

    Timer(
      const Duration(milliseconds: 120),
      () => _entranceController.forward(),
    );
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // ── Login via API ───────────────────────────────────────────────────────────

  Future<void> _attemptLogin() async {
    setState(() => _errorText = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final error = await AuthService.login(
      _usernameCtrl.text.trim(),
      _passwordCtrl.text,
    );

    if (!mounted) return;
    setState(() {
      _loading = false;
      _errorText = error;
    });

    if (error == null) {
      // Login successful — navigate based on role
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainLayout(initialIndex: 0)),
      );
    }
  }

  // ── Open register bottom sheet ──────────────────────────────────────────────

  void _openRegisterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _RegisterSheet(),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width.clamp(400.0, 560.0);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.file(
              File(backgroundImagePath),
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) =>
                  Container(color: const Color(0xFFDFF3F4)),
            ),
          ),
          Positioned.fill(
            child:
                Container(color: const Color(0xFFBFEFF0).withOpacity(0.18)),
          ),
          Center(
            child: SlideTransition(
              position: _slideAnim,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: ConstrainedBox(
                  constraints:
                      BoxConstraints(maxWidth: maxWidth, minWidth: 320),
                  child: _buildLoginCard(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginCard(BuildContext context) {
    return Material(
      elevation: 28,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        padding:
            const EdgeInsets.symmetric(vertical: 32, horizontal: 36),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'PHARMACY LOGISTICS',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: Color(0xFF0A4D57),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'WAREHOUSE MANAGEMENT SYSTEM',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1CA0A5),
                ),
              ),
              const SizedBox(height: 20),
              _buildLogoCircle(),
              const SizedBox(height: 24),

              // Username
              _buildLabeledField(
                label: 'Username',
                child: TextFormField(
                  controller: _usernameCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Enter your username',
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.person_outline, size: 20),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty)
                          ? 'Please enter username'
                          : null,
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(height: 14),

              // Password
              _buildLabeledField(
                label: 'Password',
                child: TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Enter your password',
                    border: InputBorder.none,
                    prefixIcon:
                        const Icon(Icons.lock_outline, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                      ),
                      onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty)
                          ? 'Please enter password'
                          : null,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _attemptLogin(),
                ),
              ),
              const SizedBox(height: 22),

              // Login button
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: _loading ? null : _attemptLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1CA0A5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 6,
                    shadowColor: Colors.black.withOpacity(0.25),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    child: _loading
                        ? const SizedBox(
                            key: ValueKey('loader'),
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            key: ValueKey('label'),
                            'LOGIN',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                            ),
                          ),
                  ),
                ),
              ),

              // Error
              if (_errorText != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.redAccent, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorText!,
                          style: const TextStyle(
                              color: Colors.redAccent, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Register link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an account? ",
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  GestureDetector(
                    onTap: _openRegisterSheet,
                    child: const Text(
                      'Register',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1CA0A5),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabeledField(
      {required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87)),
        const SizedBox(height: 6),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F7FB),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: child,
        ),
      ],
    );
  }

  Widget _buildLogoCircle() {
    return Container(
      height: 76,
      width: 76,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Container(
          height: 58,
          width: 58,
          decoration: const BoxDecoration(
            color: Color(0xFFE6FBFC),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.local_pharmacy,
              size: 30, color: Color(0xFF0A6B6E)),
        ),
      ),
    );
  }
}

// ─── Register Bottom Sheet ────────────────────────────────────────────────────

class _RegisterSheet extends StatefulWidget {
  const _RegisterSheet();

  @override
  State<_RegisterSheet> createState() => _RegisterSheetState();
}

class _RegisterSheetState extends State<_RegisterSheet> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _fullNameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _errorText;
  String? _successText;

  // "admin" = Warehouse Manager, "user" = Supervisor
  String _selectedRole = 'user';

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _fullNameCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _errorText = null;
      _successText = null;
    });
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    String? error;
    if (_selectedRole == 'admin') {
      error = await AuthService.registerAdmin(
        username: _usernameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        fullName: _fullNameCtrl.text.trim(),
      );
    } else {
      error = await AuthService.registerUser(
        username: _usernameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        fullName: _fullNameCtrl.text.trim(),
      );
    }

    if (!mounted) return;
    setState(() {
      _loading = false;
      _errorText = error;
      _successText = error == null
          ? 'Account created successfully! You can now log in.'
          : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomPad),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Create Account',
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Fill in the details below to register.',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 20),

              // Role selector
              const Text('Account Type',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _roleChip(
                    label: 'Supervisor',
                    value: 'user',
                    icon: Icons.supervised_user_circle_outlined,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 10),
                  _roleChip(
                    label: 'Manager (Admin)',
                    value: 'admin',
                    icon: Icons.admin_panel_settings_outlined,
                    color: Colors.blue,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Full Name
              _field(
                controller: _fullNameCtrl,
                label: 'Full Name',
                hint: 'e.g. Ahmed Mohamed',
                icon: Icons.badge_outlined,
              ),
              const SizedBox(height: 12),

              // Username
              _field(
                controller: _usernameCtrl,
                label: 'Username',
                hint: 'Choose a username',
                icon: Icons.person_outline,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Required'
                    : null,
              ),
              const SizedBox(height: 12),

              // Email
              _field(
                controller: _emailCtrl,
                label: 'Email',
                hint: 'your@email.com',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (!v.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Password
              _field(
                controller: _passwordCtrl,
                label: 'Password',
                hint: 'Min. 6 characters',
                icon: Icons.lock_outline,
                obscure: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                  ),
                  onPressed: () => setState(
                      () => _obscurePassword = !_obscurePassword),
                ),
                validator: (v) => (v == null || v.length < 6)
                    ? 'At least 6 characters'
                    : null,
              ),
              const SizedBox(height: 12),

              // Confirm Password
              _field(
                controller: _confirmCtrl,
                label: 'Confirm Password',
                hint: 'Repeat your password',
                icon: Icons.lock_outline,
                obscure: _obscureConfirm,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                  ),
                  onPressed: () => setState(
                      () => _obscureConfirm = !_obscureConfirm),
                ),
                validator: (v) => v != _passwordCtrl.text
                    ? 'Passwords do not match'
                    : null,
              ),
              const SizedBox(height: 20),

              // Feedback banners
              if (_errorText != null)
                _banner(
                    text: _errorText!,
                    color: Colors.red,
                    icon: Icons.error_outline),
              if (_successText != null)
                _banner(
                    text: _successText!,
                    color: Colors.green,
                    icon: Icons.check_circle_outline),
              if (_errorText != null || _successText != null)
                const SizedBox(height: 12),

              // Submit
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: _loading || _successText != null
                      ? null
                      : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1CA0A5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('CREATE ACCOUNT',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),

              if (_successText != null) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Back to Login'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleChip({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final selected = _selectedRole == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color:
              selected ? color.withOpacity(0.12) : Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color : Colors.grey[300]!,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 18, color: selected ? color : Colors.grey),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected
                    ? FontWeight.w600
                    : FontWeight.normal,
                color: selected ? color : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20),
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 14),
          ),
          validator: validator ??
              (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
        ),
      ],
    );
  }

  Widget _banner(
      {required String text,
      required Color color,
      required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text,
                  style: TextStyle(color: color, fontSize: 13))),
        ],
      ),
    );
  }
}