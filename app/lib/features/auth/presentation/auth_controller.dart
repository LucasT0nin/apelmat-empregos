import 'package:flutter/foundation.dart';

import '../../../core/api/api_client.dart';
import '../data/auth_repository.dart';
import '../domain/app_user.dart';

enum AuthStatus { loading, authenticated, unauthenticated }

class AuthController extends ChangeNotifier {
  AuthController(this._repository);

  final AuthRepository _repository;

  AuthStatus status = AuthStatus.loading;
  AppUser? user;
  String? errorMessage;
  bool isSubmitting = false;

  Future<void> restoreSession() async {
    final token = await _repository.apiClient.accessToken;
    if (token == null) {
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    try {
      user = await _repository.me();
      status = AuthStatus.authenticated;
    } on ApiException {
      await _repository.logout();
      status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login({required String email, required String password}) async {
    return _submit(() => _repository.login(email: email, password: password));
  }

  Future<bool> register({
    required String displayName,
    required String email,
    required String phone,
    required bool acceptTerms,
    required String password,
    required String accountType,
  }) async {
    return _submit(
      () => _repository.register(
        displayName: displayName,
        email: email,
        phone: phone,
        acceptTerms: acceptTerms,
        password: password,
        accountType: accountType,
      ),
    );
  }

  Future<bool> _submit(Future<AppUser> Function() action) async {
    isSubmitting = true;
    errorMessage = null;
    notifyListeners();
    try {
      user = await action();
      status = AuthStatus.authenticated;
      return true;
    } on ApiException catch (error) {
      errorMessage = error.message;
      return false;
    } catch (_) {
      errorMessage = 'Nao foi possivel conectar ao servidor. Tente novamente.';
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    user = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<bool> deleteAccount() async {
    try {
      await _repository.deleteAccount();
      user = null;
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      errorMessage = error.message;
      notifyListeners();
      return false;
    }
  }
}
