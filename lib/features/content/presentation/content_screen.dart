import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/layout/side_b_layout.dart';
import '../../../core/theme/side_b_theme.dart';
import '../../../core/widgets/async_state.dart';
import '../../../core/widgets/editorial_components.dart';
import '../../../core/widgets/olive_shimmer.dart';
import '../data/content_models.dart';
import 'content_providers.dart';
import 'post_detail_screen.dart';
import 'artist_screens.dart';
import 'shop_screen.dart';
import 'reaction_providers.dart';

enum ContentMode { home, editorial, artists, catalog }

class ContentScreen extends ConsumerWidget {
  const ContentScreen({super.key, required this.mode});
  final ContentMode mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) => switch (mode) {
    ContentMode.home => const _HomeScreen(),
    ContentMode.editorial => _EditorialScreen(posts: ref.watch(postsProvider)),
    ContentMode.artists => const ArtistCatalogScreen(),
    ContentMode.catalog => const ShopScreen(),
  };
}

class _HomeScreen extends ConsumerWidget {
  const _HomeScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      final posts = ref.watch(postsProvider);
      return RefreshIndicator(
        color: SideBColors.olive,
        onRefresh: () async {
          ref.invalidate(reactionUpdatesProvider);
          try {
            await Future.wait([
              ref.refresh(postsProvider.future),
              ref.refresh(artistsProvider.future),
              ref.refresh(productsProvider.future),
            ]);
          } on Exception {
            // Each section renders its own provider error and retry action.
          }
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const SliverToBoxAdapter(
              child: EditorialHeader(
                eyebrow: 'SIDE B / Música y cultura',
                title: 'Historias para',
                subtitle: 'escuchar distinto.',
              ),
            ),
            SliverToBoxAdapter(
              child: _ContentWidth(
                width: width,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    posts.when(
                      loading: () => OliveShimmer(
                        child: _FeaturedSkeleton(
                          height: SideBLayout.featuredPostHeight(width),
                        ),
                      ),
                      error: (_, _) => AsyncErrorView(
                        message: 'No pudimos cargar las publicaciones.',
                        onRetry: () => ref.invalidate(postsProvider),
                      ),
                      data: (items) => items.isEmpty
                          ? const EmptyView(
                              message: 'Aún no hay publicaciones disponibles.',
                            )
                          : _HomePosts(posts: items, width: width),
                    ),
                    _HomeSelection<Artist>(
                      title: 'Artistas',
                      selection: ref.watch(artistsProvider),
                      onRetry: () => ref.invalidate(artistsProvider),
                      itemBuilder: (artist) =>
                          ArtistCard(artist: artist, imageAspectRatio: 1),
                    ),
                    _HomeSelection<Product>(
                      title: 'De la tienda',
                      selection: ref.watch(productsProvider),
                      onRetry: () => ref.invalidate(productsProvider),
                      itemBuilder: (product) => ProductCard(product: product),
                    ),
                    const SizedBox(height: 52),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _HomePosts extends StatelessWidget {
  const _HomePosts({required this.posts, required this.width});
  final List<Post> posts;
  final double width;

  @override
  Widget build(BuildContext context) {
    final latest = posts.skip(1).take(2).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _publicationCard(
          context,
          posts.first,
          height: SideBLayout.featuredPostHeight(width),
        ),
        if (latest.isNotEmpty) ...[
          const SizedBox(height: 28),
          const _SectionTitle(title: 'Últimas publicaciones'),
          const SizedBox(height: 14),
          if (width >= SideBLayout.compactBreakpoint && latest.length == 2)
            _PreviewRow(
              children: [
                for (final post in latest) _publicationCard(context, post),
              ],
            )
          else
            for (final post in latest)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _publicationCard(context, post),
              ),
        ],
      ],
    );
  }
}

class _HomeSelection<T> extends StatelessWidget {
  const _HomeSelection({
    required this.title,
    required this.selection,
    required this.onRetry,
    required this.itemBuilder,
  });

  final String title;
  final AsyncValue<List<T>> selection;
  final VoidCallback onRetry;
  final Widget Function(T) itemBuilder;

  @override
  Widget build(BuildContext context) {
    final content = selection.when<Widget?>(
      loading: () => const OliveShimmer(
        child: _PreviewRow(
          children: [
            AspectRatio(aspectRatio: 1, child: SkeletonBlock()),
            AspectRatio(aspectRatio: 1, child: SkeletonBlock()),
          ],
        ),
      ),
      error: (_, _) => AsyncErrorView(
        message: 'No pudimos cargar esta selección.',
        onRetry: onRetry,
      ),
      data: (items) => items.isEmpty
          ? null
          : _PreviewRow(children: items.take(2).map(itemBuilder).toList()),
    );
    if (content == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Divider(),
          const SizedBox(height: 20),
          _SectionTitle(title: title),
          const SizedBox(height: 14),
          content,
        ],
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: children.first),
      const SizedBox(width: 14),
      Expanded(
        child: children.length == 2 ? children.last : const SizedBox.shrink(),
      ),
    ],
  );
}

