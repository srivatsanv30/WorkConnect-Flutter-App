import 'dart:async';
import 'package:flutter/material.dart';
import 'notification_service.dart';
import 'notifications_screen.dart';

class NotificationBell extends StatefulWidget {
  final String currentUserId;
  const NotificationBell({super.key, required this.currentUserId});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  final _notificationService = NotificationService();
  int _unreadCount = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchCount();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchCount());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchCount() async {
    final list = await _notificationService.fetchNotifications();
    final count = list.where((n) => n['read'] != true).length;
    if (mounted) {
      setState(() => _unreadCount = count);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => NotificationsScreen(currentUserId: widget.currentUserId),
              ),
            ).then((_) => _fetchCount());
          },
        ),
        if (_unreadCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                '$_unreadCount',
                style: TextStyle(
                  color: Theme.of(context).cardColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
