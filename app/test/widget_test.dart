import 'package:apelmat_empregos/features/onboarding/presentation/welcome_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('welcome page presents the main entry actions', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: WelcomePage(onLogin: () {}, onRegister: () {})),
    );

    expect(find.text('Conectando quem faz com quem precisa.'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pump();

    expect(find.text('Criar minha conta'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('Solicite contatos'), findsOneWidget);
  });
}
