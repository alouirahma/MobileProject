import 'package:flutter/material.dart';
import 'package:mobile2025/Services/database_helper.dart';

class NotificationsScreen extends StatefulWidget {
  final String userId;
  final List<Map<String, dynamic>> notifications;

  const NotificationsScreen({super.key, required this.userId, required this.notifications});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late List<Map<String, dynamic>> _notifications;

  @override
  void initState() {
    super.initState();
    _notifications = List<Map<String, dynamic>>.from(widget.notifications);
  }

  Future<void> _markAsRead(int id) async {
    await DatabaseHelper().markNotificationsRead([id]);
    setState(() {
      _notifications.removeWhere((notif) => notif['id'] == id);
    });
  }

  void _openNotification(Map<String, dynamic> notif) {
    Navigator.pop(context, notif);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: _notifications.isEmpty
          ? const Center(child: Text('Aucune notification'))
          : ListView.separated(
              itemCount: _notifications.length,
              separatorBuilder: (_, __) => const Divider(height: 0),
              itemBuilder: (context, index) {
                final notif = _notifications[index];
                final title = notif['title'] as String? ?? 'Notification';
                final body = notif['body'] as String? ?? '';
                final date = notif['date'] as String? ?? '';
                final id = notif['id'] as int?;

                return ListTile(
                  title: Text(title),
                  subtitle: Text(body),
                  trailing: Text(_formatDate(date), style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  onTap: () {
                    if (id != null) {
                      _markAsRead(id);
                    }
                    _openNotification(notif);
                  },
                );
              },
            ),
    );
  }

  String _formatDate(String iso) {
    try {
      final date = DateTime.parse(iso);
      return '${date.day}/${date.month} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}
