import 'package:flutter/material.dart';

import '../../../core/config/app_config.dart';
import '../../../core/external/external_actions.dart';
import '../../../core/theme/app_theme.dart';
import 'auth_controller.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({required this.authController, super.key});

  final AuthController authController;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _acceptTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(17),
                    child: Image.asset(
                      'assets/images/apelmat_app_icon.png',
                      width: 68,
                      height: 68,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Crie sua conta',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Cadastro para quem quer trabalhar pela Apelmat.',
                          style: TextStyle(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator:
                    (value) =>
                        value == null || value.trim().length < 3
                            ? 'Informe seu nome.'
                            : null,
              ),
              const SizedBox(height: 16),
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
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'E-mail',
                  prefixIcon: Icon(Icons.mail_outline),
                ),
                validator:
                    (value) =>
                        value == null || !value.contains('@')
                            ? 'Informe um e-mail valido.'
                            : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Senha',
                  helperText: 'Use pelo menos 8 caracteres.',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator:
                    (value) =>
                        value == null || value.length < 8
                            ? 'A senha precisa ter pelo menos 8 caracteres.'
                            : null,
              ),
              const SizedBox(height: 20),
              Card(
                color: AppColors.goldSoft,
                child: ListTile(
                  leading: const Icon(
                    Icons.work_outline,
                    color: AppColors.goldDark,
                  ),
                  title: const Text(
                    'Conta de candidato',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: const Text(
                    'Empresas contratantes sao cadastradas somente pela Apelmat.',
                  ),
                ),
              ),
              const SizedBox(height: 24),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _acceptTerms,
                onChanged: (value) {
                  setState(() => _acceptTerms = value ?? false);
                },
                title: const Text(
                  'Aceito os Termos de Uso e a Politica de Privacidade.',
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              Wrap(
                children: [
                  TextButton(
                    onPressed:
                        () => openWebPage(
                          'https://${AppConfig.publicDomain}/termos/',
                        ),
                    child: const Text('Ler termos'),
                  ),
                  TextButton(
                    onPressed:
                        () => openWebPage(
                          'https://${AppConfig.publicDomain}/privacidade/',
                        ),
                    child: const Text('Ler privacidade'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ListenableBuilder(
                listenable: widget.authController,
                builder: (context, _) {
                  return Column(
                    children: [
                      if (widget.authController.errorMessage != null) ...[
                        Text(
                          widget.authController.errorMessage!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      FilledButton(
                        onPressed:
                            widget.authController.isSubmitting ? null : _submit,
                        child:
                            widget.authController.isSubmitting
                                ? const SizedBox.square(
                                  dimension: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Text('Criar conta'),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aceite os termos para criar sua conta.')),
      );
      return;
    }
    final success = await widget.authController.register(
      displayName: _nameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      acceptTerms: _acceptTerms,
      password: _passwordController.text,
      accountType: 'professional',
    );
    if (success && mounted) {
      Navigator.of(context).pop();
    }
  }
}
