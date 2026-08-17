import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/auth_controller.dart';
import 'resume_upload_page.dart';
import 'work_areas_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({
    required this.authController,
    required this.apiClient,
    super.key,
  });

  final AuthController authController;
  final ApiClient apiClient;

  @override
  Widget build(BuildContext context) {
    final user = authController.user;
    return Scaffold(
      appBar: AppBar(title: const Text('Seu perfil')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: const BoxDecoration(
                      color: AppColors.goldSoft,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _initials(user?.displayName ?? ''),
                      style: const TextStyle(
                        color: AppColors.goldDark,
                        fontSize: 27,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    user?.displayName ?? '',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    user?.email ?? '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.muted),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    user?.phone ?? '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ],
              ),
            ),
          ),
          if (user?.canWork == true) ...[
            const SizedBox(height: 14),
            Card(child: _ResumeTile(apiClient: apiClient)),
            const SizedBox(height: 10),
            Card(child: _AreasTile(apiClient: apiClient)),
          ],
          const SizedBox(height: 22),
          OutlinedButton.icon(
            onPressed: authController.logout,
            icon: const Icon(Icons.logout),
            label: const Text('Sair da conta'),
          ),
          if (user?.isStaff != true) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => _confirmDelete(context),
              child: Text(
                'Excluir minha conta',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Excluir conta?'),
            content: const Text(
              'Esta acao remove sua conta e os dados associados. '
              'Ela nao pode ser desfeita.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Excluir'),
              ),
            ],
          ),
    );
    if (confirmed == true) {
      await authController.deleteAccount();
    }
  }
}

class _ResumeTile extends StatelessWidget {
  const _ResumeTile({required this.apiClient});

  final ApiClient apiClient;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.goldSoft,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(
          Icons.description_outlined,
          color: AppColors.goldDark,
        ),
      ),
      title: const Text(
        'Meu curriculo',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: const Text('Atualize seu perfil e envie seu PDF'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ResumeUploadPage(apiClient: apiClient),
          ),
        );
      },
    );
  }
}

class _AreasTile extends StatelessWidget {
  const _AreasTile({required this.apiClient});

  final ApiClient apiClient;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.goldSoft,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.work_outline, color: AppColors.goldDark),
      ),
      title: const Text(
        'Minhas areas',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: const Text('Cadastre ate 3 funcoes para analise'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => WorkAreasPage(apiClient: apiClient),
          ),
        );
      },
    );
  }
}
