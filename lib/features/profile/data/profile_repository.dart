import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../auth/auth.dart';
import '../../checkout/data/checkout_repository.dart';
import '../../content/presentation/content_providers.dart';

class ProfileRepository {
  ProfileRepository(this.api);
  final ApiClient api;
  Future<AuthUser> save(String alias, String biography) async =>
      AuthUser.fromJson(
        await api.put(
          '/profile',
          data: {'alias': alias.trim(), 'biography': biography.trim()},
        ) as Map<String, dynamic>,
      );
  Future<AuthUser> avatar(List<int> bytes) async => AuthUser.fromJson(
    await api.uploadBytes('/profile/avatar', bytes) as Map<String, dynamic>,
  );
  Future<void> password(
    String current,
    String next,
    String confirmation,
  ) async {
    await api.put(
      '/profile/password',
      data: {
        'current_password': current,
        'new_password': next,
        'confirmation': confirmation,
      },
    );
  }

  Future<List<DeliveryAddress>> addresses() async {
    final data = await api.get('/profile/addresses') as Map<String, dynamic>;
    return (data['addresses'] as List)
        .map((row) => DeliveryAddress.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveAddress({
    int? id,
    required String label,
    required String address,
    required bool isDefault,
  }) async {
    final body = {
      'label': label.trim(),
      'address': address.trim(),
      'is_default': isDefault,
    };
    if (id == null) {
      await api.post('/profile/addresses', data: body);
    } else {
      await api.put('/profile/addresses/$id', data: body);
    }
  }

  Future<void> setDefault(int id) async {
    await api.put('/profile/addresses/$id/default');
  }

  Future<void> removeAddress(int id) async {
    await api.delete('/profile/addresses/$id');
  }
}

final profileRepositoryProvider = Provider(
  (ref) => ProfileRepository(ref.watch(apiClientProvider)),
);
final profileAddressesProvider =
    FutureProvider.autoDispose<List<DeliveryAddress>>((ref) {
      ref.watch(authProvider);
      return ref.watch(profileRepositoryProvider).addresses();
    });
