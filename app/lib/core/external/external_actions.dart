import 'package:url_launcher/url_launcher.dart';

Future<void> openWebPage(String url) async {
  final uri = Uri.parse(url);
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    throw StateError('Nao foi possivel abrir esta pagina.');
  }
}

Future<void> openWhatsApp(String phone, {required String message}) async {
  final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
  final uri = Uri.parse(
    'https://wa.me/$digits?text=${Uri.encodeComponent(message)}',
  );
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    throw StateError('Nao foi possivel abrir o WhatsApp.');
  }
}

Future<void> openEmail(
  String email, {
  required String subject,
  String? body,
}) async {
  final uri = Uri(
    scheme: 'mailto',
    path: email,
    queryParameters: {'subject': subject, if (body != null) 'body': body},
  );
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    throw StateError('Nao foi possivel abrir o aplicativo de e-mail.');
  }
}
