import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/external/external_actions.dart';
import '../../../core/files/resume_downloader.dart';
import '../../../core/theme/app_theme.dart';
import '../../professionals/domain/professional_item.dart';

class AdminCreateContractorPage extends StatefulWidget {
  const AdminCreateContractorPage({required this.apiClient, super.key});

  final ApiClient apiClient;

  @override
  State<AdminCreateContractorPage> createState() =>
      _AdminCreateContractorPageState();
}

class _AdminCreateContractorPageState extends State<AdminCreateContractorPage> {
  final _formKey = GlobalKey<FormState>();
  final _companyController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  late final TextEditingController _passwordController =
      TextEditingController(text: _temporaryPassword());
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  bool _submitting = false;
  String? _error;

  static String _temporaryPassword() {
    const chars =
        'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789!@#';
    final random = Random.secure();
    return List.generate(
      14,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
  }

  @override
  void dispose() {
    _companyController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inserir contratante')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            const _AdminIntroCard(
              icon: Icons.business_center_outlined,
              title: 'Conta de empresa',
              body:
                  'Crie aqui o acesso de contratantes. Candidato continua criando conta sozinho pela tela inicial.',
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _companyController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nome da empresa',
                prefixIcon: Icon(Icons.business_outlined),
              ),
              validator:
                  (value) =>
                      value == null || value.trim().length < 2
                          ? 'Informe a empresa.'
                          : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Responsavel',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator:
                  (value) =>
                      value == null || value.trim().length < 3
                          ? 'Informe o responsavel.'
                          : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'WhatsApp com DDD',
                hintText: '(11) 99999-9999',
                prefixIcon: Icon(Icons.chat_outlined),
              ),
              validator:
                  (value) =>
                      value == null ||
                              value.replaceAll(RegExp(r'[^0-9]'), '').length <
                                  10
                          ? 'Informe um WhatsApp valido.'
                          : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'E-mail de acesso',
                prefixIcon: Icon(Icons.mail_outline),
              ),
              validator:
                  (value) =>
                      value == null || !value.contains('@')
                          ? 'Informe um e-mail valido.'
                          : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Senha provisoria',
                helperText: 'Use pelo menos 8 caracteres.',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              validator:
                  (value) =>
                      value == null || value.length < 8
                          ? 'A senha precisa ter pelo menos 8 caracteres.'
                          : null,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _cityController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Cidade',
                      prefixIcon: Icon(Icons.location_city_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _stateController,
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 2,
                    decoration: const InputDecoration(
                      labelText: 'UF',
                      counterText: '',
                    ),
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 14),
              Text(
                _error!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _submitting ? null : _submit,
              icon:
                  _submitting
                      ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.person_add_alt_1),
              label: const Text('Criar contratante'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    try {
      await widget.apiClient.post(
        '/accounts/contractors/',
        body: {
          'company_name': _companyController.text.trim(),
          'display_name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'email': email,
          'password': password,
          'city': _cityController.text.trim(),
          'state': _stateController.text.trim(),
        },
      );
      if (!mounted) {
        return;
      }
      await showDialog<void>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Contratante criado'),
              content: Text(
                'A empresa ja pode entrar no app.\n\nE-mail: $email\nSenha: $password',
              ),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Ok'),
                ),
              ],
            ),
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }
}

class AdminResumesPage extends StatefulWidget {
  const AdminResumesPage({required this.apiClient, super.key});

  final ApiClient apiClient;

  @override
  State<AdminResumesPage> createState() => _AdminResumesPageState();
}

