import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../auth/auth.dart';
import '../../content/data/content_models.dart';
import '../../content/presentation/content_providers.dart';

class SavedPosts {
  SavedPosts({required List<Post> posts, required Set<int> ids})
    : posts = List.unmodifiable(posts),
      ids = Set.unmodifiable(ids);
  final List<Post> posts;
  final Set<int> ids;
  factory SavedPosts.fromJson(Map<String, dynamic> json) => SavedPosts(
    posts: (json['posts'] as List)
        .map((row) => Post.fromJson(row as Map<String, dynamic>))
        .toList(),
    ids: (json['saved_ids'] as List).cast<int>().toSet(),
  );
}

class SavedPostsRepository {
  SavedPostsRepository(this.api);
  final ApiClient api;
  Future<SavedPosts> load() async => SavedPosts.fromJson(
    await api.get('/library/posts') as Map<String, dynamic>,
  );
  Future<void> save(int id) async {
    await api.put('/library/posts/$id');
  }

  Future<void> remove(int id) async {
    await api.delete('/library/posts/$id');
  }
}

final savedPostsRepositoryProvider = Provider(
  (ref) => SavedPostsRepository(ref.watch(apiClientProvider)),
);
final savedPostsProvider = FutureProvider.autoDispose<SavedPosts>((ref) async {
  final auth = ref.watch(authProvider);
  final repository = ref.watch(savedPostsRepositoryProvider);
  if (auth.asData?.value == null) return SavedPosts(posts: [], ids: {});
  return repository.load();
});
