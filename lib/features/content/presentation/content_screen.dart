import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/layout/side_b_layout.dart';
import '../../../core/network/api_exception.dart';
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
  Widget build(BuildContext context, WidgetRef ref) {
    if (mode == ContentMode.home)
      return _HomeScreen(posts: ref.watch(postsProvider));
    if (mode == ContentMode.editorial)
      return _EditorialScreen(posts: ref.watch(postsProvider));
    if (mode == ContentMode.artists) return const ArtistCatalogScreen();
    if (mode == ContentMode.catalog) return const ShopScreen();
    return _OtherContentScreen(mode: mode);
  }
}

class _HomeScreen extends ConsumerWidget {
  const _HomeScreen({required this.posts});
  final AsyncValue<List<Post>> posts;

  @override
  Widget build(BuildContext context, WidgetRef ref) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      return RefreshIndicator(
        color: SideBColors.olive,
        onRefresh: () async {
          ref.invalidate(reactionUpdatesProvider);
          await ref.refresh(postsProvider.future);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const SliverToBoxAdapter(
              child: EditorialHeader(
                eyebrow: 'SIDE B / Música y cultura',
                title: 'Historias para\nescuchar distinto.',
                alignment: Alignment.centerLeft,
              ),
            ),
            posts.when(
              loading: () =>
                  SliverToBoxAdapter(child: _HomeSkeleton(width: width)),
              error: (error, _) => SliverFillRemaining(
                child: AsyncErrorView(
                  message: error is ApiException
                      ? 'No pudimos cargar la portada de SIDE B.\n${error.message}'
                      : 'No pudimos procesar las publicaciones de SIDE B.',
                  onRetry: () => ref.invalidate(postsProvider),
                ),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return const SliverFillRemaining(
                    child: EmptyView(
                      message: 'Aún no hay publicaciones disponibles.',
                    ),
                  );
                }
                return SliverToBoxAdapter(
                  child: _HomeBody(width: width, posts: items),
                );
              },
            ),
          ],
        ),
      );
    },
  );
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({required this.width, required this.posts});
  final double width;
  final List<Post> posts;

  @override
  Widget build(BuildContext context) {
    final size = SideBLayout.sizeFor(width);
    final padding = SideBLayout.horizontalPadding(width);
    final latest = posts.skip(1).take(4).toList();
    final featured = FeaturedPostCard(
      post: posts.first,
      height: SideBLayout.featuredPostHeight(width),
      onTap: () => _open(context, posts.first),
      onComment: () => _open(context, posts.first, comments: true),
    );
    final recent = _RecentPosts(posts: latest);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: SideBLayout.maxContentWidth,
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(padding, 0, padding, 24),
          child: size == SideBScreenSize.expanded
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 6, child: featured),
                    const SizedBox(width: 32),
                    Expanded(flex: 4, child: recent),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [featured, const SizedBox(height: 29), recent],
                ),
        ),
      ),
    );
  }
}

class _RecentPosts extends StatelessWidget {
  const _RecentPosts({required this.posts});
  final List<Post> posts;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _SectionTitle(title: 'Últimas publicaciones'),
      const SizedBox(height: 5),
      ...posts.map(
        (post) => CompactPostCard(
          post: post,
          onTap: () => _open(context, post),
          onComment: () => _open(context, post, comments: true),
        ),
      ),
    ],
  );
}

class _EditorialScreen extends ConsumerWidget {
  const _EditorialScreen({required this.posts});
  final AsyncValue<List<Post>> posts;

