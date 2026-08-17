import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';

class WorkAreasPage extends StatefulWidget {
  const WorkAreasPage({required this.apiClient, super.key});

  final ApiClient apiClient;

  @override
  State<WorkAreasPage> createState() => _WorkAreasPageState();
}

class _WorkAreasPageState extends State<WorkAreasPage> {
  late Future<List<WorkObjective>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<WorkObjective>> _load() async {
    final payload =
        await widget.apiClient.get('/marketplace/professional-objectives/')
            as Map<String, dynamic>;
    final items = payload['results'] as List<dynamic>;
    return items
        .map((item) => WorkObjective.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Minhas areas')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<WorkObjective>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final objectives = snapshot.data ?? [];
            if (snapshot.hasError) {
              return _MessageState(
                icon: Icons.cloud_off_outlined,
                title: 'Nao foi possivel carregar suas areas.',
                body: 'Confira o servidor e puxe para atualizar.',
                action: _refresh,
              );
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 100),
              children: [
                const _IntroCard(),
                const SizedBox(height: 16),
                for (final objective in objectives) ...[
                  _ObjectiveCard(
                    objective: objective,
                    onEdit: () => _openForm(objective),
                    onDelete: () => _delete(objective),
                  ),
                  const SizedBox(height: 10),
                ],
                if (objectives.isEmpty)
                  const _MessageState(
                    icon: Icons.work_outline,
                    title: 'Nenhuma area cadastrada ainda.',
                    body:
                        'Cadastre ate 3 areas para aparecer no catalogo depois da analise da Apelmat.',
                  ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: objectives.length >= 3 ? null : () => _openForm(),
                  icon: const Icon(Icons.add),
                  label: Text(
                    objectives.length >= 3
                        ? 'Limite de 3 areas atingido'
                        : 'Adicionar area de trabalho',
                  ),
                ),
              ],
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

  Future<void> _openForm([WorkObjective? objective]) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder:
            (_) => WorkAreaFormPage(
              apiClient: widget.apiClient,
              objective: objective,
            ),
      ),
    );
    if (saved == true) {
      await _refresh();
    }
  }

  Future<void> _delete(WorkObjective objective) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Remover area?'),
            content: Text(
              'A area ${objective.roleLabel} sera removida do seu perfil.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Remover'),
              ),
            ],
          ),
    );
    if (confirmed != true) {
      return;
    }
    try {
      await widget.apiClient.delete(
        '/marketplace/professional-objectives/${objective.id}/',
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Area removida.')));
      }
      await _refresh();
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }
}

class WorkAreaFormPage extends StatefulWidget {
  const WorkAreaFormPage({required this.apiClient, this.objective, super.key});

  final ApiClient apiClient;
  final WorkObjective? objective;

  @override
  State<WorkAreaFormPage> createState() => _WorkAreaFormPageState();
}

