import 'package:flutter/material.dart';
import 'package:graduation_project/Models/app_version.dart';
import 'package:graduation_project/Services/update_service.dart';

class UpdateCheckScope extends StatefulWidget {
  final Widget child;

  const UpdateCheckScope({super.key, required this.child});

  @override
  State<UpdateCheckScope> createState() => _UpdateCheckScopeState();
}

class _UpdateCheckScopeState extends State<UpdateCheckScope> {
  @override
  void initState() {
    super.initState();
    _checkForUpdate();
  }

  Future<void> _checkForUpdate() async {
    await Future.delayed(const Duration(seconds: 2));

    final available = await UpdateService.isUpdateAvailable();
    if (!available || !mounted) return;

    final remote = await UpdateService.fetchLatestVersion();
    if (remote == null || !mounted) return;

    showDialog(
      context: context,
      barrierDismissible: !remote.mandatory,
      builder: (_) => UpdateDialog(version: remote),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class UpdateDialog extends StatelessWidget {
  final AppVersion version;

  const UpdateDialog({super.key, required this.version});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1B2430) : Colors.white;

    return PopScope(
      canPop: !version.mandatory,
      child: Dialog(
        insetPadding: const EdgeInsets.all(24),
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildIcon(isDark),
              const SizedBox(height: 18),
              Text(
                'Update Available',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Version ${version.latestVersion} is now available.',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              if (version.releaseNotes.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'What\'s new:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...version.releaseNotes.map(
                        (note) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• ', style: TextStyle(fontSize: 13)),
                              Expanded(
                                child: Text(
                                  note,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black54,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: () => _download(context),
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Update Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A6B6E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              if (!version.mandatory) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Maybe Later'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(bool isDark) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF0A6B6E).withOpacity(0.1),
      ),
      child: const Icon(
        Icons.system_update_rounded,
        size: 36,
        color: Color(0xFF0A6B6E),
      ),
    );
  }

  Future<void> _download(BuildContext context) async {
    final url = version.downloadUrl;
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Download URL not configured.')),
      );
      return;
    }
    await UpdateService.openDownloadUrl(url);
    if (!version.mandatory && context.mounted) {
      Navigator.pop(context);
    }
  }
}