  @override
  Widget build(BuildContext context, WidgetRef ref) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      final padding = SideBLayout.horizontalPadding(width);
      final expanded = SideBLayout.sizeFor(width) == SideBScreenSize.expanded;
      final contentWidth = math
          .min(width - (padding * 2), SideBLayout.maxContentWidth)
          .toDouble();
      // A two-column tile must include its responsive 1.35 image plus all
      // editorial text below it. A fixed 455px tile overflows on tablets.
      final editorialTileHeight = ((contentWidth - 24) / 2) / 1.35 + 270;
      return RefreshIndicator(
        color: SideBColors.olive,
        onRefresh: () async {
          ref.invalidate(reactionUpdatesProvider);
          await ref.refresh(postsProvider.future);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const SliverToBoxAdapter(
              child: EditorialHeader(
                eyebrow: 'Lecturas SIDE B',
                title: 'Editorial.',
                description:
                    'Historias, hallazgos y sonidos para ir un poco más allá.',
              ),
            ),
            posts.when(
              loading: () =>
                  SliverToBoxAdapter(child: _EditorialSkeleton(width: width)),
              error: (_, __) => SliverFillRemaining(
                child: AsyncErrorView(
                  message: 'No pudimos cargar las publicaciones.',
                  onRetry: () => ref.invalidate(postsProvider),
                ),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return const SliverFillRemaining(
                    child: EmptyView(
                      message: 'No hay publicaciones disponibles por ahora.',
                    ),
                  );
                }
                return SliverPadding(
                  padding: EdgeInsets.fromLTRB(padding, 0, padding, 24),
                  sliver: SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: SideBLayout.maxContentWidth,
                        ),
                        child: expanded
                            ? GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      mainAxisSpacing: 20,
                                      crossAxisSpacing: 24,
                                      mainAxisExtent: editorialTileHeight,
                                    ),
                                itemCount: items.length,
                                itemBuilder: (context, index) =>
                                    EditorialPostCard(
                                      post: items[index],
                                      onTap: () => _open(context, items[index]),
                                      onComment: () => _open(
                                        context,
                                        items[index],
                                        comments: true,
                                      ),
                                    ),
                              )
                            : Column(
                                children: items
                                    .map(
                                      (post) => EditorialPostCard(
                                        post: post,
                                        onTap: () => _open(context, post),
                                        onComment: () => _open(
                                          context,
                                          post,
                                          comments: true,
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                      ),
                    ),
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

class _OtherContentScreen extends StatelessWidget {
  const _OtherContentScreen({required this.mode});
  final ContentMode mode;

  @override
  Widget build(BuildContext context) {
    final title = mode == ContentMode.artists
        ? 'Artistas.'
        : 'La tienda\ndel otro lado.';
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: EditorialHeader(eyebrow: mode.name, title: title),
        ),
        SliverFillRemaining(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Esta sección conserva su diseño base mientras se completa la siguiente fase.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(title, style: Theme.of(context).textTheme.titleLarge),
      const Spacer(),
      Text(
        'VER TODAS',
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(color: SideBColors.accent),
      ),
    ],
  );
}

void _open(BuildContext context, Post post, {bool comments = false}) =>
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            PostDetailScreen(postId: post.id, scrollToComments: comments),
      ),
    );

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton({required this.width});
  final double width;

  @override
  Widget build(BuildContext context) {
    final expanded = SideBLayout.sizeFor(width) == SideBScreenSize.expanded;
    final hero = _FeaturedSkeleton(
      height: SideBLayout.featuredPostHeight(width),
    );
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: SideBLayout.maxContentWidth,
        ),
        child: Padding(
          padding: SideBLayout.pageInsets(width),
          child: OliveShimmer(
            child: expanded
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 6, child: hero),
                      const SizedBox(width: 32),
                      const Expanded(flex: 4, child: _RecentSkeleton()),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      hero,
                      const SizedBox(height: 30),
                      const _RecentSkeleton(),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

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

class _RecentSkeleton extends StatelessWidget {
  const _RecentSkeleton();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _SectionTitle(title: 'Ultimas publicaciones'),
      SizedBox(height: 5),
      _CompactSkeleton(),
      _CompactSkeleton(),
      _CompactSkeleton(),
    ],
  );
}

class _EditorialSkeleton extends StatelessWidget {
  const _EditorialSkeleton({required this.width});
  final double width;

  @override
  Widget build(BuildContext context) {
    final padding = SideBLayout.horizontalPadding(width);
    final expanded = SideBLayout.sizeFor(width) == SideBScreenSize.expanded;
    final contentWidth = math
        .min(width - (padding * 2), SideBLayout.maxContentWidth)
        .toDouble();
    final tileHeight = ((contentWidth - 24) / 2) / 1.35 + 210;
    final cards = expanded
        ? GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 20,
              crossAxisSpacing: 24,
              mainAxisExtent: tileHeight,
            ),
            itemCount: 4,
            itemBuilder: (_, __) => const _EditorialCardSkeleton(),
          )
        : const Column(
            children: [_EditorialCardSkeleton(), _EditorialCardSkeleton()],
          );
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: SideBLayout.maxContentWidth,
        ),
        child: Padding(
          padding: SideBLayout.pageInsets(width),
          child: OliveShimmer(child: cards),
        ),
      ),
    );
  }
}

class _EditorialCardSkeleton extends StatelessWidget {
  const _EditorialCardSkeleton();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(bottom: 26),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(aspectRatio: 1.35, child: SkeletonBlock(radius: 3)),
        SizedBox(height: 13),
        SkeletonBlock(width: 78, height: 10),
        SizedBox(height: 7),
        SkeletonBlock(height: 28),
        SizedBox(height: 6),
        SkeletonBlock(width: 190, height: 28),
        SizedBox(height: 10),
        SkeletonBlock(height: 14),
        SizedBox(height: 6),
        SkeletonBlock(width: 210, height: 14),
        SizedBox(height: 10),
        SkeletonBlock(width: 130, height: 10),
      ],
    ),
  );
}

class _CompactSkeleton extends StatelessWidget {
  const _CompactSkeleton();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 13),
    child: Row(
      children: [
        SkeletonBlock(height: 84, width: 84, radius: 3),
        SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBlock(height: 10, width: 65),
              SizedBox(height: 9),
              SkeletonBlock(height: 20),
              SizedBox(height: 7),
              SkeletonBlock(height: 12, width: 110),
            ],
          ),
        ),
      ],
    ),
  );
}
