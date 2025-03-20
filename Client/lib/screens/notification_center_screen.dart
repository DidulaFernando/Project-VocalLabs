import 'package:flutter/material.dart';
import 'package:vocallabs_flutter_app/utils/constants.dart';
import 'package:vocallabs_flutter_app/widgets/card_layout.dart';
import 'package:intl/intl.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  final List<Map<String, dynamic>> _notifications = [
    {
      'title': 'New Analysis Complete',
      'message':
          'Your speech "Project Presentation" has been analyzed. Check your results!',
      'date': DateTime.now().subtract(const Duration(hours: 2)),
      'isRead': false,
      'type': 'analysis',
    },
    {
      'title': 'Weekly Progress Report',
      'message':
          'Your speaking skills have improved by 5% this week. Keep up the good work!',
      'date': DateTime.now().subtract(const Duration(days: 1)),
      'isRead': true,
      'type': 'progress',
    },
    {
      'title': 'Practice Reminder',
      'message':
          'It\'s been 3 days since your last practice session. Schedule a new recording to maintain your progress.',
      'date': DateTime.now().subtract(const Duration(days: 2)),
      'isRead': true,
      'type': 'reminder',
    },
    {
      'title': 'Tip of the Day',
      'message':
          'Try pausing for 2 seconds before making important points to increase impact.',
      'date': DateTime.now().subtract(const Duration(days: 3)),
      'isRead': false,
      'type': 'tip',
    },
    {
      'title': 'New Feature Available',
      'message':
          'We\'ve added pitch analysis to help you improve vocal modulation. Try it now!',
      'date': DateTime.now().subtract(const Duration(days: 5)),
      'isRead': true,
      'type': 'update',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                for (final notification in _notifications) {
                  notification['isRead'] = true;
                }
              });
            },
            child: const Text('Mark All Read'),
          ),
        ],
      ),
      body:
          _notifications.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                padding: AppPadding.screenPadding,
                itemCount: _notifications.length,
                itemBuilder: (context, index) {
                  final notification = _notifications[index];
                  return _buildNotificationItem(
                    title: notification['title'],
                    message: notification['message'],
                    date: notification['date'],
                    isRead: notification['isRead'],
                    type: notification['type'],
                    onTap: () {
                      setState(() {
                        notification['isRead'] = true;
                      });
                      // Handle notification tap based on type
                    },
                    onDismiss: () {
                      setState(() {
                        _notifications.removeAt(index);
                      });
                    },
                  );
                },
              ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('No Notifications', style: AppTextStyles.heading2),
          const SizedBox(height: 8),
          const Text('You\'re all caught up!', style: AppTextStyles.body2),
        ],
      ),
    );
  }

  Widget _buildNotificationItem({
    required String title,
    required String message,
    required DateTime date,
    required bool isRead,
    required String type,
    required VoidCallback onTap,
    required VoidCallback onDismiss,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: Key(title + date.toString()),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        onDismissed: (direction) {
          onDismiss();
        },
        child: CardLayout(
          onTap: onTap,
          backgroundColor:
              isRead ? null : AppColors.primaryBlue.withOpacity(0.05),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _getNotificationColor(type).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    _getNotificationIcon(type),
                    color: _getNotificationColor(type),
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: AppTextStyles.body1.copyWith(
                              fontWeight:
                                  isRead ? FontWeight.normal : FontWeight.bold,
                            ),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primaryBlue,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: AppTextStyles.body2,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(date),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.lightText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'analysis':
        return Icons.analytics_outlined;
      case 'progress':
        return Icons.trending_up;
      case 'reminder':
        return Icons.alarm;
      case 'tip':
        return Icons.lightbulb_outline;
      case 'update':
        return Icons.new_releases_outlined;
      default:
        return Icons.notifications_none;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'analysis':
        return AppColors.primaryBlue;
      case 'progress':
        return AppColors.success;
      case 'reminder':
        return AppColors.warning;
      case 'tip':
        return AppColors.accent;
      case 'update':
        return Colors.purple;
      default:
        return AppColors.primaryBlue;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }
}
