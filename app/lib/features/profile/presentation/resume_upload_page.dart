import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';

class ResumeUploadPage extends StatefulWidget {
  const ResumeUploadPage({required this.apiClient, super.key});

  final ApiClient apiClient;

  @override
  State<ResumeUploadPage> createState() => _ResumeUploadPageState();
}

class _ResumeUploadPageState extends State<ResumeUploadPage> {
  final _headlineController = TextEditingController();
  final _bioController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _experienceController = TextEditingController();
  PlatformFile? _file;
  bool _loading = true;
  bool _hasExistingResume = false;
  String _catalogStatusLabel = 'Rascunho';
  bool _submitting = false;
  String? _message;
  bool _success = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _headlineController.dispose();
    _bioController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final payload =
          await widget.apiClient.get('/accounts/me/professional/')
              as Map<String, dynamic>;
      _headlineController.text = payload['headline'] as String? ?? '';
      _bioController.text = payload['bio'] as String? ?? '';
      _cityController.text = payload['city'] as String? ?? '';
      _stateController.text = payload['state'] as String? ?? '';
      _experienceController.text =
          (payload['years_of_experience'] as int? ?? 0).toString();
      _catalogStatusLabel = _statusLabel(payload['catalog_status'] as String?);
      _hasExistingResume = (payload['resume'] as String?)?.isNotEmpty == true;
    } on ApiException catch (error) {
      _message = error.message;
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Meu curriculo',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFEADCA8)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Seu curriculo base',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Preencha seus dados principais. A Apelmat analisa e publica no catalogo quando estiver pronto.',
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Status: $_catalogStatusLabel',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _headlineController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Resumo profissional',
                      hintText: 'Ex.: Operador com experiencia em logistica',
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _bioController,
                    minLines: 3,
                    maxLines: 6,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Apresentacao',
                      hintText: 'Conte brevemente sua experiencia.',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _cityController,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Cidade',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _stateController,
                          maxLength: 2,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            labelText: 'UF',
                            counterText: '',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _experienceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Anos de experiencia',
                      prefixIcon: Icon(Icons.workspace_premium_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: _pickFile,
                    icon: const Icon(Icons.attach_file),
                    label: Text(
                      _file?.name ??
                          (_hasExistingResume
                              ? 'Trocar curriculo PDF'
                              : 'Escolher curriculo PDF'),
                    ),
                  ),
                  if (_hasExistingResume && _file == null)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text('Ja existe um PDF salvo.'),
                    ),
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'O PDF ajuda, mas nao e obrigatorio para salvar o perfil.',
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_message != null) ...[
                    Text(
                      _message!,
                      style: TextStyle(
                        color:
                            _success
                                ? Colors.green.shade800
                                : Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  FilledButton(
                    onPressed: _submitting ? null : _submit,
                    child:
                        _submitting
                            ? const SizedBox.square(
                              dimension: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Text('Salvar perfil e curriculo'),
                  ),
                ],
              ),
    );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: false,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _file = result.files.single);
    }
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _message = null;
    });
    try {
      final uploadedPdf = _file?.path != null;
      await widget.apiClient.multipartPatch(
        '/accounts/me/professional/',
        fields: {
          'headline': _headlineController.text.trim(),
          'bio': _bioController.text.trim(),
          'area': 'outros',
          'city': _cityController.text.trim(),
          'state': _stateController.text.trim().toUpperCase(),
          'years_of_experience': _experienceController.text.trim(),
          'profile_visible': 'true',
        },
        fileField: _file?.path == null ? null : 'resume',
        filePath: _file?.path,
      );
      if (mounted) {
        setState(() {
          _hasExistingResume = _hasExistingResume || uploadedPdf;
          _file = null;
          _catalogStatusLabel = 'Em analise';
          _success = true;
          _message = 'Curriculo salvo e enviado para analise da Apelmat.';
        });
      }
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          _success = false;
          _message = error.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _success = false;
          _message = 'Nao foi possivel enviar o curriculo.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  String _statusLabel(String? status) {
    return switch (status) {
      'published' => 'Publicado e verificado',
      'review' => 'Em analise',
      'paused' => 'Pausado',
      'rejected' => 'Recusado',
      _ => 'Rascunho',
    };
  }
}
