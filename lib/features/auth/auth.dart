import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../content/presentation/content_providers.dart';

class AuthUser {
  const AuthUser({required this.id, required this.name, required this.email, required this.role});
  final int id;
  final String name, email, role;
  bool get canPublish {
    final normalized = role.toLowerCase();
    return normalized.contains('artist') || normalized.contains('editor') || normalized.contains('producer') || normalized.contains('manager');
  }
  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    id: json['id'] as int,
    name: json['profile']?['alias']?.toString() ?? json['name'] as String,
    email: json['email'] as String,
    role: json['role']?['name']?.toString() ?? 'Listener',
  );
}

class AuthController extends AsyncNotifier<AuthUser?> {
  @override
  Future<AuthUser?> build() async {
    final token = await ref.read(tokenStorageProvider).read();
    if (token == null) return null;
    try {
      return AuthUser.fromJson(await ref.read(apiClientProvider).get('/auth/me') as Map<String, dynamic>);
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await ref.read(tokenStorageProvider).clear();
        return null;
      }
      rethrow;
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final data = await ref.read(apiClientProvider).post('/auth/login', data: {'email': email, 'password': password}) as Map<String, dynamic>;
      await ref.read(tokenStorageProvider).write(data['access_token'] as String);
      return AuthUser.fromJson(await ref.read(apiClientProvider).get('/auth/me') as Map<String, dynamic>);
    });
  }

  Future<void> register(String name, String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(apiClientProvider).post('/auth/register', data: {'username': name, 'email': email, 'password': password});
      final data = await ref.read(apiClientProvider).post('/auth/login', data: {'email': email, 'password': password}) as Map<String, dynamic>;
      await ref.read(tokenStorageProvider).write(data['access_token'] as String);
      return AuthUser.fromJson(await ref.read(apiClientProvider).get('/auth/me') as Map<String, dynamic>);
    });
  }

  Future<void> logout() async {
    await ref.read(tokenStorageProvider).clear();
    state = const AsyncData(null);
  }
}

final authProvider = AsyncNotifierProvider<AuthController, AuthUser?>(AuthController.new);
