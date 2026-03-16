// features/notifications/pages/notifications_page.dart — Historial de notificaciones
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/notifications_provider.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          if (notifications.isNotEmpty)
            TextButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                ref.read(notificationsProvider.notifier).clearAll();
              },
              child: const Text('Limpiar'),
            ),
        ],
      ),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none_rounded,
                      size: 64,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text(
                    'Sin notificaciones',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final n = notifications[i];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(ctx).colorScheme.primaryContainer,
                    child: Icon(Icons.notifications_active_rounded,
                        color: Theme.of(ctx).colorScheme.primary, size: 20),
                  ),
                  title: Text(n.title),
                  subtitle: Text(n.body),
                  trailing: Text(
                    DateFormat('dd/MM HH:mm').format(n.receivedAt),
                    style: Theme.of(ctx).textTheme.labelSmall,
                  ),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(notificationsProvider.notifier).markRead(n.id);
                  },
                );
              },
            ),
    );
  }
}