class _AdminResumesPageState extends State<AdminResumesPage> {
  final _searchController = TextEditingController();
  late Future<List<ProfessionalItem>> _future;
  String? _busyId;

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
      appBar: AppBar(title: const Text('Curriculos')),
      body: Column(
        children: [
          _AdminSearchBar(
            controller: _searchController,
            hintText: 'Buscar candidato, cidade ou experiencia',
            onSearch: _refresh,
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
                  if (snapshot.hasError) {
                    return _AdminMessageState(
                      icon: Icons.cloud_off_outlined,
                      title: 'Nao foi possivel carregar curriculos.',
                      body: 'Confira o servidor e puxe para atualizar.',
                      onRetry: _refresh,
                    );
                  }
                  final items = snapshot.data ?? [];
                  if (items.isEmpty) {
                    return const _AdminMessageState(
                      icon: Icons.description_outlined,
                      title: 'Nenhum curriculo encontrado.',
                      body:
                          'Quando candidatos completarem o perfil, aparecem aqui.',
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _AdminResumeCard(
                        item: item,
                        busy: _busyId == item.userId,
                        onPublish: () => _status(item, 'publish'),
                        onPause: () => _status(item, 'pause'),
                        onReview: () => _status(item, 'review'),
                        onDownload: () => _download(item),
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

  Future<void> _status(ProfessionalItem item, String action) async {
    setState(() => _busyId = item.userId);
    try {
      await widget.apiClient.post(
        '/accounts/professionals/${item.userId}/$action/',
      );
      _show('Curriculo atualizado.');
      await _refresh();
    } on ApiException catch (error) {
      _show(error.message);
    } finally {
      if (mounted) {
        setState(() => _busyId = null);
      }
    }
  }

  Future<void> _download(ProfessionalItem item) async {
    final url = item.resumeDownloadUrl;
    if (url == null || url.isEmpty) {
      _show('Este candidato ainda nao enviou PDF.');
      return;
    }
    setState(() => _busyId = item.userId);
    try {
      await downloadResume(
        apiClient: widget.apiClient,
        url: url,
        professionalName: item.displayName,
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

class AdminObjectivesPage extends StatefulWidget {
  const AdminObjectivesPage({required this.apiClient, super.key});

  final ApiClient apiClient;

  @override
  State<AdminObjectivesPage> createState() => _AdminObjectivesPageState();
}

class _AdminObjectivesPageState extends State<AdminObjectivesPage> {
  late Future<List<AdminObjectiveItem>> _future;
  String? _busyId;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<AdminObjectiveItem>> _load() async {
    final payload =
        await widget.apiClient.get('/marketplace/professional-objectives/')
            as Map<String, dynamic>;
    final items = payload['results'] as List<dynamic>;
    return items
        .map(
          (item) => AdminObjectiveItem.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Areas profissionais')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<AdminObjectiveItem>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _AdminMessageState(
                icon: Icons.cloud_off_outlined,
                title: 'Nao foi possivel carregar areas.',
                body: 'Confira o servidor e puxe para atualizar.',
                onRetry: _refresh,
              );
            }
            final items = snapshot.data ?? [];
            if (items.isEmpty) {
              return const _AdminMessageState(
                icon: Icons.work_outline,
                title: 'Nenhuma area cadastrada.',
                body: 'As areas enviadas pelos candidatos aparecem aqui.',
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = items[index];
                return _AdminObjectiveCard(
                  item: item,
                  busy: _busyId == item.id,
                  onPublish: () => _status(item, 'publish'),
                  onReject: () => _status(item, 'reject'),
                  onReview: () => _status(item, 'review'),
                  onWhatsApp: () => _whatsApp(item),
                  onEmail: () => _email(item),
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

  Future<void> _status(AdminObjectiveItem item, String action) async {
    setState(() => _busyId = item.id);
    try {
      await widget.apiClient.post(
        '/marketplace/professional-objectives/${item.id}/$action/',
      );
      _show('Area atualizada.');
      await _refresh();
    } on ApiException catch (error) {
      _show(error.message);
    } finally {
      if (mounted) {
        setState(() => _busyId = null);
      }
    }
  }

  Future<void> _whatsApp(AdminObjectiveItem item) async {
    if (item.professionalPhone.isEmpty) {
      _show('Profissional sem WhatsApp.');
      return;
    }
    try {
      await openWhatsApp(
        item.professionalPhone,
        message:
            'Ola, ${item.professionalName}. Aqui e a Apelmat Empregos. Estamos analisando sua area ${item.roleLabel}.',
      );
    } catch (error) {
      _show(error.toString());
    }
  }

  Future<void> _email(AdminObjectiveItem item) async {
    if (item.professionalEmail.isEmpty) {
      _show('Profissional sem e-mail.');
      return;
    }
    try {
      await openEmail(
        item.professionalEmail,
        subject: 'Analise Apelmat Empregos',
        body:
            'Ola, ${item.professionalName}. Estamos analisando sua area ${item.roleLabel}.',
      );
    } catch (error) {
      _show(error.toString());
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

class AdminContactRequestsPage extends StatefulWidget {
  const AdminContactRequestsPage({required this.apiClient, super.key});

  final ApiClient apiClient;

  @override
  State<AdminContactRequestsPage> createState() =>
      _AdminContactRequestsPageState();
}

class _AdminContactRequestsPageState extends State<AdminContactRequestsPage> {
  late Future<List<AdminContactRequestItem>> _future;
  String? _busyId;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<AdminContactRequestItem>> _load() async {
    final payload =
        await widget.apiClient.get('/marketplace/contact-requests/')
            as Map<String, dynamic>;
    final items = payload['results'] as List<dynamic>;
    return items
        .map(
          (item) =>
              AdminContactRequestItem.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Solicitacoes de contato')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<AdminContactRequestItem>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _AdminMessageState(
                icon: Icons.cloud_off_outlined,
                title: 'Nao foi possivel carregar solicitacoes.',
                body: 'Confira o servidor e puxe para atualizar.',
                onRetry: _refresh,
              );
            }
            final items = snapshot.data ?? [];
            if (items.isEmpty) {
              return const _AdminMessageState(
                icon: Icons.lock_open_outlined,
                title: 'Nenhuma solicitacao ainda.',
                body: 'Quando uma empresa pedir contato, aparece aqui.',
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = items[index];
                return _AdminContactRequestCard(
                  item: item,
                  busy: _busyId == item.id,
                  onApprove: () => _status(item, 'approve'),
                  onReject: () => _status(item, 'reject'),
                  onWhatsApp: () => _whatsApp(item),
                  onEmail: () => _email(item),
                  onCompanyWhatsApp: () => _companyWhatsApp(item),
                  onCompanyEmail: () => _companyEmail(item),
                  onDownload: () => _download(item),
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

  Future<void> _status(AdminContactRequestItem item, String action) async {
    setState(() => _busyId = item.id);
    try {
      await widget.apiClient.post(
        '/marketplace/contact-requests/${item.id}/$action/',
      );
      _show('Solicitacao atualizada.');
      await _refresh();
    } on ApiException catch (error) {
      _show(error.message);
    } finally {
      if (mounted) {
        setState(() => _busyId = null);
      }
    }
  }

  Future<void> _whatsApp(AdminContactRequestItem item) async {
    if (item.professionalPhone.isEmpty) {
      _show('Profissional sem WhatsApp.');
      return;
    }
    try {
      await openWhatsApp(
        item.professionalPhone,
        message:
            'Ola, ${item.professionalName}. Aqui e a Apelmat Empregos. Uma empresa associada solicitou seu contato.',
      );
    } catch (error) {
      _show(error.toString());
    }
  }

  Future<void> _email(AdminContactRequestItem item) async {
    if (item.professionalEmail.isEmpty) {
      _show('Profissional sem e-mail.');
      return;
    }
    try {
      await openEmail(
        item.professionalEmail,
        subject: 'Contato pela Apelmat Empregos',
        body:
            'Ola, ${item.professionalName}. Uma empresa associada solicitou seu contato pela Apelmat Empregos.',
      );
    } catch (error) {
      _show(error.toString());
    }
  }

  Future<void> _companyWhatsApp(AdminContactRequestItem item) async {
    if (item.companyPhone.isEmpty) {
      _show('Empresa sem WhatsApp.');
      return;
    }
    try {
      await openWhatsApp(
        item.companyPhone,
        message:
            'Ola, ${item.companyName}. Aqui e a Apelmat Empregos. Estamos analisando sua solicitacao de contato.',
      );
    } catch (error) {
      _show(error.toString());
    }
  }

  Future<void> _companyEmail(AdminContactRequestItem item) async {
    if (item.companyEmail.isEmpty) {
      _show('Empresa sem e-mail.');
      return;
    }
    try {
      await openEmail(
        item.companyEmail,
        subject: 'Solicitacao pela Apelmat Empregos',
        body:
            'Ola, ${item.companyName}. Estamos analisando sua solicitacao pela Apelmat Empregos.',
      );
    } catch (error) {
      _show(error.toString());
    }
  }

  Future<void> _download(AdminContactRequestItem item) async {
    final url = item.resumeDownloadUrl;
    if (url == null || url.isEmpty) {
      _show('Curriculo nao disponivel.');
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

class AdminObjectiveItem {
  const AdminObjectiveItem({
    required this.id,
    required this.professionalName,
    required this.professionalEmail,
    required this.professionalPhone,
    required this.roleLabel,
    required this.summary,
    required this.salaryExpectation,
    required this.availability,
    required this.answers,
    required this.status,
    required this.statusLabel,
  });

  factory AdminObjectiveItem.fromJson(Map<String, dynamic> json) {
    return AdminObjectiveItem(
      id: json['id'] as String,
      professionalName: json['professional_name'] as String? ?? '',
      professionalEmail: json['professional_email'] as String? ?? '',
      professionalPhone: json['professional_phone'] as String? ?? '',
      roleLabel: json['role_label'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      salaryExpectation: json['salary_expectation'] as String? ?? '',
      availability: json['availability'] as String? ?? '',
      answers: (json['answers'] as Map<String, dynamic>? ?? {}).map(
        (key, value) => MapEntry(key, value.toString()),
      ),
      status: json['status'] as String? ?? 'review',
      statusLabel: json['status_label'] as String? ?? 'Em analise',
    );
  }

  final String id;
  final String professionalName;
  final String professionalEmail;
  final String professionalPhone;
  final String roleLabel;
  final String summary;
  final String salaryExpectation;
  final String availability;
  final Map<String, String> answers;
  final String status;
  final String statusLabel;
}

class AdminContactRequestItem {
  const AdminContactRequestItem({
    required this.id,
    required this.companyName,
    required this.companyEmail,
    required this.companyPhone,
    required this.professionalName,
    required this.professionalEmail,
    required this.professionalPhone,
    required this.professionalCity,
    required this.professionalState,
    required this.roleLabel,
    required this.status,
    required this.statusLabel,
    this.resumeDownloadUrl,
  });

  factory AdminContactRequestItem.fromJson(Map<String, dynamic> json) {
    return AdminContactRequestItem(
      id: json['id'] as String,
      companyName: json['company_name'] as String? ?? 'Empresa',
      companyEmail: json['company_email'] as String? ?? '',
      companyPhone: json['company_phone'] as String? ?? '',
      professionalName: json['professional_name'] as String? ?? '',
      professionalEmail: json['professional_email'] as String? ?? '',
      professionalPhone: json['professional_phone'] as String? ?? '',
      professionalCity: json['professional_city'] as String? ?? '',
      professionalState: json['professional_state'] as String? ?? '',
      roleLabel: json['role_label'] as String? ?? 'Perfil profissional',
      status: json['status'] as String? ?? 'pending',
      statusLabel: json['status_label'] as String? ?? 'Em analise',
      resumeDownloadUrl: json['resume_download_url'] as String?,
    );
  }

  final String id;
  final String companyName;
  final String companyEmail;
  final String companyPhone;
  final String professionalName;
  final String professionalEmail;
  final String professionalPhone;
  final String professionalCity;
  final String professionalState;
  final String roleLabel;
  final String status;
  final String statusLabel;
  final String? resumeDownloadUrl;
}

class _AdminResumeCard extends StatelessWidget {
  const _AdminResumeCard({
    required this.item,
    required this.busy,
    required this.onPublish,
    required this.onPause,
    required this.onReview,
    required this.onDownload,
  });

  final ProfessionalItem item;
  final bool busy;
  final VoidCallback onPublish;
  final VoidCallback onPause;
  final VoidCallback onReview;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final location = [
      item.city,
      item.state,
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
                const _AdminCircleIcon(icon: Icons.description_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.displayName,
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
                _AdminStatusPill(
                  status: item.catalogStatus,
                  label: item.catalogStatusLabel,
                ),
              ],
            ),
            if (item.headline.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                item.headline,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
            if (item.bio.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(item.bio, maxLines: 3, overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _AdminChip(
                  icon:
                      item.hasResume
                          ? Icons.picture_as_pdf_outlined
                          : Icons.upload_file_outlined,
                  label: item.hasResume ? 'PDF enviado' : 'Sem PDF',
                ),
                _AdminChip(
                  icon: Icons.workspace_premium_outlined,
                  label: '${item.yearsOfExperience} anos exp.',
                ),
                for (final objective in item.objectives)
                  _AdminChip(
                    icon: Icons.work_outline,
                    label: '${objective.roleLabel} - ${objective.statusLabel}',
                  ),
              ],
            ),
            const SizedBox(height: 14),
            _AdminButtonWrap(
              busy: busy,
              children: [
                FilledButton.icon(
                  onPressed: busy ? null : onPublish,
                  icon: const Icon(Icons.verified_outlined),
                  label: const Text('Publicar'),
                ),
                OutlinedButton.icon(
                  onPressed: busy ? null : onPause,
                  icon: const Icon(Icons.pause_circle_outline),
                  label: const Text('Pausar'),
                ),
                TextButton.icon(
                  onPressed: busy ? null : onReview,
                  icon: const Icon(Icons.rate_review_outlined),
                  label: const Text('Analise'),
                ),
                OutlinedButton.icon(
                  onPressed: busy ? null : onDownload,
                  icon: const Icon(Icons.download_outlined),
                  label: const Text('PDF'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminObjectiveCard extends StatelessWidget {
  const _AdminObjectiveCard({
    required this.item,
    required this.busy,
    required this.onPublish,
    required this.onReject,
    required this.onReview,
    required this.onWhatsApp,
    required this.onEmail,
  });

  final AdminObjectiveItem item;
  final bool busy;
  final VoidCallback onPublish;
  final VoidCallback onReject;
  final VoidCallback onReview;
  final VoidCallback onWhatsApp;
  final VoidCallback onEmail;

  @override
  Widget build(BuildContext context) {
    final answers = item.answers.entries
        .where((entry) => entry.value.trim().isNotEmpty)
        .take(3);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _AdminCircleIcon(icon: Icons.work_outline),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.roleLabel,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        item.professionalName,
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                _AdminStatusPill(status: item.status, label: item.statusLabel),
              ],
            ),
            if (item.summary.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(item.summary),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (item.salaryExpectation.isNotEmpty)
                  _AdminChip(
                    icon: Icons.payments_outlined,
                    label: item.salaryExpectation,
                  ),
                if (item.availability.isNotEmpty)
                  _AdminChip(
                    icon: Icons.schedule_outlined,
                    label: item.availability,
                  ),
              ],
            ),
            for (final answer in answers) ...[
              const SizedBox(height: 8),
              Text(
                '${answer.key}: ${answer.value}',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.muted),
              ),
            ],
            const SizedBox(height: 14),
            _AdminButtonWrap(
              busy: busy,
              children: [
                FilledButton.icon(
                  onPressed: busy ? null : onPublish,
                  icon: const Icon(Icons.verified_outlined),
                  label: const Text('Publicar'),
                ),
                OutlinedButton.icon(
                  onPressed: busy ? null : onReject,
                  icon: const Icon(Icons.block_outlined),
                  label: const Text('Recusar'),
                ),
                TextButton.icon(
                  onPressed: busy ? null : onReview,
                  icon: const Icon(Icons.rate_review_outlined),
                  label: const Text('Analise'),
                ),
                IconButton(
                  onPressed: busy ? null : onWhatsApp,
                  icon: const Icon(Icons.chat_outlined),
                  tooltip: 'WhatsApp',
                ),
                IconButton(
                  onPressed: busy ? null : onEmail,
                  icon: const Icon(Icons.email_outlined),
                  tooltip: 'E-mail',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminContactRequestCard extends StatelessWidget {
  const _AdminContactRequestCard({
    required this.item,
    required this.busy,
    required this.onApprove,
    required this.onReject,
    required this.onWhatsApp,
    required this.onEmail,
    required this.onCompanyWhatsApp,
    required this.onCompanyEmail,
    required this.onDownload,
  });

  final AdminContactRequestItem item;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onWhatsApp;
  final VoidCallback onEmail;
  final VoidCallback onCompanyWhatsApp;
  final VoidCallback onCompanyEmail;
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _AdminCircleIcon(icon: Icons.lock_open_outlined),
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
                      Text('Empresa: ${item.companyName}'),
                      if (location.isNotEmpty)
                        Text(
                          location,
                          style: const TextStyle(color: AppColors.muted),
                        ),
                    ],
                  ),
                ),
                _AdminStatusPill(status: item.status, label: item.statusLabel),
              ],
            ),
            const SizedBox(height: 10),
            _AdminChip(icon: Icons.work_outline, label: item.roleLabel),
            const SizedBox(height: 14),
            _AdminButtonWrap(
              busy: busy,
              children: [
                FilledButton.icon(
                  onPressed: busy ? null : onApprove,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Liberar'),
                ),
                OutlinedButton.icon(
                  onPressed: busy ? null : onReject,
                  icon: const Icon(Icons.block_outlined),
                  label: const Text('Recusar'),
                ),
                IconButton(
                  onPressed: busy ? null : onWhatsApp,
                  icon: const Icon(Icons.chat_outlined),
                  tooltip: 'WhatsApp profissional',
                ),
                IconButton(
                  onPressed: busy ? null : onEmail,
                  icon: const Icon(Icons.email_outlined),
                  tooltip: 'E-mail profissional',
                ),
                IconButton(
                  onPressed: busy ? null : onCompanyWhatsApp,
                  icon: const Icon(Icons.business_center_outlined),
                  tooltip: 'WhatsApp empresa',
                ),
                IconButton(
                  onPressed: busy ? null : onCompanyEmail,
                  icon: const Icon(Icons.alternate_email_outlined),
                  tooltip: 'E-mail empresa',
                ),
                IconButton(
                  onPressed: busy ? null : onDownload,
                  icon: const Icon(Icons.download_outlined),
                  tooltip: 'Curriculo',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminSearchBar extends StatelessWidget {
  const _AdminSearchBar({
    required this.controller,
    required this.hintText,
    required this.onSearch,
  });

  final TextEditingController controller;
  final String hintText;
  final Future<void> Function() onSearch;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: SearchBar(
        controller: controller,
        hintText: hintText,
        leading: const Icon(Icons.search),
        trailing: [
          IconButton(
            onPressed: onSearch,
            icon: const Icon(Icons.arrow_forward),
          ),
        ],
        onSubmitted: (_) => onSearch(),
      ),
    );
  }
}

class _AdminIntroCard extends StatelessWidget {
  const _AdminIntroCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.goldSoft,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AdminCircleIcon(icon: icon),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    body,
                    style: const TextStyle(
                      color: AppColors.muted,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminButtonWrap extends StatelessWidget {
  const _AdminButtonWrap({required this.children, required this.busy});

  final List<Widget> children;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (busy)
          const SizedBox.square(
            dimension: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ...children,
      ],
    );
  }
}

class _AdminStatusPill extends StatelessWidget {
  const _AdminStatusPill({required this.status, required this.label});

  final String status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final published = status == 'published' || status == 'approved';
    final rejected = status == 'rejected' || status == 'paused';
    final color =
        published
            ? AppColors.goldSoft
            : rejected
            ? const Color(0xFFFFECEC)
            : const Color(0xFFF8F5ED);
    final foreground =
        published
            ? AppColors.goldDark
            : rejected
            ? const Color(0xFF9A2E2E)
            : AppColors.muted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label.isEmpty ? status : label,
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.w900,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _AdminChip extends StatelessWidget {
  const _AdminChip({required this.icon, required this.label});

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

class _AdminCircleIcon extends StatelessWidget {
  const _AdminCircleIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundColor: AppColors.goldSoft,
      foregroundColor: AppColors.goldDark,
      child: Icon(icon),
    );
  }
}

class _AdminMessageState extends StatelessWidget {
  const _AdminMessageState({
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
