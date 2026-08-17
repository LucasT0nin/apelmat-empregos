import 'package:flutter/material.dart';

import 'core/api/api_client.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/auth_controller.dart';
import 'features/auth/presentation/login_page.dart';
import 'features/auth/presentation/register_page.dart';
import 'features/home/presentation/home_shell.dart';
import 'features/onboarding/presentation/welcome_page.dart';

class ApelmatApp extends StatelessWidget {
  const ApelmatApp({
    required this.apiClient,
    required this.authController,
    super.key,
  });

  final ApiClient apiClient;
  final AuthController authController;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Apelmat Empregos',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: ListenableBuilder(
        listenable: authController,
        builder: (context, _) {
          return switch (authController.status) {
            AuthStatus.loading => const _LoadingPage(),
            AuthStatus.authenticated => HomeShell(
              apiClient: apiClient,
              authController: authController,
            ),
            AuthStatus.unauthenticated => WelcomePage(
              onLogin: () => _openLogin(context),
              onRegister: () => _openRegister(context),
            ),
          };
        },
      ),
    );
  }

  Future<void> _openLogin(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LoginPage(authController: authController),
      ),
    );
  }

  Future<void> _openRegister(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RegisterPage(authController: authController),
      ),
    );
  }
}

class _LoadingPage extends StatelessWidget {
  const _LoadingPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
