import 'package:flutter/material.dart';
import 'package:graduation_project/Models/ProductProvider.dart';
import 'package:graduation_project/Models/UserRoleModel.dart';
import 'package:graduation_project/views/DashboardView.dart';
import 'package:graduation_project/views/InventoryView.dart';
import 'package:graduation_project/views/LoginView.dart';
import 'package:graduation_project/views/OrdersView.dart';
import 'package:graduation_project/views/ReportsPage.dart';
import 'package:graduation_project/views/UserInfo.dart';
import 'package:graduation_project/main.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MainLayout  (single definition — Mainlayout.dart is deleted / unused)
// ─────────────────────────────────────────────────────────────────────────────

class MainLayout extends StatefulWidget {
  final int initialIndex;
  const MainLayout({super.key, this.initialIndex = 0});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  late int _selectedIndex;

  // ── Menu definitions ────────────────────────────────────────────────────────

  static const List<_MenuItem> _managerMenu = [
    _MenuItem(icon: Icons.dashboard_rounded, label: 'Dashboard', index: 0),
    _MenuItem(icon: Icons.inventory_2_rounded, label: 'Inventory', index: 1),
    _MenuItem(icon: Icons.bar_chart_rounded, label: 'Reports', index: 2),
    _MenuItem(icon: Icons.list_alt_rounded, label: 'Orders', index: 3),
    _MenuItem(icon: Icons.manage_accounts, label: 'Settings', index: 4),
  ];

  static const List<_MenuItem> _supervisorMenu = [
    _MenuItem(icon: Icons.list_alt_rounded, label: 'Orders', index: 0),
    _MenuItem(icon: Icons.bar_chart_rounded, label: 'Reports', index: 1),
  ];

  // ── Page lists ──────────────────────────────────────────────────────────────

  static const List<Widget> _managerPages = [
    DashboardPage(),
    InventoryPage(),
    _ReportsWrapper(),
    _OrdersWrapper(),
    UserInfoPage(),
  ];

  static const List<Widget> _supervisorPages = [
    _OrdersWrapper(),
    _ReportsWrapper(),
  ];