class _WorkAreaFormPageState extends State<WorkAreaFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _summaryController = TextEditingController();
  final _salaryController = TextEditingController(text: 'A combinar');
  final _availabilityController = TextEditingController();
  final Map<String, TextEditingController> _answerControllers = {};
  String _role = roleOptions.first.value;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final objective = widget.objective;
    if (objective != null) {
      _role = objective.role;
      _summaryController.text = objective.summary;
      _salaryController.text = objective.salaryExpectation;
      _availabilityController.text = objective.availability;
    }
    _syncQuestionControllers();
  }

  @override
  void dispose() {
    _summaryController.dispose();
    _salaryController.dispose();
    _availabilityController.dispose();
    for (final controller in _answerControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final questions = questionsByRole[_role] ?? const <String>[];
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.objective == null ? 'Nova area' : 'Editar area'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
          children: [
            DropdownButtonFormField<String>(
              value: _role,
              decoration: const InputDecoration(
                labelText: 'Funcao principal',
                prefixIcon: Icon(Icons.work_outline),
              ),
              items:
                  roleOptions
                      .map(
                        (role) => DropdownMenuItem(
                          value: role.value,
                          child: Text(role.label),
                        ),
                      )
                      .toList(),
              onChanged:
                  widget.objective == null
                      ? (value) {
                        setState(() {
                          _role = value ?? roleOptions.first.value;
                          _syncQuestionControllers();
                        });
                      }
                      : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _summaryController,
              minLines: 2,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Resumo para empresas',
                hintText: 'Ex.: Operador com experiencia em retroescavadeira',
                alignLabelWithHint: true,
              ),
              validator:
                  (value) =>
                      value == null || value.trim().length < 10
                          ? 'Escreva um resumo mais completo.'
                          : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _salaryController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Valor pretendido',
                hintText: 'A combinar, diaria, mensal ou faixa',
                prefixIcon: Icon(Icons.payments_outlined),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _availabilityController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Disponibilidade',
                hintText: 'Ex.: imediato, finais de semana, viagens curtas',
                prefixIcon: Icon(Icons.schedule_outlined),
              ),
              validator:
                  (value) =>
                      value == null || value.trim().length < 4
                          ? 'Informe sua disponibilidade.'
                          : null,
            ),
            const SizedBox(height: 20),
            Text(
              'Perguntas da funcao',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              'Leia cada pergunta com calma e responda embaixo. A Apelmat usa essas respostas para entender se o perfil esta pronto para ser apresentado as empresas.',
              style: TextStyle(color: AppColors.muted, height: 1.35),
            ),
            const SizedBox(height: 14),
            for (var index = 0; index < questions.length; index++) ...[
              _QuestionField(
                number: index + 1,
                question: questions[index],
                controller: _answerControllers[questions[index]]!,
              ),
              const SizedBox(height: 14),
            ],
            if (_error != null) ...[
              Text(
                _error!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
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
                      : const Text('Enviar para analise'),
            ),
          ],
        ),
      ),
    );
  }

  void _syncQuestionControllers() {
    final objectiveAnswers =
        widget.objective?.answers ?? const <String, String>{};
    final questions = questionsByRole[_role] ?? const <String>[];
    for (final question in questions) {
      _answerControllers.putIfAbsent(
        question,
        () => TextEditingController(text: objectiveAnswers[question] ?? ''),
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final answers = <String, String>{};
    final questions = questionsByRole[_role] ?? const <String>[];
    for (final question in questions) {
      answers[question] = _answerControllers[question]?.text.trim() ?? '';
    }
    final body = {
      'role': _role,
      'summary': _summaryController.text.trim(),
      'salary_expectation': _salaryController.text.trim(),
      'availability': _availabilityController.text.trim(),
      'answers': answers,
    };
    try {
      if (widget.objective == null) {
        await widget.apiClient.post(
          '/marketplace/professional-objectives/',
          body: body,
        );
      } else {
        await widget.apiClient.patch(
          '/marketplace/professional-objectives/${widget.objective!.id}/',
          body: body,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Area enviada para analise.')),
        );
        Navigator.of(context).pop(true);
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

class WorkObjective {
  const WorkObjective({
    required this.id,
    required this.role,
    required this.roleLabel,
    required this.summary,
    required this.salaryExpectation,
    required this.availability,
    required this.answers,
    required this.status,
    required this.statusLabel,
  });

  factory WorkObjective.fromJson(Map<String, dynamic> json) {
    return WorkObjective(
      id: json['id'] as String,
      role: json['role'] as String,
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
  final String role;
  final String roleLabel;
  final String summary;
  final String salaryExpectation;
  final String availability;
  final Map<String, String> answers;
  final String status;
  final String statusLabel;
}

class RoleOption {
  const RoleOption(this.value, this.label);

  final String value;
  final String label;
}

const roleOptions = [
  RoleOption('operador', 'Operador'),
  RoleOption('motorista_caminhao', 'Motorista de caminhao'),
  RoleOption('encarregado', 'Encarregado'),
  RoleOption('engenheiro', 'Engenheiro'),
  RoleOption('outros', 'Outros'),
];

const questionsByRole = {
  'operador': [
    'Quais equipamentos voce sabe operar com seguranca? Cite os principais, por exemplo retroescavadeira, pa carregadeira, escavadeira, empilhadeira ou outros.',
    'Quanto tempo de experiencia voce tem em cada equipamento citado? Separe por maquina se conseguir.',
    'Antes de ligar e operar uma maquina, quais itens voce confere no checklist de seguranca?',
    'Quais problemas ou sinais fazem voce parar a operacao e chamar manutencao ou o encarregado?',
    'Conte uma situacao dificil em obra ou operacao que voce ja resolveu, explicando o que aconteceu e como voce agiu.',
  ],
  'motorista_caminhao': [
    'Qual e sua categoria de CNH? Informe tambem se possui EAR, MOPP ou outros cursos/observacoes importantes.',
    'Quais tipos de caminhao voce dirige com seguranca? Exemplo: toco, truck, carreta, basculante, munck ou outros.',
    'Quais regioes, rotas ou tipos de trajeto voce conhece melhor?',
    'Antes de sair, como voce confere carga, documentos, amarracao, pneus, freio, luzes e condicao geral do veiculo?',
    'Qual sua disponibilidade para horario, viagem, pernoite, finais de semana e inicio imediato?',
  ],
  'encarregado': [
    'Qual foi a maior equipe que voce ja liderou? Informe quantidade de pessoas, tipo de trabalho e tempo nessa funcao.',
    'Como voce organiza escala, prioridade do dia, distribuicao de tarefas e acompanhamento da produtividade?',
    'Como voce conduz DDS, orientacao de seguranca, uso de EPI e correcao de risco antes de virar problema?',
    'Conte uma situacao de conflito ou erro na equipe que voce resolveu, explicando sua atitude.',
    'Quais relatorios, controles, planilhas, fotos ou comunicados voce sabe entregar para a empresa?',
  ],
  'engenheiro': [
    'Voce possui CREA ativo? Informe modalidade, area de atuacao e principais responsabilidades tecnicas que ja assumiu.',
    'Quais tipos de obra, manutencao, operacao ou projeto voce ja acompanhou do inicio ao fim?',
    'Como voce controla prazo, custo, qualidade, seguranca e comunicacao com equipe/cliente?',
    'Quais softwares, planilhas, sistemas ou ferramentas tecnicas voce domina no dia a dia?',
    'Conte um problema tecnico importante que voce resolveu, explicando o diagnostico e a solucao.',
  ],
  'outros': [
    'Qual funcao ou tipo de trabalho voce procura? Escreva do jeito mais claro possivel.',
    'Qual experiencia pratica voce tem nessa area? Informe onde trabalhou, por quanto tempo ou que atividades sabe fazer.',
    'Quais ferramentas, equipamentos, sistemas, documentos ou rotinas voce sabe usar?',
    'Qual sua disponibilidade de horario, local de trabalho, viagens e data para comecar?',
    'O que uma empresa precisa saber sobre voce antes de chamar para conversar?',
  ],
};

class _QuestionField extends StatelessWidget {
  const _QuestionField({
    required this.number,
    required this.question,
    required this.controller,
  });

  final int number;
  final String question;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pergunta $number',
              style: const TextStyle(
                color: AppColors.goldDark,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              question,
              style: const TextStyle(fontWeight: FontWeight.w900, height: 1.25),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: controller,
              minLines: 3,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Sua resposta',
                hintText:
                    'Responda com detalhes para a Apelmat avaliar melhor.',
                alignLabelWithHint: true,
              ),
              validator:
                  (value) =>
                      value == null || value.trim().length < 3
                          ? 'Responda esta pergunta.'
                          : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.goldSoft,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Escolha ate 3 areas',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              'Essas respostas ajudam a Apelmat publicar seu perfil no catalogo certo e encaminhar oportunidades com mais criterio.',
              style: TextStyle(height: 1.35),
            ),
          ],
        ),
      ),
    );
  }
}

class _ObjectiveCard extends StatelessWidget {
  const _ObjectiveCard({
    required this.objective,
    required this.onEdit,
    required this.onDelete,
  });

  final WorkObjective objective;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    objective.roleLabel,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _StatusPill(
                  status: objective.status,
                  label: objective.statusLabel,
                ),
              ],
            ),
            if (objective.summary.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(objective.summary),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (objective.salaryExpectation.isNotEmpty)
                  _SmallPill(
                    icon: Icons.payments_outlined,
                    label: objective.salaryExpectation,
                  ),
                if (objective.availability.isNotEmpty)
                  _SmallPill(
                    icon: Icons.schedule_outlined,
                    label: objective.availability,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Editar'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Remover'),
                ),
              ],
            ),
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
    final approved = status == 'published';
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

class _SmallPill extends StatelessWidget {
  const _SmallPill({required this.icon, required this.label});

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
          Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.body,
    this.action,
  });

  final IconData icon;
  final String title;
  final String body;
  final Future<void> Function()? action;

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      physics: action == null ? const NeverScrollableScrollPhysics() : null,
      padding: const EdgeInsets.all(26),
      children: [
        Icon(icon, size: 52, color: AppColors.goldDark),
        const SizedBox(height: 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(body, textAlign: TextAlign.center),
        if (action != null) ...[
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: action,
            child: const Text('Tentar novamente'),
          ),
        ],
      ],
    );
  }
}