class _ContentWidth extends StatelessWidget {
  const _ContentWidth({required this.width, required this.child});

  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: SideBLayout.maxContentWidth),
      child: Padding(
        padding: SideBLayout.pageInsets(width, bottom: 0),
        child: child,
      ),
    ),
  );
}

class _EditorialScreen extends ConsumerWidget {
  const _EditorialScreen({required this.posts});
  final AsyncValue<List<Post>> posts;

  @override
  Widget build(BuildContext context, WidgetRef ref) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      final columns = width >= SideBLayout.compactBreakpoint ? 2 : 1;
      return RefreshIndicator(
        color: SideBColors.olive,
        onRefresh: () async {
          ref.invalidate(reactionUpdatesProvider);
          ref.invalidate(postsProvider);
          await ref.read(postsProvider.future);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const SliverToBoxAdapter(
              child: EditorialHeader(
                eyebrow: 'Lecturas SIDE B',
                title: 'Publicaciones',
                subtitle: 'y hallazgos.',
                description:
                    'Historias, hallazgos y sonidos para ir un poco más allá.',
              ),
            ),
            posts.when(
              loading: () => SliverToBoxAdapter(
                child: _ContentWidth(
                  width: width,
                  child: OliveShimmer(
                    child: _FeaturedSkeleton(
                      height: SideBLayout.featuredPostHeight(width),
                    ),
                  ),
                ),
              ),
              error: (_, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: AsyncErrorView(
                  message: 'No pudimos cargar las publicaciones.',
                  onRetry: () => ref.invalidate(postsProvider),
                ),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyView(
                      message: 'No hay publicaciones disponibles por ahora.',
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.only(bottom: 52),
                  sliver: SliverList.builder(
                    itemCount: (items.length / columns).ceil(),
                    itemBuilder: (context, index) {
                      final start = index * columns;
                      final first = _publicationCard(context, items[start]);
                      return _ContentWidth(
                        width: width,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: columns == 1
                              ? first
                              : _PreviewRow(
                                  children: [
                                    first,
                                    if (start + 1 < items.length)
                                      _publicationCard(
                                        context,
                                        items[start + 1],
                                      ),
                                  ],
                                ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      );
    },
  );
}

FeaturedPostCard _publicationCard(
  BuildContext context,
  Post post, {
  double? height,
}) => FeaturedPostCard(
  post: post,
  height: height,
  onTap: () => _open(context, post),
  onComment: () => _open(context, post, comments: true),
);

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) =>
      Text(title, style: Theme.of(context).textTheme.headlineMedium);
}

void _open(BuildContext context, Post post, {bool comments = false}) =>
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            PostDetailScreen(postId: post.id, scrollToComments: comments),
      ),
    );

class _FeaturedSkeleton extends StatelessWidget {
  const _FeaturedSkeleton({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: Stack(
      fit: StackFit.expand,
      children: [
        const SkeletonBlock(radius: 3),
        Positioned(
          left: 18,
          right: 18,
          bottom: 18,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              SkeletonBlock(width: 84, height: 10),
              SizedBox(height: 10),
              SkeletonBlock(height: 27),
              SizedBox(height: 7),
              SkeletonBlock(width: 190, height: 27),
              SizedBox(height: 12),
              SkeletonBlock(width: 145, height: 10),
            ],
          ),
        ),
      ],
    ),
  );
}
