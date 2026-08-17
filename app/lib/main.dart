import 'package:flutter/material.dart';

import 'app.dart';
import 'core/api/api_client.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/auth_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final apiClient = ApiClient();
  final authController = AuthController(AuthRepository(apiClient: apiClient));
  await authController.restoreSession();

  runApp(ApelmatApp(apiClient: apiClient, authController: authController));
}
