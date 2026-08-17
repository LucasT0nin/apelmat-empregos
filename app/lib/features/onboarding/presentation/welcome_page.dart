import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({
    required this.onLogin,
    required this.onRegister,
    super.key,
  });

  final VoidCallback onLogin;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.background,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: Stack(
          children: [
            const Positioned.fill(child: _Background()),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxHeight < 700;
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
                    children: [
                      Center(child: _Logo(size: compact ? 142 : 166)),
                      SizedBox(height: compact ? 18 : 24),
                      Text(
                        'Conectando quem faz com quem precisa.',
                        textAlign: TextAlign.center,
                        style: Theme.of(
                          context,
                        ).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          height: 1.03,
                          letterSpacing: -1.1,
                        ),
                      ),
                      const SizedBox(height: 13),
                      const Text(
                        'Profissionais publicam curriculo. Empresas consultam '
                        'o catalogo e a Apelmat libera os contatos com criterio.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 15,
                          height: 1.42,
                        ),
                      ),
                      const SizedBox(height: 22),
                      const Row(
                        children: [
                          Expanded(
                            child: _RoleCard(
                              icon: Icons.engineering_outlined,
                              title: 'Quero trabalhar',
                              subtitle: 'Publique seu curriculo',
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: _RoleCard(
                              icon: Icons.person_search_outlined,
                              title: 'Quero contratar',
                              subtitle: 'Solicite contatos',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: onRegister,
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: const Text('Criar minha conta'),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton(
                        onPressed: onLogin,
                        child: const Text('Entrar'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Background extends StatelessWidget {
  const _Background();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFF8E5), AppColors.background, Colors.white],
              stops: [0, 0.5, 1],
            ),
          ),
          child: SizedBox.expand(),
        ),
        Positioned(
          top: -190,
          right: -150,
          child: Container(
            width: 360,
            height: 360,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Color(0x42F5B800), Color(0x00F5B800)],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.23),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26946D00),
            blurRadius: 30,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.23),
        child: Image.asset(
          'assets/images/apelmat_app_icon.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 110),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.outline),
        boxShadow: const [
          BoxShadow(
            color: Color(0x15946D00),
            blurRadius: 18,
            offset: Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.goldSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.goldDark, size: 21),
          ),
          const SizedBox(height: 11),
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 11,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}
