import 'package:flutter/material.dart';
import 'package:graduation_project/Models/ProductProvider.dart';
import 'package:graduation_project/Models/UserRoleModel.dart';
import 'package:graduation_project/Models/materialModel.dart';
import 'package:graduation_project/Services/notificationService.dart';
import 'package:graduation_project/Services/alertService.dart';
import 'package:graduation_project/views/UserInfo.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    NotificationService.changes.addListener(_handleNotificationChange);
  }

  @override
  void dispose() {
    NotificationService.changes.removeListener(_handleNotificationChange);
    super.dispose();
  }

  void _handleNotificationChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final provider = ProductProvider.of(context);
    final expiringSoonCount = provider.expiringSoonCount;
    final lowStockCount = provider.lowStockCount;
    final criticalAlertsCount = provider.getCriticalAlertsCount();
    final criticalAlerts = AlertService.getCriticalAlerts();
    final unreadNotifications = NotificationService.getUnread();
    final bellCount = AuthService.isSupervisor
        ? unreadNotifications.length
        : criticalAlertsCount;
    final recentMaterials = _recentMaterials(provider.products);
    final roleColor = AuthService.isWarehouseManager
        ? Colors.blue
        : Colors.green;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
      child: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left column
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Topbar
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText:
                                      'Search for materials, orders, or reports',
                                  prefixIcon: const Icon(Icons.search),
                                  filled: true,
                                  fillColor: Theme.of(context).cardColor,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Stack(
                              children: [
                                IconButton(
                                  onPressed: _showNotifications,
                                  icon: const Icon(Icons.notifications_none),
                                ),
                                if (bellCount > 0)
                                  Positioned(
                                    right: 8,
                                    top: 8,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 16,
                                        minHeight: 16,
                                      ),
                                      child: Text(
                                        bellCount.toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              customBorder: const CircleBorder(),
                              onTap: _showProfilePopup,
                              child: CircleAvatar(
                                backgroundColor: roleColor.withOpacity(0.16),
                                child: Text(
                                  _profileInitial(),
                                  style: TextStyle(
                                    color: roleColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Title
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Warehouse Overview',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () => provider.loadProducts(),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Refresh'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // KPI row
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _kpiCard(
                                context,
                                'Total Materials',
                                provider.totalProducts.toString(),
                                icon: Icons.grid_view,
                              ),
                              if (AuthService.isWarehouseManager) ...[
                                const SizedBox(width: 12),
                                _kpiCard(
                                  context,
                                  'Nearing Expiry',
                                  expiringSoonCount.toString(),
                                  icon: Icons.hourglass_bottom,
                                  color: expiringSoonCount > 0
                                      ? Colors.orange
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                _kpiCard(
                                  context,
                                  'Low Stock Items',
                                  lowStockCount.toString(),
                                  icon: Icons.warning_amber_rounded,
                                  color: lowStockCount > 0
                                      ? Colors.yellow[700]
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                _kpiCard(
                                  context,
                                  'Critical Alerts',
                                  criticalAlertsCount.toString(),
                                  icon: Icons.notifications_active,
                                  color: criticalAlertsCount > 0
                                      ? Colors.red
                                      : null,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Chart placeholder
                        Container(
                          height: 240,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Theme.of(context).cardColor,
                          ),
                          child: const Center(
                            child: Text('Chart Visualization Placeholder'),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Recent Activity (shows top materials from API)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Theme.of(context).cardColor,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Recent Materials',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 12),
                              ...recentMaterials.map(
                                (m) => Column(
                                  children: [
                                    _materialRow(
                                      m.name,
                                      '${m.quantity} units',
                                      m.expiryDate,
                                      m.category,
                                    ),
                                    const Divider(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (AuthService.isWarehouseManager) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Critical Alerts',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              const Spacer(),
                              if (criticalAlertsCount > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    criticalAlertsCount.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (criticalAlerts.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Theme.of(context).cardColor,
                              ),
                              child: const Center(
                                child: Text('No critical alerts'),
                              ),
                            )
                          else
                            ...criticalAlerts.take(5).map((alert) {
                              final isExpired = alert.alertType == 'expired';
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _alertCard(
                                  context,
                                  alert.material?.name ?? 'Alert',
                                  alert.message,
                                  isExpired
                                      ? Icons.error_outline
                                      : Icons.warning_amber_rounded,
                                  isExpired
                                      ? Colors.redAccent
                                      : Colors.orangeAccent,
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _kpiCard(
    BuildContext context,
    String title,
    String value, {
    required IconData icon,
    Color? color,
  }) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).cardColor,
        border: color != null
            ? Border.all(color: color.withOpacity(0.3))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[400]
                  : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _alertCard(
    BuildContext context,
    String title,
    String body,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Theme.of(context).cardColor,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[400]
                        : Colors.grey[600],
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<MaterialModel> _recentMaterials(List<MaterialModel> products) {
    final materials = products.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return materials.take(5).toList();
  }

  Widget _materialRow(
    String name,
    String quantity,
    String expiryDate,
    String category,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(name)),
          Expanded(flex: 2, child: Text(quantity)),
          Expanded(flex: 2, child: Text(expiryDate)),
          Expanded(flex: 2, child: Text(category)),
        ],
      ),
    );
  }

  String _profileInitial() {
    final name = AuthService.currentUser?.fullName.trim() ?? '';
    if (name.isEmpty) return '?';
    return name.substring(0, 1).toUpperCase();
  }

  void _showNotifications() {
    if (AuthService.isSupervisor) {
      final notifications = NotificationService.getAll();
      showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.notifications_active, color: Colors.green),
                const SizedBox(width: 12),
                Text(
                  'Notifications (${NotificationService.getUnread().length})',
                ),
              ],
            ),
            content: SizedBox(
              width: 460,
              child: notifications.isEmpty
                  ? const Text('No notifications')
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final item = notifications[index];
                        return ListTile(
                          leading: Icon(
                            item.isRead
                                ? Icons.mark_email_read_outlined
                                : Icons.mark_email_unread_outlined,
                            color: item.isRead ? Colors.grey : Colors.green,
                          ),
                          title: Text(item.title),
                          subtitle: Text(
                            '${item.body}\n${item.createdAt.toLocal().toString().substring(0, 16)}',
                          ),
                          isThreeLine: true,
                          trailing: item.isRead
                              ? null
                              : TextButton(
                                  onPressed: () {
                                    NotificationService.markRead(item.id);
                                    setState(() {});
                                    setDialogState(() {});
                                  },
                                  child: const Text('Mark Read'),
                                ),
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  NotificationService.markAllRead();
                  setState(() {});
                  Navigator.pop(ctx);
                },
                child: const Text('Mark All Read'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      );
      return;
    }

    final alerts = AlertService.getAllAlerts();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.notifications_active, color: Colors.red),
            const SizedBox(width: 12),
            Text('Notifications (${alerts.length})'),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: alerts.isEmpty
              ? const Text('No active notifications')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: alerts.length,
                  itemBuilder: (context, index) {
                    final alert = alerts[index];
                    return ListTile(
                      leading: Icon(
                        alert.alertType == 'expired'
                            ? Icons.error
                            : Icons.warning_amber_rounded,
                        color: alert.alertType == 'expired'
                            ? Colors.red
                            : alert.alertType == 'expiring_soon'
                            ? Colors.orange
                            : Colors.blue,
                      ),
                      title: Text(alert.material?.name ?? 'Alert'),
                      subtitle: Text(alert.message),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showProfilePopup() {
    final user = AuthService.currentUser;
    final isManager = AuthService.isWarehouseManager;
    final roleColor = isManager ? Colors.blue : Colors.green;
    final roleText = isManager ? 'Warehouse Manager' : 'Supervisor';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        alignment: Alignment.topRight,
        insetPadding: const EdgeInsets.only(top: 72, right: 36),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: roleColor.withOpacity(0.12),
                  child: Text(
                    _profileInitial(),
                    style: TextStyle(
                      color: roleColor,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user?.fullName ?? 'Unknown user',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: roleColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: roleColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    roleText,
                    style: TextStyle(
                      color: roleColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const UserInfoPage(showBackButton: true),
                        ),
                      );
                    },
                    child: const Text('More ->'),
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
