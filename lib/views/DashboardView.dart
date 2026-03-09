import 'package:flutter/material.dart';
import 'package:graduation_project/Services/MaterialSerivce.dart';
import 'package:graduation_project/Services/alertService.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    // Refresh alerts when dashboard is loaded
    AlertService.refreshAlerts();
  }

  @override
  Widget build(BuildContext context) {
    final materials = MaterialService.getAllMaterials();
    final expiringSoonCount = AlertService.getExpiringSoonCount();
    final lowStockCount = AlertService.getLowStockCount();
    final criticalAlerts = AlertService.getCriticalAlerts();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
      child: SingleChildScrollView(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left column: KPI, Chart, Recent Activity
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
                            onPressed: () => _showNotifications(),
                            icon: const Icon(Icons.notifications_none),
                          ),
                          if (criticalAlerts.isNotEmpty)
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
                                  criticalAlerts.length.toString(),
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
                      const CircleAvatar(child: Icon(Icons.person)),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Title + actions
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
                        onPressed: () {},
                        icon: const Icon(Icons.add),
                        label: const Text('Add Stock'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () {},
                        child: const Text('Issue Stock'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () {},
                        child: const Text('View Full Report'),
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
                          materials.length.toString(),
                          icon: Icons.grid_view,
                        ),
                        const SizedBox(width: 12),
                        _kpiCard(
                          context,
                          'Nearing Expiry',
                          expiringSoonCount.toString(),
                          icon: Icons.hourglass_bottom,
                          color: expiringSoonCount > 0 ? Colors.orange : null,
                        ),
                        const SizedBox(width: 12),
                        _kpiCard(
                          context,
                          'Low Stock Items',
                          lowStockCount.toString(),
                          icon: Icons.warning_amber_rounded,
                          color: lowStockCount > 0 ? Colors.yellow[700] : null,
                        ),
                        const SizedBox(width: 12),
                        _kpiCard(
                          context,
                          'Total Alerts',
                          AlertService.getAllAlerts().length.toString(),
                          icon: Icons.notifications_active,
                          color: criticalAlerts.isNotEmpty ? Colors.red : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Chart
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

                  // Recent Activity
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
                          'Recent Activity',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        _activityRow(
                          'Paracetamol 500mg',
                          'Received',
                          '500 units',
                          '2024-07-21',
                          'Admin',
                        ),
                        const Divider(),
                        _activityRow(
                          'Amoxicillin 250mg',
                          'Issued',
                          '150 units',
                          '2024-07-20',
                          'Admin',
                        ),
                        const Divider(),
                        _activityRow(
                          'Ibuprofen 400mg',
                          'Issued',
                          '200 units',
                          '2024-07-20',
                          'Admin',
                        ),
                        const Divider(),
                        _activityRow(
                          'Saline Solution',
                          'Received',
                          '50 units',
                          '2024-07-19',
                          'Admin',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Right column: Critical Alerts
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
                      if (criticalAlerts.isNotEmpty)
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
                            criticalAlerts.length.toString(),
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
                      child: const Center(child: Text('No critical alerts')),
                    )
                  else
                    ...criticalAlerts.take(5).map((alert) {
                      Color color;
                      IconData icon;

                      if (alert.alertType == 'expired') {
                        color = Colors.redAccent;
                        icon = Icons.error_outline;
                      } else {
                        color = Colors.orangeAccent;
                        icon = Icons.warning_amber_rounded;
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _alertCard(
                          context,
                          alert.material?.name ?? 'Alert',
                          alert.message,
                          icon,
                          color,
                        ),
                      );
                    }).toList(),
                ],
              ),
            ),
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

  Widget _activityRow(
    String item,
    String type,
    String quantity,
    String date,
    String user,
  ) {
    final typeColor = type == 'Received' ? Colors.green : Colors.blue;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(item)),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(type, style: TextStyle(color: typeColor)),
            ),
          ),
          Expanded(flex: 2, child: Text(quantity)),
          Expanded(flex: 2, child: Text(date)),
          Expanded(flex: 1, child: Text(user)),
        ],
      ),
    );
  }

  void _showNotifications() {
    final alerts = AlertService.getCriticalAlerts();

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
              ? const Text('No critical notifications')
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
                            : Colors.orange,
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
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Navigate to reports page
            },
            child: const Text('View All'),
          ),
        ],
      ),
    );
  }
}
