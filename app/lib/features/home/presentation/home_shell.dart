import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../admin/presentation/admin_pages.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../notifications/presentation/notifications_page.dart';
import '../../professionals/presentation/contact_requests_page.dart';
import '../../professionals/presentation/professionals_page.dart';
import '../../profile/presentation/profile_page.dart';
import '../../profile/presentation/resume_upload_page.dart';
import '../../profile/presentation/work_areas_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({
    required this.apiClient,
    required this.authController,
    super.key,
  });

  final ApiClient apiClient;
  final AuthController authController;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = widget.authController.user!;
    if (user.isStaff) {
      return _AdminHomeShell(
        apiClient: widget.apiClient,
        authController: widget.authController,
      );
    }
    final secondaryPage =
        user.canHire
            ? ProfessionalsPage(apiClient: widget.apiClient)
            : WorkAreasPage(apiClient: widget.apiClient);
    final secondaryDestination =
        user.canHire
            ? const NavigationDestination(
              icon: Icon(Icons.person_search_outlined),
              selectedIcon: Icon(Icons.person_search_rounded),
              label: 'Catalogo',
            )
            : const NavigationDestination(
              icon: Icon(Icons.work_outline),
              selectedIcon: Icon(Icons.work_rounded),
              label: 'Areas',
            );
    final thirdPage =
        user.canHire && !user.canWork
            ? ContactRequestsPage(apiClient: widget.apiClient)
            : NotificationsPage(apiClient: widget.apiClient);
    final thirdDestination =
        user.canHire && !user.canWork
            ? const NavigationDestination(
              icon: Icon(Icons.assignment_outlined),
              selectedIcon: Icon(Icons.assignment_rounded),
              label: 'Pedidos',
            )
            : const NavigationDestination(
              icon: Icon(Icons.notifications_none),
              selectedIcon: Icon(Icons.notifications_rounded),
              label: 'Avisos',
            );
    final pages = [
      _DashboardPage(
        userName: user.displayName,
        canWork: user.canWork,
        canHire: user.canHire,
        onCatalog: () => setState(() => _selectedIndex = 1),
        onResume: () => _open(ResumeUploadPage(apiClient: widget.apiClient)),
        onAreas: () => _open(WorkAreasPage(apiClient: widget.apiClient)),
        onRequests:
            () => _open(ContactRequestsPage(apiClient: widget.apiClient)),
      ),
      secondaryPage,
      thirdPage,
      ProfilePage(
        authController: widget.authController,
        apiClient: widget.apiClient,
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Inicio',
          ),
          secondaryDestination,
          thirdDestination,
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  Future<void> _open(Widget page) async {
    await Navigator.of(
      context,
    ).push<void>(MaterialPageRoute<void>(builder: (_) => page));
  }
}

class _AdminHomeShell extends StatefulWidget {
  const _AdminHomeShell({
    required this.apiClient,
    required this.authController,
  });

  final ApiClient apiClient;
  final AuthController authController;

  @override
  State<_AdminHomeShell> createState() => _AdminHomeShellState();
}

class _AdminHomeShellState extends State<_AdminHomeShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      _AdminDashboardPage(apiClient: widget.apiClient),
      NotificationsPage(
        apiClient: widget.apiClient,
        onOpenContactRequests:
            () => _open(AdminContactRequestsPage(apiClient: widget.apiClient)),
        onOpenResumes:
            () => _open(AdminResumesPage(apiClient: widget.apiClient)),
      ),
      ProfilePage(
        authController: widget.authController,
        apiClient: widget.apiClient,
      ),
    ];
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected:
            (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.admin_panel_settings_outlined),
            selectedIcon: Icon(Icons.admin_panel_settings_rounded),
            label: 'Admin',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_none),
            selectedIcon: Icon(Icons.notifications_rounded),
            label: 'Avisos',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  Future<void> _open(Widget page) async {
    await Navigator.of(
      context,
    ).push<void>(MaterialPageRoute<void>(builder: (_) => page));
  }
}

class _AdminDashboardPage extends StatelessWidget {
  const _AdminDashboardPage({required this.apiClient});

