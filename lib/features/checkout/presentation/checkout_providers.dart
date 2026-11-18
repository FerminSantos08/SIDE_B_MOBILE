import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/auth.dart';
import '../../content/presentation/content_providers.dart';
import '../data/checkout_repository.dart';

final checkoutRepositoryProvider = Provider(
  (ref) => CheckoutRepository(ref.watch(apiClientProvider)),
);
final deliveryAddressesProvider =
    FutureProvider.autoDispose<List<DeliveryAddress>>((ref) {
      ref.watch(authProvider);
      return ref.watch(checkoutRepositoryProvider).addresses();
    });
final ordersProvider = FutureProvider.autoDispose<List<PurchaseOrder>>((ref) {
  ref.watch(authProvider);
  return ref.watch(checkoutRepositoryProvider).orders();
});
final orderProvider = FutureProvider.autoDispose.family<PurchaseOrder, int>((
  ref,
  id,
) {
  ref.watch(authProvider);
  return ref.watch(checkoutRepositoryProvider).order(id);
});
