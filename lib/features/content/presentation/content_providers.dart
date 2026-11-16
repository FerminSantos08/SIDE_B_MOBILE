import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../data/content_models.dart';
import '../data/content_repository.dart';

final tokenStorageProvider = Provider((ref) => TokenStorage());
final apiClientProvider = Provider(
  (ref) => ApiClient(ref.watch(tokenStorageProvider)),
);
final contentRepositoryProvider = Provider(
  (ref) => ContentRepository(ref.watch(apiClientProvider)),
);
final postsProvider = FutureProvider<List<Post>>(
  (ref) => ref.watch(contentRepositoryProvider).posts(),
);
final commentsProvider = FutureProvider.autoDispose
    .family<List<PostComment>, int>(
      (ref, id) => ref.watch(contentRepositoryProvider).comments(id),
    );
final postProvider = FutureProvider.family<Post, int>(
  (ref, id) => ref.watch(contentRepositoryProvider).post(id),
);
final artistsProvider = FutureProvider<List<Artist>>(
  (ref) => ref.watch(contentRepositoryProvider).artists(),
);
final artistProvider = FutureProvider.family<Artist, int>(
  (ref, id) => ref.watch(contentRepositoryProvider).artist(id),
);
final productsProvider = FutureProvider<List<Product>>(
  (ref) => ref.watch(contentRepositoryProvider).products(),
);
final productProvider = FutureProvider.family<Product, int>(
  (ref, id) => ref.watch(contentRepositoryProvider).product(id),
);
final cartProvider = FutureProvider<List<CartItem>>(
  (ref) => ref.watch(contentRepositoryProvider).cart(),
);