  final ApiClient apiClient;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.asset(
                  'assets/images/apelmat_app_icon.png',
                  width: 54,
                  height: 54,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Painel Admin',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Controle da Apelmat Empregos',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _AdminActionTile(
            icon: Icons.verified_outlined,
            title: 'Curriculos',
            subtitle: 'Aprovar, pausar e aplicar selo Apelmat.',
            onTap: () => _open(context, AdminResumesPage(apiClient: apiClient)),
          ),
          const SizedBox(height: 10),
          _AdminActionTile(
            icon: Icons.work_outline,
            title: 'Areas profissionais',
            subtitle: 'Operador, motorista, encarregado, engenheiro e outros.',
            onTap:
                () => _open(context, AdminObjectivesPage(apiClient: apiClient)),
          ),
          const SizedBox(height: 10),
          _AdminActionTile(
            icon: Icons.business_center_outlined,
            title: 'Inserir contratante',
            subtitle: 'Criar conta de empresa para acessar o catalogo.',
            onTap:
                () => _open(
                  context,
                  AdminCreateContractorPage(apiClient: apiClient),
                ),
          ),
          const SizedBox(height: 10),
          _AdminActionTile(
            icon: Icons.lock_open_outlined,
            title: 'Solicitacoes de contato',
            subtitle: 'Liberar ou recusar cada pedido manualmente.',
            onTap:
                () => _open(
                  context,
                  AdminContactRequestsPage(apiClient: apiClient),
                ),
          ),
        ],
      ),
    );
  }

  Future<void> _open(BuildContext context, Widget page) async {
    await Navigator.of(
      context,
    ).push<void>(MaterialPageRoute<void>(builder: (_) => page));
  }
}

class _AdminActionTile extends StatelessWidget {
  const _AdminActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        leading: _AdminTileIcon(icon: icon),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _AdminTileIcon extends StatelessWidget {
  const _AdminTileIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.goldSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: AppColors.goldDark),
    );
  }
}

class _DashboardPage extends StatelessWidget {
  const _DashboardPage({
    required this.userName,
    required this.canWork,
    required this.canHire,
    required this.onCatalog,
    required this.onResume,
    required this.onAreas,
    required this.onRequests,
  });

  final String userName;
  final bool canWork;
  final bool canHire;
  final VoidCallback onCatalog;
  final VoidCallback onResume;
  final VoidCallback onAreas;
  final VoidCallback onRequests;

  @override
  Widget build(BuildContext context) {
    final trimmedName = userName.trim();
    final firstName =
        trimmedName.isEmpty ? '' : trimmedName.split(RegExp(r'\s+')).first;
    final actions = <_DashboardAction>[
      if (canWork)
        _DashboardAction(
          icon: Icons.description_outlined,
          title: 'Meu curriculo',
          subtitle: 'Perfil, cidade, experiencia e PDF',
          onTap: onResume,
        ),
      if (canWork)
        _DashboardAction(
          icon: Icons.work_outline,
          title: 'Minhas areas',
          subtitle: 'Cadastre ate 3 funcoes',
          onTap: onAreas,
        ),
      if (canHire)
        _DashboardAction(
          icon: Icons.person_search_outlined,
          title: 'Catalogo',
          subtitle: 'Veja profissionais verificados',
          onTap: onCatalog,
        ),
      if (canHire)
        _DashboardAction(
          icon: Icons.assignment_outlined,
          title: 'Solicitacoes',
          subtitle: 'Acompanhe contatos pedidos',
          onTap: onRequests,
        ),
    ];

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.asset(
                  'assets/images/apelmat_app_icon.png',
                  width: 54,
                  height: 54,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ola, $firstName',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Central de oportunidades Apelmat',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _FlowCard(canHire: canHire, canWork: canWork),
          const SizedBox(height: 24),
          Text(
            'Seus atalhos',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: actions.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.28,
            ),
            itemBuilder: (context, index) {
              return _DashboardCard(action: actions[index]);
            },
          ),
        ],
      ),
    );
  }
}

class _DashboardAction {
  const _DashboardAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
}

class _FlowCard extends StatelessWidget {
  const _FlowCard({required this.canHire, required this.canWork});

  final bool canHire;
  final bool canWork;

  @override
  Widget build(BuildContext context) {
    final title =
        canHire && !canWork
            ? 'Solicite contatos com controle Apelmat'
            : 'Seu curriculo passa pela Apelmat';
    final body =
        canHire && !canWork
            ? 'A empresa consulta o catalogo, solicita contato e acompanha a liberacao no app.'
            : 'Complete seu perfil, escolha ate 3 areas e aguarde a analise para entrar no catalogo.';
    return Card(
      color: AppColors.goldSoft,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(17),
              ),
              child: Icon(
                canHire && !canWork
                    ? Icons.lock_open_outlined
                    : Icons.verified_outlined,
                color: AppColors.goldDark,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: const TextStyle(color: AppColors.muted, height: 1.3),
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

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({required this.action});

  final _DashboardAction action;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.goldSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(action.icon, color: AppColors.goldDark, size: 23),
              ),
              const Spacer(),
              Text(
                action.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                action.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
