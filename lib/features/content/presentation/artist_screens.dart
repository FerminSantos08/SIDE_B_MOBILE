import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/layout/side_b_layout.dart';
import '../../../core/widgets/async_state.dart';
import '../../../core/widgets/editorial_components.dart';
import '../../../core/widgets/olive_shimmer.dart';
import '../data/content_models.dart';
import 'content_providers.dart';
import 'post_detail_screen.dart';

class ArtistCatalogScreen extends ConsumerWidget {
  const ArtistCatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artists = ref.watch(artistsProvider);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= SideBLayout.expandedBreakpoint ? 3 : 2;
        return CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(
              child: EditorialHeader(
                eyebrow: 'Artistas',
                title: 'Descubre',
                subtitle: 'algo distinto.',
                description: 'Explora sus historias, discos y publicaciones.',
              ),
            ),
            artists.when(
              loading: () => SliverToBoxAdapter(
                child: _ArtistCatalogWidth(
                  width: width,
                  child: const OliveShimmer(child: _ArtistSkeleton()),
                ),
              ),
              error: (_, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: AsyncErrorView(
                  message: 'No pudimos cargar los artistas.',
                  onRetry: () => ref.invalidate(artistsProvider),
                ),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyView(
                      message: 'Aún no hay artistas disponibles.',
                    ),
                  );
                }
                final rest = items.length - 1;
                return SliverMainAxisGroup(
                  slivers: [
                    SliverToBoxAdapter(
                      child: _ArtistCatalogWidth(
                        width: width,
                        child: ArtistCard(
                          artist: items.first,
                          imageAspectRatio: 16 / 9,
                          featured: true,
                        ),
                      ),
                    ),
                    if (rest > 0) ...[
                      SliverToBoxAdapter(
                        child: _ArtistCatalogWidth(
                          width: width,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 28, bottom: 14),
                            child: Text(
                              'Más artistas',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                          ),
                        ),
                      ),
                      SliverList.builder(
                        itemCount: (rest / columns).ceil(),
                        itemBuilder: (context, row) => _ArtistCatalogWidth(
                          width: width,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (
                                  var column = 0;
                                  column < columns;
                                  column++
                                ) ...[
                                  if (column > 0) const SizedBox(width: 12),
                                  Expanded(
                                    child:
                                        1 + row * columns + column <
                                            items.length
                                        ? ArtistCard(
                                            artist:
                                                items[1 +
                                                    row * columns +
                                                    column],
                                            imageAspectRatio: 1,
                                          )
                                        : const SizedBox.shrink(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SliverToBoxAdapter(child: SizedBox(height: 52)),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _ArtistCatalogWidth extends StatelessWidget {
  const _ArtistCatalogWidth({required this.width, required this.child});

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

class ArtistCard extends StatelessWidget {
  const ArtistCard({
    super.key,
    required this.artist,
    required this.imageAspectRatio,
    this.featured = false,
  });
  final Artist artist;
  final double imageAspectRatio;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: 'Ver perfil de ${artist.name}',
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ArtistProfileScreen(artistId: artist.id),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              NetworkCover(
                url: artist.image,
                aspectRatio: imageAspectRatio,
                height: featured
                    ? SideBLayout.featuredPostHeight(
                        MediaQuery.sizeOf(context).width,
                      )
                    : null,
              ),
              Padding(
                padding: EdgeInsets.all(featured ? 18 : 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (artist.genre case final genre?) ...[
                            Text(
                              genre,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.secondary,
                              ),
                            ),
                            const SizedBox(height: 5),
                          ],
                          Text(
                            artist.name,
                            style: featured
                                ? theme.textTheme.headlineMedium
                                : theme.textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                    if (featured) ...[
                      const SizedBox(width: 12),
                      Icon(
                        Icons.arrow_outward,
                        size: 18,
                        color: theme.colorScheme.secondary,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ArtistProfileScreen extends ConsumerWidget {
  const ArtistProfileScreen({super.key, required this.artistId});
  final int artistId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(artistProvider(artistId));
    return Scaffold(
      appBar: AppBar(title: const Text('Artistas')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => AsyncErrorView(
          message: 'No pudimos abrir este artista.',
          onRetry: () => ref.invalidate(artistProvider(artistId)),
        ),
        data: (artist) => _ArtistProfile(artist: artist),
      ),
    );
  }
}

class _ArtistProfile extends StatelessWidget {
  const _ArtistProfile({required this.artist});

  final Artist artist;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      final theme = Theme.of(context);
      final wide = width >= SideBLayout.compactBreakpoint;
      final identity = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (artist.genre case final genre?) ...[
            Text(
              genre.toUpperCase(),
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Text(artist.name, style: theme.textTheme.displaySmall),
        ],
      );
      final cover = artist.image == null
          ? null
          : NetworkCover(url: artist.image, aspectRatio: 4 / 3);

      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: SideBLayout.maxContentWidth,
          ),
          child: ListView(
            padding: SideBLayout.pageInsets(width, top: 24, bottom: 56),
            children: [
              if (wide && cover != null)
                Row(
                  children: [
                    Expanded(child: identity),
                    const SizedBox(width: 28),
                    Expanded(child: cover),
                  ],
                )
              else ...[
                identity,
                if (cover != null) ...[const SizedBox(height: 20), cover],
              ],
              if (artist.bio case final bio?) ...[
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: SizedBox(
                      width: double.infinity,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Biografía',
                                style: theme.textTheme.headlineMedium,
                              ),
                              const SizedBox(height: 10),
                              Text(bio, style: theme.textTheme.bodyLarge),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              if (artist.albums.isNotEmpty) ...[
                const SizedBox(height: 32),
                Text('Discografía', style: theme.textTheme.headlineMedium),
                const SizedBox(height: 14),
                _AlbumGrid(albums: artist.albums),
              ],
              if (artist.posts.isNotEmpty) ...[
                const SizedBox(height: 32),
                Text(
                  'Publicaciones relacionadas',
                  style: theme.textTheme.headlineMedium,
                ),
                for (final post in artist.posts)
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: FeaturedPostCard(
                      post: post,
                      height: 180,
                      onTap: () => _openPost(context, post),
                      onComment: () => _openPost(context, post, comments: true),
                    ),
                  ),
              ],
              if (artist.posts.isEmpty && artist.albums.isEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'Aún no hay álbumes ni publicaciones de este artista.',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ],
          ),
        ),
      );
    },
  );

  void _openPost(BuildContext context, Post post, {bool comments = false}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            PostDetailScreen(postId: post.id, scrollToComments: comments),
      ),
    );
  }
}

class _AlbumGrid extends StatelessWidget {
  const _AlbumGrid({required this.albums});

  final List<Album> albums;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const gap = 12.0;
      final text = Theme.of(context).textTheme;
      final accent = Theme.of(context).colorScheme.secondary;
      final width = constraints.maxWidth;
      final columns = ((width + gap) / 148).floor().clamp(1, 5);
      final tileWidth = (width - gap * (columns - 1)) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final album in albums)
            SizedBox(
              width: tileWidth,
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    NetworkCover(url: album.cover, aspectRatio: 1),
                    Padding(
                      padding: const EdgeInsets.all(11),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(album.title, style: text.titleMedium),
                          const SizedBox(height: 5),
                          Text(
                            [
                              album.type?.toUpperCase() ?? 'ÁLBUM',
                              if (DateTime.tryParse(album.releaseDate ?? '')
                                  case final date?)
                                date.year.toString(),
                            ].join(' · '),
                            style: text.labelMedium?.copyWith(color: accent),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    },
  );
}

class _ArtistSkeleton extends StatelessWidget {
  const _ArtistSkeleton();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      AspectRatio(aspectRatio: 16 / 9, child: SkeletonBlock()),
      SizedBox(height: 14),
      SkeletonBlock(width: 110, height: 12),
      SizedBox(height: 8),
      SkeletonBlock(width: 180, height: 24),
    ],
  );
}
