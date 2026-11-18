import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/presentation/content_providers.dart';
import '../data/editorial_repository.dart';
import '../../auth/auth.dart';
import '../../content/data/content_models.dart';

final editorialRepositoryProvider = Provider(
  (ref) => EditorialRepository(ref.watch(apiClientProvider)),
);

final editorialOptionsProvider = FutureProvider<EditorialOptions>(
  (ref) => ref.watch(editorialRepositoryProvider).options(),
);
final managedPostsProvider = FutureProvider.autoDispose<List<Post>>((ref) {
  ref.watch(authProvider);
  return ref.watch(editorialRepositoryProvider).publications();
});
final editablePostProvider = FutureProvider.autoDispose
    .family<EditablePublication, int>((ref, id) {
      ref.watch(authProvider);
      return ref.watch(editorialRepositoryProvider).editable(id);
    });
