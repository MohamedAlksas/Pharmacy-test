import 'package:flutter/material.dart';
import 'package:graduation_project/Models/UserRoleModel.dart';
import 'package:graduation_project/views/DashboardView.dart';
import 'package:graduation_project/views/InventoryView.dart';
import 'package:graduation_project/views/OrdersView.dart';
import 'package:graduation_project/views/ReportsPage.dart';
import 'package:graduation_project/main.dart';

class MainLayout extends StatefulWidget {
  final int initialIndex;

  const MainLayout({super.key, this.initialIndex = 0});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = AuthService.isSupervisor ? 0 : widget.initialIndex;
  }

  void _onSelect(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
  }

  List<Widget> _getPages() {
    if (AuthService.isSupervisor) {
      return const [
        InventoryPage(),
        OrdersPageWithPrint(),
        ReportsPageWithPrint(),
      ];
    }
    return const [
      DashboardPage(),
      InventoryPage(),
      ReportsPageWithPrint(),
      OrdersPageWithPrint(),
      Center(child: Text('Settings Page')),
    ];
  }

  List<_MenuItem> _getMenuItems() {
    if (AuthService.isSupervisor) {
      return [
        _MenuItem(Icons.inventory_2, 'Inventory', 0),
        _MenuItem(Icons.list_alt, 'Orders', 1),
        _MenuItem(Icons.bar_chart, 'Reports', 2),
      ];
    }
    return [
      _MenuItem(Icons.dashboard, 'Dashboard', 0),
      _MenuItem(Icons.inventory_2, 'Inventory', 1),
      _MenuItem(Icons.bar_chart, 'Reports', 2),
      _MenuItem(Icons.list_alt, 'Orders', 3),
      _MenuItem(Icons.settings, 'Settings', 4),
    ];
  }

  Future<void> _logout() async {
    await AuthService.logout();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pages = _getPages();
    final menuItems = _getMenuItems();

    return Scaffold(
      body: Row(
        children: [
          // ── Sidebar ──────────────────────────────────────────────────────
          Container(
            width: 220,
            padding: const EdgeInsets.symmetric(vertical: 18),
            color: isDark ? const Color(0xFF071014) : const Color(0xFFEAF2F3),
            child: Column(
              children: [
                // App brand + user name
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: isDark
                            ? const Color(0xFF0B2B2B)
                            : const Color(0xFFDDF3F3),
                        child: Icon(
                          Icons.local_pharmacy,
                          color: isDark ? Colors.white : Colors.black54,
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
                            Text(
                              AuthService.currentUser?.fullName ?? '',
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 6),

                // Role badge
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 14),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AuthService.isWarehouseManager
                        ? Colors.blue.withOpacity(0.15)
                        : Colors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    AuthService.isWarehouseManager ? 'Manager' : 'Supervisor',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AuthService.isWarehouseManager
                          ? Colors.blue
                          : Colors.green,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Nav items
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    children: menuItems.map((item) {
                      return _sidebarItem(
                        item.icon,
                        item.label,
                        item.index,
                        isDark,
                      );
                    }).toList(),
                  ),
                ),

                const Divider(height: 1),

                // Bottom toolbar
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          themeNotifier.value =
                              themeNotifier.value == ThemeMode.dark
                              ? ThemeMode.light
                              : ThemeMode.dark;
                        },
                        icon: Icon(
                          isDark ? Icons.light_mode : Icons.dark_mode,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                        tooltip: 'Toggle theme',
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => _logout(),
                        icon: Icon(
                          Icons.logout,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                        tooltip: 'Logout',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Page content ─────────────────────────────────────────────────
          Expanded(child: pages[_selectedIndex]),
        ],
      ),
    );
  }

  Widget _sidebarItem(IconData icon, String label, int index, bool isDark) {
    final selected = index == _selectedIndex;
    final selectedColor = isDark ? Colors.lightBlueAccent : Colors.blueAccent;
    final defaultColor = isDark ? Colors.white70 : Colors.black54;
    final textColor = selected
        ? selectedColor
        : (isDark ? Colors.white : Colors.black87);

    return ListTile(
      dense: true,
      leading: Icon(icon, color: selected ? selectedColor : defaultColor),
      title: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: selected,
      selectedTileColor: selectedColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onTap: () => _onSelect(index),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final int index;
  _MenuItem(this.icon, this.label, this.index);
}

// ─── Orders wrapper ───────────────────────────────────────────────────────────

class OrdersPageWithPrint extends StatelessWidget {
  const OrdersPageWithPrint({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (AuthService.isSupervisor)
          Container(
            padding: const EdgeInsets.all(14),
            color: Colors.blue.withOpacity(0.08),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Supervisor view — read-only. You may print orders.',
                    style: TextStyle(color: Colors.blue[900]),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: Stack(
            children: [
              const OrdersPage(),
              Positioned(
                top: 16,
                right: 16,
                child: FloatingActionButton.extended(
                  onPressed: () => _printOrders(context),
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

  void _printOrders(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Printing orders… (Print functionality)')),
    );
  }
}

// ─── Reports wrapper ──────────────────────────────────────────────────────────

class ReportsPageWithPrint extends StatelessWidget {
  const ReportsPageWithPrint({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (AuthService.isSupervisor)
          Container(
            padding: const EdgeInsets.all(14),
            color: Colors.blue.withOpacity(0.08),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Supervisor view — read-only. You may print reports.',
                    style: TextStyle(color: Colors.blue[900]),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: Stack(
            children: [
              const ReportsPage(),
              Positioned(
                top: 16,
                right: 16,
                child: FloatingActionButton.extended(
                  onPressed: () => _printReports(context),
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

  void _printReports(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Printing report… (Print functionality)')),
    );
  }
}
