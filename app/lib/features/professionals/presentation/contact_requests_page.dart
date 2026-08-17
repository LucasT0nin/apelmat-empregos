import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/external/external_actions.dart';
import '../../../core/files/resume_downloader.dart';
import '../../../core/theme/app_theme.dart';

class ContactRequestsPage extends StatefulWidget {
  const ContactRequestsPage({required this.apiClient, super.key});

  final ApiClient apiClient;

  @override
  State<ContactRequestsPage> createState() => _ContactRequestsPageState();
}

class _ContactRequestsPageState extends State<ContactRequestsPage> {
  late Future<List<ContactRequestItem>> _future;
  String? _busyId;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<ContactRequestItem>> _load() async {
    final payload =
        await widget.apiClient.get('/marketplace/contact-requests/')
            as Map<String, dynamic>;
    final items = payload['results'] as List<dynamic>;
    return items
        .map(
          (item) => ContactRequestItem.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Solicitacoes')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<ContactRequestItem>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _MessageState(
                icon: Icons.cloud_off_outlined,
                title: 'Nao foi possivel carregar.',
                body: 'Confira o servidor e puxe para atualizar.',
                onRetry: _refresh,
              );
            }
            final requests = snapshot.data ?? [];
            if (requests.isEmpty) {
              return const _MessageState(
                icon: Icons.assignment_outlined,
                title: 'Nenhuma solicitacao ainda.',
                body:
                    'Quando sua empresa solicitar um contato, o status aparece aqui.',
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemCount: requests.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final request = requests[index];
                return _ContactRequestCard(
                  item: request,
                  busy: _busyId == request.id,
                  onWhatsApp: () => _whatsApp(request),
                  onEmail: () => _email(request),
                  onDownload: () => _download(request),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  Future<void> _whatsApp(ContactRequestItem item) async {
    final phone = item.professionalPhone;
    if (phone == null || phone.isEmpty) {
      _show('WhatsApp ainda nao foi liberado.');
      return;
    }
    try {
      await openWhatsApp(
        phone,
        message:
            'Ola, ${item.professionalName}. Recebi seu contato pela Apelmat Empregos.',
      );
    } catch (error) {
      _show(error.toString());
    }
  }

  Future<void> _email(ContactRequestItem item) async {
    final email = item.professionalEmail;
    if (email == null || email.isEmpty) {
      _show('E-mail ainda nao foi liberado.');
      return;
    }
    try {
      await openEmail(
        email,
        subject: 'Contato pela Apelmat Empregos',
        body:
            'Ola, ${item.professionalName}. Recebi seu contato pela Apelmat Empregos.',
      );
    } catch (error) {
      _show(error.toString());
    }
  }

  Future<void> _download(ContactRequestItem item) async {
    final url = item.resumeDownloadUrl;
    if (url == null) {
      _show('Curriculo ainda nao foi liberado.');
      return;
    }
    setState(() => _busyId = item.id);
    try {
      await downloadResume(
        apiClient: widget.apiClient,
        url: url,
        professionalName: item.professionalName,
      );
      _show('Curriculo salvo no celular.');
    } catch (error) {
      _show(error.toString());
    } finally {
      if (mounted) {
        setState(() => _busyId = null);
      }
    }
  }

  void _show(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

class ContactRequestItem {
  const ContactRequestItem({
    required this.id,
    required this.professionalName,
    required this.professionalCity,
    required this.professionalState,
    required this.status,
    required this.statusLabel,
    required this.roleLabel,
    this.professionalEmail,
    this.professionalPhone,
    this.resumeDownloadUrl,
  });

  factory ContactRequestItem.fromJson(Map<String, dynamic> json) {
    return ContactRequestItem(
      id: json['id'] as String,
      professionalName: json['professional_name'] as String? ?? '',
      professionalCity: json['professional_city'] as String? ?? '',
      professionalState: json['professional_state'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      statusLabel: json['status_label'] as String? ?? 'Em analise',
      roleLabel: json['role_label'] as String? ?? 'Perfil profissional',
      professionalEmail: json['professional_email'] as String?,
      professionalPhone: json['professional_phone'] as String?,
      resumeDownloadUrl: json['resume_download_url'] as String?,
    );
  }

  final String id;
  final String professionalName;
  final String professionalCity;
  final String professionalState;
  final String status;
  final String statusLabel;
  final String roleLabel;
  final String? professionalEmail;
  final String? professionalPhone;
  final String? resumeDownloadUrl;

  bool get approved => status == 'approved';
}

class _ContactRequestCard extends StatelessWidget {
  const _ContactRequestCard({
    required this.item,
    required this.busy,
    required this.onWhatsApp,
    required this.onEmail,
    required this.onDownload,
  });

  final ContactRequestItem item;
  final bool busy;
  final VoidCallback onWhatsApp;
  final VoidCallback onEmail;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final location = [
      item.professionalCity,
      item.professionalState,
    ].where((part) => part.isNotEmpty).join(' - ');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppColors.goldSoft,
                  foregroundColor: AppColors.goldDark,
                  child: Icon(Icons.person_outline),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.professionalName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (location.isNotEmpty)
                        Text(
                          location,
                          style: const TextStyle(color: AppColors.muted),
                        ),
                    ],
                  ),
                ),
                _StatusPill(status: item.status, label: item.statusLabel),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              item.roleLabel,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              item.approved
                  ? 'Contato liberado pela Apelmat.'
                  : 'Sua solicitacao esta aguardando analise da Apelmat.',
              style: const TextStyle(color: AppColors.muted),
            ),
            if (item.approved) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: onWhatsApp,
                    icon: const Icon(Icons.chat_outlined),
                    label: const Text('WhatsApp'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onEmail,
                    icon: const Icon(Icons.email_outlined),
                    label: const Text('E-mail'),
                  ),
                  OutlinedButton.icon(
                    onPressed: busy ? null : onDownload,
                    icon:
                        busy
                            ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Icon(Icons.download_outlined),
                    label: const Text('Curriculo'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status, required this.label});

  final String status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final approved = status == 'approved';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: approved ? AppColors.goldSoft : const Color(0xFFF8F5ED),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: approved ? AppColors.goldDark : AppColors.muted,
          fontWeight: FontWeight.w900,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.body,
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String body;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(28),
      children: [
        const SizedBox(height: 90),
        Icon(icon, size: 58, color: AppColors.goldDark),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(body, textAlign: TextAlign.center),
        if (onRetry != null) ...[
          const SizedBox(height: 18),
          OutlinedButton(
            onPressed: onRetry,
            child: const Text('Tentar novamente'),
          ),
        ],
      ],
    );
  }
}
