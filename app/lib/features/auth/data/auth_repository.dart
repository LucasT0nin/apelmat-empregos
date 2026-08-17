import '../../../core/api/api_client.dart';
import '../domain/app_user.dart';

class AuthRepository {
  AuthRepository({required this.apiClient});

  final ApiClient apiClient;

  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    final payload =
        await apiClient.post(
              '/auth/token/',
              authenticated: false,
              body: {'email': email.trim(), 'password': password},
            )
            as Map<String, dynamic>;
    await apiClient.saveTokens(
      access: payload['access'] as String,
      refresh: payload['refresh'] as String,
    );
    return me();
  }

  Future<AppUser> register({
    required String displayName,
    required String email,
    required String phone,
    required bool acceptTerms,
    required String password,
    required String accountType,
  }) async {
    await apiClient.post(
      '/accounts/register/',
      authenticated: false,
      body: {
        'display_name': displayName.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'accept_terms': acceptTerms,
        'password': password,
        'account_type': accountType,
      },
    );
    return login(email: email, password: password);
  }

  Future<AppUser> me() async {
    final payload =
        await apiClient.get('/accounts/me/') as Map<String, dynamic>;
    return AppUser.fromJson(payload);
  }

  Future<void> logout() => apiClient.clearTokens();

  Future<void> deleteAccount() async {
    await apiClient.delete('/accounts/me/delete/');
    await apiClient.clearTokens();
  }
}
