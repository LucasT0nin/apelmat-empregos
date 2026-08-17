import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({
    required this.apiClient,
    this.onOpenContactRequests,
    this.onOpenResumes,
    super.key,
  });

  final ApiClient apiClient;
  final VoidCallback? onOpenContactRequests;
  final VoidCallback? onOpenResumes;

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late Future<List<AppNotification>> _future;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _future = _load();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        setState(() => _future = _load());
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<List<AppNotification>> _load() async {
    final payload =
        await widget.apiClient.get('/marketplace/notifications/')
            as Map<String, dynamic>;
    final items = payload['results'] as List<dynamic>;
    return items
        .map((item) => AppNotification.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Avisos'),
        actions: [
          TextButton(onPressed: _markAllRead, child: const Text('Ler todos')),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<AppNotification>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const _NotificationMessage(
                icon: Icons.cloud_off_outlined,
                title: 'Nao foi possivel carregar os avisos.',
                body: 'Confira o servidor e puxe para atualizar.',
              );
            }
            final notifications = snapshot.data ?? [];
            if (notifications.isEmpty) {
              return const _NotificationMessage(
                icon: Icons.notifications_none,
                title: 'Nenhum aviso ainda.',
                body:
                    'Analises de curriculo e contatos liberados aparecem aqui.',
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemCount: notifications.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return Card(
                  color:
                      notification.isRead
                          ? null
                          : Theme.of(context).colorScheme.primaryContainer,
                  child: ListTile(
                    onTap: () => _openNotification(notification),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.goldSoft,
                      foregroundColor: AppColors.goldDark,
                      child: Icon(notification.icon),
                    ),
                    title: Text(
                      notification.title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(notification.body),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _openNotification(AppNotification notification) async {
    if (!notification.isRead) {
      await widget.apiClient.post(
        '/marketplace/notifications/${notification.id}/read/',
      );
    }
    final openContactRequests = widget.onOpenContactRequests;
    final openResumes = widget.onOpenResumes;
    if (notification.kind == 'contact_request' &&
        notification.contactRequestId != null &&
        openContactRequests != null) {
      openContactRequests();
      await _refresh();
      return;
    }
    if (notification.kind == 'profile_review' &&
        notification.professionalId != null &&
        openResumes != null) {
      openResumes();
      await _refresh();
      return;
    }
    if (mounted) {
      await showDialog<void>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text(notification.title),
              content: Text(notification.body),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Entendi'),
                ),
              ],
            ),
      );
    }
    await _refresh();
  }

  Future<void> _markAllRead() async {
    await widget.apiClient.post('/marketplace/notifications/read-all/');
    await _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.isRead,
    this.professionalId,
    this.contactRequestId,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      kind: json['kind'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      isRead: json['is_read'] as bool? ?? false,
      professionalId: json['professional'] as String?,
      contactRequestId: json['contact_request'] as String?,
    );
  }

  final String id;
  final String kind;
  final String title;
  final String body;
  final bool isRead;
  final String? professionalId;
  final String? contactRequestId;

  IconData get icon {
    return switch (kind) {
      'new_resume' => Icons.description_outlined,
      'new_opportunity' => Icons.work_outline,
      'application' => Icons.person_add_alt_1,
      'application_status' => Icons.fact_check_outlined,
      'profile_review' => Icons.verified_outlined,
      'contact_request' => Icons.assignment_outlined,
      'contact_released' => Icons.lock_open_outlined,
      'contact_rejected' => Icons.block_outlined,
      _ => Icons.notifications_none,
    };
  }
}

class _NotificationMessage extends StatelessWidget {
  const _NotificationMessage({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(28),
      children: [
        const SizedBox(height: 110),
        Icon(icon, size: 58),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(body, textAlign: TextAlign.center),
      ],
    );
  }
}
