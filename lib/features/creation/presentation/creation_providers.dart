import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/presentation/content_providers.dart';
import '../data/editorial_repository.dart';

final editorialRepositoryProvider = Provider(
  (ref) => EditorialRepository(ref.watch(apiClientProvider)),
);

final editorialOptionsProvider = FutureProvider<EditorialOptions>(
  (ref) => ref.watch(editorialRepositoryProvider).options(),
);
