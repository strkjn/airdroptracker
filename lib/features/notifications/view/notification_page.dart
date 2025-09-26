import 'package:airdrop_flow/core/providers/firebase_providers.dart';
import 'package:airdrop_flow/core/widgets/app_background.dart'; // <-- IMPORT BARU
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class NotificationPage extends ConsumerWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsStreamProvider);

    return AppBackground( // <-- WIDGET DITAMBAHKAN
      child: Scaffold(
        backgroundColor: Colors.transparent, // <-- MODIFIKASI
        appBar: AppBar(
          title: const Text('Notifikasi'),
          backgroundColor: Colors.transparent, // <-- Tambahan
          elevation: 0, // <-- Tambahan
        ),
        body: notificationsAsync.when(
          data: (notifications) {
            if (notifications.isEmpty) {
              return const Center(
                child: Text(
                  'Belum ada notifikasi.',
                  style: TextStyle(fontSize: 16),
                ),
              );
            }
            return ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                final isRead = notification.isRead;
                
                final timeAgo = Text(
                  _formatTimestamp(notification.timestamp),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isRead ? Colors.grey : Colors.white70,
                      ),
                );

                return Opacity(
                  opacity: isRead ? 0.7 : 1.0,
                  child: ListTile(
                    leading: isRead
                        ? const Icon(Icons.mark_email_read_outlined, color: Colors.grey)
                        : Icon(Icons.mark_email_unread_outlined, color: Theme.of(context).colorScheme.secondary),
                    title: Text(
                      notification.title,
                      style: TextStyle(
                        fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(notification.body),
                    trailing: timeAgo,
                    onTap: () {
                      if (!isRead) {
                        ref.read(firestoreServiceProvider).markNotificationAsRead(notification.id);
                      }
                    },
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Gagal memuat notifikasi: $err')),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 1) {
      return DateFormat('d MMM', 'id_ID').format(timestamp);
    } else if (difference.inHours >= 24) {
      return 'Kemarin';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours} jam yang lalu';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes} mnt yang lalu';
    } else {
      return 'Baru saja';
    }
  }
}