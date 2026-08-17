import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/external/external_actions.dart';
import '../../../core/files/resume_downloader.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/professional_item.dart';

class ProfessionalsPage extends StatefulWidget {
  const ProfessionalsPage({required this.apiClient, super.key});

  final ApiClient apiClient;

  @override
  State<ProfessionalsPage> createState() => _ProfessionalsPageState();
}

class _ProfessionalsPageState extends State<ProfessionalsPage> {
  final _searchController = TextEditingController();
  late Future<List<ProfessionalItem>> _future;
  String? _busyProfessionalId;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<ProfessionalItem>> _load() async {
    final payload = await widget.apiClient.get(
      '/accounts/professionals/',
      queryParameters: {
        if (_searchController.text.trim().isNotEmpty)
          'search': _searchController.text.trim(),
      },
    );
    final items =
        payload is Map<String, dynamic>
            ? payload['results'] as List<dynamic>
            : payload as List<dynamic>;
    return items
        .map((item) => ProfessionalItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Catalogo Apelmat')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Buscar por nome, cidade ou experiencia',
              leading: const Icon(Icons.search),
              trailing: [
                IconButton(
                  onPressed: _refresh,
                  icon: const Icon(Icons.arrow_forward),
                ),
              ],
              onSubmitted: (_) => _refresh(),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: FutureBuilder<List<ProfessionalItem>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final professionals = snapshot.data ?? [];
                  if (snapshot.hasError || professionals.isEmpty) {
                    return ListView(
                      padding: const EdgeInsets.all(28),
                      children: [
                        const SizedBox(height: 100),
                        const Icon(Icons.person_search_outlined, size: 56),
                        const SizedBox(height: 14),
                        Text(
                          snapshot.hasError
                              ? 'Nao foi possivel carregar o catalogo.'
                              : 'Nenhum profissional publicado ainda.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: professionals.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final professional = professionals[index];
                      return _ProfessionalCard(
                        professional: professional,
                        busy: _busyProfessionalId == professional.userId,
                        onRequest: () => _requestContact(professional),
                        onWhatsApp: () => _whatsApp(professional),
                        onEmail: () => _email(professional),
                        onDownload: () => _download(professional),
                        onReport: () => _report(professional),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  Future<void> _requestContact(ProfessionalItem professional) async {
    setState(() => _busyProfessionalId = professional.userId);
    try {
      await widget.apiClient.post(
        '/marketplace/contact-requests/',
        body: {
          'professional': professional.userId,
          if (professional.objectives.isNotEmpty)
            'objective': professional.objectives.first.id,
        },
      );
      _show('Solicitacao enviada para analise da Apelmat.');
      await _refresh();
    } on ApiException catch (error) {
      _show(error.message);
      await _refresh();
    } finally {
      if (mounted) {
        setState(() => _busyProfessionalId = null);
      }
    }
  }

  Future<void> _download(ProfessionalItem professional) async {
    final url = professional.resumeDownloadUrl;
    if (url == null) {
      _show('Curriculo ainda nao liberado pela Apelmat.');
      return;
    }
    setState(() => _busyProfessionalId = professional.userId);
    try {
      await downloadResume(
        apiClient: widget.apiClient,
        url: url,
        professionalName: professional.displayName,
      );
      _show('Curriculo salvo no celular.');
    } catch (error) {
      _show(error.toString());
    } finally {
      if (mounted) {
        setState(() => _busyProfessionalId = null);
      }
    }
  }

  Future<void> _whatsApp(ProfessionalItem professional) async {
    final phone = professional.phone;
    if (phone == null || phone.isEmpty) {
      _show('WhatsApp ainda nao liberado pela Apelmat.');
      return;
    }
    try {
      await openWhatsApp(
        phone,
        message:
            'Ola, ${professional.displayName}. Recebi seu contato pela Apelmat Empregos.',
      );
    } catch (error) {
      _show(error.toString());
    }
  }

  Future<void> _email(ProfessionalItem professional) async {
    final email = professional.email;
    if (email == null || email.isEmpty) {
      _show('E-mail ainda nao liberado pela Apelmat.');
      return;
    }
    try {
      await openEmail(
        email,
        subject: 'Contato pela Apelmat Empregos',
        body:
            'Ola, ${professional.displayName}. Recebi seu contato pela Apelmat Empregos.',
      );
    } catch (error) {
      _show(error.toString());
    }
  }

  Future<void> _report(ProfessionalItem professional) async {
    try {
      await widget.apiClient.post(
        '/moderation/reports/',
        body: {
          'target_type': 'user',
          'target_id': professional.userId,
          'reason': 'Perfil profissional denunciado pelo aplicativo',
        },
      );
      _show('Perfil enviado para analise da Apelmat.');
    } on ApiException catch (error) {
      _show(error.message);
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

class _ProfessionalCard extends StatelessWidget {
  const _ProfessionalCard({
    required this.professional,
    required this.busy,
    required this.onRequest,
    required this.onWhatsApp,
    required this.onEmail,
    required this.onDownload,
    required this.onReport,
  });

  final ProfessionalItem professional;
  final bool busy;
  final VoidCallback onRequest;
  final VoidCallback onWhatsApp;
  final VoidCallback onEmail;
  final VoidCallback onDownload;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    final location = [
      professional.city,
      professional.state,
    ].where((part) => part.isNotEmpty).join(' - ');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              professional.displayName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          if (professional.verifiedByApelmat)
                            const _VerifiedBadge(),
                        ],
                      ),
                      if (location.isNotEmpty)
                        Text(
                          location,
                          style: const TextStyle(color: AppColors.muted),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onReport,
                  tooltip: 'Denunciar',
                  icon: const Icon(Icons.flag_outlined),
                ),
              ],
            ),
            if (professional.headline.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                professional.headline,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
            if (professional.bio.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                professional.bio,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(height: 1.35),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(
                  icon: Icons.workspace_premium_outlined,
                  label: '${professional.yearsOfExperience} anos exp.',
                ),
                for (final objective in professional.objectives)
                  _InfoChip(
                    icon: Icons.work_outline,
                    label: objective.roleLabel,
                  ),
              ],
            ),
            if (professional.objectives.isNotEmpty) ...[
              const SizedBox(height: 12),
              _ObjectivePreview(objective: professional.objectives.first),
            ],
            const SizedBox(height: 14),
            if (professional.contactReleased)
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
              )
            else
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed:
                      busy || professional.contactPending ? null : onRequest,
                  icon:
                      busy
                          ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : Icon(
                            professional.contactPending
                                ? Icons.hourglass_top_outlined
                                : Icons.lock_open_outlined,
                          ),
                  label: Text(
                    professional.contactPending
                        ? 'Solicitado: em analise'
                        : 'Solicitar contato',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _VerifiedBadge extends StatelessWidget {
  const _VerifiedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.goldSoft,
        borderRadius: BorderRadius.circular(30),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_rounded, size: 14, color: AppColors.goldDark),
          SizedBox(width: 4),
          Text(
            'Apelmat',
            style: TextStyle(
              color: AppColors.goldDark,
              fontWeight: FontWeight.w900,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F5ED),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.goldDark),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _ObjectivePreview extends StatelessWidget {
  const _ObjectivePreview({required this.objective});

  final ProfessionalObjectiveSummary objective;

  @override
  Widget build(BuildContext context) {
    final answers = objective.answers.entries
        .take(3)
        .where((entry) => entry.value.isNotEmpty);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            objective.summary.isEmpty ? objective.roleLabel : objective.summary,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          if (objective.salaryExpectation.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Valor: ${objective.salaryExpectation}'),
          ],
          if (objective.availability.isNotEmpty)
            Text('Disponibilidade: ${objective.availability}'),
          for (final entry in answers) Text('${entry.key}: ${entry.value}'),
        ],
      ),
    );
  }
}
