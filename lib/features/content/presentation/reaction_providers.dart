import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/auth.dart';
import '../data/reactions_repository.dart';
import 'content_providers.dart';

final reactionsRepositoryProvider = Provider(
  (ref) => ReactionsRepository(ref.watch(apiClientProvider)),
);

final reactionCatalogProvider = FutureProvider.autoDispose<ReactionCatalog>(
  (ref) => ref.watch(reactionsRepositoryProvider).catalog(),
);

final reactionSummaryProvider = FutureProvider.autoDispose
    .family<ReactionSummary, int>((ref, postId) async {
      final repository = ref.watch(reactionsRepositoryProvider);
      final catalog = await ref.watch(reactionCatalogProvider.future);
      if (!catalog.available)
        return ReactionSummary(enabled: false, counts: {});
      return repository.summary(postId);
    });

// Session changes invalidate the selected reaction across accounts.
final selectedReactionProvider = FutureProvider.autoDispose
    .family<String?, int>((ref, postId) async {
      final repository = ref.watch(reactionsRepositoryProvider);
      final auth = ref.watch(authProvider);
      final catalog = await ref.watch(reactionCatalogProvider.future);
      if (!catalog.available || auth.asData?.value == null) return null;
      return repository.selected(postId);
    });

class ReactionUpdates extends Notifier<Map<int, ReactionSummary>> {
  @override
  Map<int, ReactionSummary> build() => {};

  void update(int postId, ReactionSummary summary) {
    state = {...state, postId: summary};
  }
}

final reactionUpdatesProvider =
    NotifierProvider<ReactionUpdates, Map<int, ReactionSummary>>(
      ReactionUpdates.new,
    );