  // ── Init ────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _selectedIndex = AuthService.isSupervisor ? 0 : widget.initialIndex;
  }

  void _onSelect(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
  }

  void _logout() {
    AuthService.logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isManager = AuthService.isWarehouseManager;
    final menu = isManager ? _managerMenu : _supervisorMenu;
    final pages = isManager ? _managerPages : _supervisorPages;
    final provider = ProductProvider.of(context);

    // Live counts
    final criticalCount = provider.getCriticalAlertsCount();
    final lowStock = provider.lowStockCount;
    final hasAnyAlerts = criticalCount > 0 || lowStock > 0;

    return Scaffold(
      body: Row(
        children: [
          _Sidebar(
            isDark: isDark,
            isManager: isManager,
            selectedIndex: _selectedIndex,
            menu: menu,
            criticalCount: criticalCount,
            hasAnyAlerts: hasAnyAlerts,
            lowStockCount: lowStock,
            onSelect: _onSelect,
            onLogout: _logout,
          ),
          Expanded(child: pages[_selectedIndex]),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _Sidebar
// ─────────────────────────────────────────────────────────────────────────────

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.isDark,
    required this.isManager,
    required this.selectedIndex,
    required this.menu,
    required this.criticalCount,
    required this.hasAnyAlerts,
    required this.lowStockCount,
    required this.onSelect,
    required this.onLogout,
  });

  final bool isDark;
  final bool isManager;
  final int selectedIndex;
  final List<_MenuItem> menu;
  final int criticalCount;
  final bool hasAnyAlerts;
  final int lowStockCount;
  final void Function(int) onSelect;
  final VoidCallback onLogout;

  Color get _bg => isDark ? const Color(0xFF071014) : const Color(0xFFEAF2F3);
  Color get _accent =>
      isDark ? Colors.lightBlueAccent : const Color(0xFF0A6B6E);
  Color get _iconDef => isDark ? Colors.white60 : Colors.black45;
  Color get _textDef => isDark ? Colors.white : Colors.black87;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 224,
      color: _bg,
      child: Column(
        children: [
          const SizedBox(height: 16),
          _buildBrand(),
          const SizedBox(height: 8),
          _buildRoleBadge(),
          const SizedBox(height: 10),
          Divider(
            height: 1,
            color: isDark ? Colors.white12 : Colors.black12,
            indent: 14,
            endIndent: 14,
          ),
          const SizedBox(height: 8),

          // Nav items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: menu
                  .map(
                    (item) => _NavItem(
                      item: item,
                      selected: item.index == selectedIndex,
                      accent: _accent,
                      iconDefault: _iconDef,
                      textDefault: _textDef,
                      isDark: isDark,
                      badge: _badgeFor(item.index),
                      onTap: () => onSelect(item.index),
                    ),
                  )
                  .toList(),
            ),
          ),

          // Alert summary — manager only
          if (isManager && hasAnyAlerts) _buildAlertPanel(),

          Divider(height: 1, color: isDark ? Colors.white12 : Colors.black12),
          _buildBottomBar(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── badge logic ─────────────────────────────────────────────────────────────

  String? _badgeFor(int menuIndex) {
    if (!isManager) return null;
    if (menuIndex == 2 && criticalCount > 0) {
      return criticalCount.toString(); // Reports
    }
    if (menuIndex == 3 && lowStockCount > 0) {
      return lowStockCount.toString(); // Orders
    }
    return null;
  }

  // ── brand header ────────────────────────────────────────────────────────────

  Widget _buildBrand() {
    final fullName = AuthService.currentUser?.fullName ?? '';
    final display = fullName;
    final roleColor = isManager ? Colors.blue : Colors.green;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: roleColor.withOpacity(0.16),
            child: Text(
              _profileInitial(fullName),
              style: TextStyle(color: roleColor, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PharmaWarehouse',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                if (display.isNotEmpty)
                  Text(
                    display,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _profileInitial(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed.substring(0, 1).toUpperCase();
  }

  // ── role badge ──────────────────────────────────────────────────────────────

  Widget _buildRoleBadge() {
    final label = isManager ? 'Warehouse Manager' : 'Supervisor';
    final color = isManager ? Colors.blue : Colors.green;
    final icon = isManager
        ? Icons.admin_panel_settings_outlined
        : Icons.supervised_user_circle_outlined;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.30)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── alert summary panel ─────────────────────────────────────────────────────

  Widget _buildAlertPanel() {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.withOpacity(0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.red,
                size: 15,
              ),
              const SizedBox(width: 5),
              Text(
                '$criticalCount Critical Alert${criticalCount != 1 ? 's' : ''}',
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          if (criticalCount > 0) ...[
            const SizedBox(height: 5),
            _alertRow(
              Icons.error_outline,
              Colors.red,
              '$criticalCount expired / expiring soon',
            ),
          ],
          if (lowStockCount > 0) ...[
            const SizedBox(height: 4),
            _alertRow(
              Icons.inventory_2_outlined,
              Colors.orange,
              '$lowStockCount low-stock item${lowStockCount != 1 ? 's' : ''}',
            ),
          ],
        ],
      ),
    );
  }

  Widget _alertRow(IconData icon, Color color, String text) => Row(
    children: [
      Icon(icon, color: color, size: 12),
      const SizedBox(width: 5),
      Expanded(
        child: Text(text, style: TextStyle(color: color, fontSize: 11)),
      ),
    ],
  );

  // ── bottom bar: theme toggle + logout ────────────────────────────────────────

  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Toggle theme',
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: _iconDef,
              size: 20,
            ),
            onPressed: () {
              themeNotifier.value = themeNotifier.value == ThemeMode.dark
                  ? ThemeMode.light
                  : ThemeMode.dark;
            },
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Logout',
            icon: Icon(
              Icons.logout_rounded,
              color: Colors.red.shade300,
              size: 20,
            ),
            onPressed: onLogout,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _NavItem
// ─────────────────────────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.item,
    required this.selected,
    required this.accent,
    required this.iconDefault,
    required this.textDefault,
    required this.isDark,
    required this.onTap,
    this.badge,
  });

  final _MenuItem item;
  final bool selected;
  final Color accent;
  final Color iconDefault;
  final Color textDefault;
  final bool isDark;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final iconColor = selected ? accent : iconDefault;
    final textColor = selected ? accent : textDefault;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: selected
            ? accent.withOpacity(isDark ? 0.15 : 0.09)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // Icon with optional red badge
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(item.icon, color: iconColor, size: 20),
                    if (badge != null)
                      Positioned(
                        right: -10,
                        top: -6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            badge!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      fontSize: 13.5,
                    ),
                  ),
                ),
                // Selection dot
                if (selected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _MenuItem data class
// ─────────────────────────────────────────────────────────────────────────────

class _MenuItem {
  final IconData icon;
  final String label;
  final int index;
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.index,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Page wrappers  (supervisor banner + print FAB)
// ─────────────────────────────────────────────────────────────────────────────

class _OrdersWrapper extends StatelessWidget {
  const _OrdersWrapper();

  @override
  Widget build(BuildContext context) {
    final isSup = AuthService.isSupervisor;
    return Column(
      children: [
        if (isSup) _SupervisorBanner(type: 'orders'),
        Expanded(
          child: Stack(
            children: [
              const OrdersPage(),
              if (isSup)
                Positioned(
                  top: 16,
                  right: 16,
                  child: FloatingActionButton.extended(
                    heroTag: 'print_orders',
                    onPressed: () => _snack(context, 'orders'),
                    icon: const Icon(Icons.print),
                    label: const Text('Print Orders'),
                    backgroundColor: Colors.blue,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReportsWrapper extends StatelessWidget {
  const _ReportsWrapper();

  @override
  Widget build(BuildContext context) {
    final isSup = AuthService.isSupervisor;
    return Column(
      children: [
        if (isSup) _SupervisorBanner(type: 'reports'),
        Expanded(
          child: Stack(
            children: [
              const ReportsPage(),
              if (isSup)
                Positioned(
                  top: 16,
                  right: 16,
                  child: FloatingActionButton.extended(
                    heroTag: 'print_reports',
                    onPressed: () => _snack(context, 'report'),
                    icon: const Icon(Icons.print),
                    label: const Text('Print Report'),
                    backgroundColor: Colors.green,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Shared supervisor info banner ─────────────────────────────────────────────

class _SupervisorBanner extends StatelessWidget {
  const _SupervisorBanner({required this.type});
  final String type;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.07),
        border: Border(
          bottom: BorderSide(color: Colors.blue.withOpacity(0.18)),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue[700], size: 17),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Supervisor view — read only. You can view and print $type.',
              style: TextStyle(color: Colors.blue[800], fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

void _snack(BuildContext context, String type) => ScaffoldMessenger.of(
  context,
).showSnackBar(SnackBar(content: Text('Sending $type to printer…')));
