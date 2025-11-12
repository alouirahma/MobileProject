import 'package:flutter/material.dart';
import 'package:mobile2025/Entites/content.dart';
import 'package:mobile2025/Services/database_helper.dart';
import 'package:mobile2025/Screens/reviews_screen.dart';

class NotificationScreen extends StatefulWidget {
  final String currentUserId;

  const NotificationScreen({super.key, required this.currentUserId});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  bool _isLoading = true;
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    final data = await _db.getNotifications(widget.currentUserId);
    if (mounted) {
      setState(() {
        _notifications = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _openNotification(Map<String, dynamic> notif) async {
    final id = notif['id'] as int?;
    if (id != null) {
      await _db.markNotificationsRead([id]);
    }

    final contentId = notif['contentId'] as String?;
    final reviewId = notif['reviewId'] as String?;
    if (contentId != null) {
      final contentMap = await _db.getContentById(contentId);
      if (contentMap != null && mounted) {
        final content = Content.fromMap(contentMap);
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (ctx) => ReviewsScreen(
              content: content,
              currentUserId: widget.currentUserId,
              preselectedReviewId: reviewId,
            ),
          ),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Contenu introuvable.')),
          );
        }
      }
    }
    await _loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadNotifications,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(child: Text('Aucune notification'))
              : ListView.builder(
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notif = _notifications[index];
                    final isRead = (notif['isRead'] as int? ?? 0) == 1;
                    final date = _formatDate(notif['date'] as String?);
                    return ListTile(
                      leading: Icon(
                        isRead ? Icons.notifications_none : Icons.notifications,
                        color: isRead ? Colors.grey : Theme.of(context).colorScheme.primary,
                      ),
                      title: Text(notif['title'] as String? ?? 'Notification'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(notif['body'] as String? ?? ''),
                          const SizedBox(height: 4),
                          Text(date, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                        ],
                      ),
                      trailing: isRead
                          ? null
                          : Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: Colors.redAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                      onTap: () => _openNotification(notif),
                    );
                  },
                ),
    );
  }

  String _formatDate(String? iso) {
    if (iso == null) return '';
    try {
      final date = DateTime.parse(iso);
      final today = DateTime.now();
      if (date.year == today.year && date.month == today.month && date.day == today.day) {
        return 'Aujourd\'hui ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      }
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}
