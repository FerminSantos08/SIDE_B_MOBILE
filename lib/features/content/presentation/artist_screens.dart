import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/layout/side_b_layout.dart';
import '../../../core/theme/side_b_theme.dart';
import '../../../core/widgets/async_state.dart';
import '../../../core/widgets/editorial_components.dart';
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
        final padding = SideBLayout.horizontalPadding(width);
        final landscape = MediaQuery.orientationOf(context) == Orientation.landscape;
        final phone = width < SideBLayout.compactBreakpoint;
        final columns = phone ? 2 : (landscape || width >= SideBLayout.expandedBreakpoint ? 3 : 2);
        final imageAspectRatio = phone ? .75 : (landscape ? 4 / 3 : .8);
        final gridWidth = width - (padding * 2);
        final tileWidth = (gridWidth - (16 * (columns - 1))) / columns;
        final tileHeight = (tileWidth / imageAspectRatio) + 60;
        return CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(
              child: EditorialHeader(
                eyebrow: 'Nuevas coordenadas',
                title: 'Descubre\nalgo distinto.',
                description:
                    'Artistas que están haciendo ruido en los márgenes.',
              ),
            ),
            artists.when(
              loading: () => SliverPadding(
                padding: EdgeInsets.all(padding),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (_, __) => _ArtistSkeleton(aspectRatio: imageAspectRatio),
                    childCount: columns * 2,
                  ),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 16,
                    mainAxisExtent: tileHeight,
                  ),
                ),
              ),
              error: (_, __) => SliverFillRemaining(
                child: AsyncErrorView(
                  message: 'No pudimos cargar los artistas.',
                  onRetry: () => ref.invalidate(artistsProvider),
                ),
              ),
              data: (items) => items.isEmpty
                  ? const SliverFillRemaining(
                      child: EmptyView(message: 'Aún no hay artistas disponibles.'),
                    )
                  : SliverPadding(
                      padding: EdgeInsets.fromLTRB(padding, 0, padding, 112),
                      sliver: SliverGrid(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _ArtistCard(
                            artist: items[index],
                            imageAspectRatio: imageAspectRatio,
                          ),
                          childCount: items.length,
                        ),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          mainAxisSpacing: 18,
                          crossAxisSpacing: 16,
                          mainAxisExtent: tileHeight,
                        ),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _ArtistCard extends StatelessWidget {
  const _ArtistCard({required this.artist, required this.imageAspectRatio});
  final Artist artist;
  final double imageAspectRatio;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Ver perfil de ${artist.name}',
    child: InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ArtistProfileScreen(artistId: artist.id)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NetworkCover(url: artist.image, aspectRatio: imageAspectRatio),
          const SizedBox(height: 10),
          Text(artist.name, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge),
          if (artist.genre != null) ...[
            const SizedBox(height: 3),
            Text(artist.genre!, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium),
          ],
        ],
      ),
    ),
  );
}

class ArtistProfileScreen extends ConsumerWidget {
  const ArtistProfileScreen({super.key, required this.artistId});
  final int artistId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(artistProvider(artistId));
    return Scaffold(
      body: SafeArea(
        child: state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => AsyncErrorView(
            message: 'No pudimos abrir este artista.',
            onRetry: () => ref.invalidate(artistProvider(artistId)),
          ),
          data: (artist) => _ArtistProfile(artist: artist),
        ),
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
      final padding = SideBLayout.horizontalPadding(width);
      final wide = width >= SideBLayout.compactBreakpoint;
      final hero = NetworkCover(url: artist.image, aspectRatio: 1);
      final copy = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (artist.genre != null)
          Text(artist.genre!.toUpperCase(), style: Theme.of(context).textTheme.labelMedium?.copyWith(color: SideBColors.accent)),
        const SizedBox(height: 9),
        Text(artist.name, style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 14),
        Text(artist.bio ?? 'Próximamente encontrarás más información sobre este artista.', style: Theme.of(context).textTheme.bodyLarge),
      ]);
      return CustomScrollView(slivers: [
        SliverAppBar(pinned: true, backgroundColor: SideBColors.ivory,
          leading: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back)), title: const Text('SIDE B')),
        SliverToBoxAdapter(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: SideBLayout.maxContentWidth), child: Padding(
          padding: EdgeInsets.fromLTRB(padding, 20, padding, 112),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (wide) Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: copy), const SizedBox(width: 40), Expanded(child: hero)]) else ...[hero, const SizedBox(height: 24), copy],
            const SizedBox(height: 48),
            Text('Historias y lanzamientos', style: Theme.of(context).textTheme.headlineMedium),
            if (artist.posts.isNotEmpty) ...[
              const SizedBox(height: 20),
              ...artist.posts.map((post) => CompactPostCard(post: post, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PostDetailScreen(postId: post.id))))),
            ],
            if (artist.albums.isNotEmpty) ...[
              const SizedBox(height: 28),
              _AlbumGrid(albums: artist.albums),
            ],
            if (artist.posts.isEmpty && artist.albums.isEmpty) const Padding(padding: EdgeInsets.only(top: 20), child: Text('Aún no hay publicaciones ni álbumes asociados.')),
          ]),
        )))),
      ]);
    },
  );
}

class _AlbumGrid extends StatelessWidget {
  const _AlbumGrid({required this.albums});
  final List<Album> albums;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 16, runSpacing: 20,
    children: albums.map((album) => SizedBox(width: 180, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      NetworkCover(url: album.cover, aspectRatio: 1), const SizedBox(height: 8),
      Text(album.type?.toUpperCase() ?? 'ÁLBUM', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: SideBColors.accent)),
      const SizedBox(height: 3), Text(album.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleLarge),
    ]))).toList(growable: false),
  );
}

class _ArtistSkeleton extends StatelessWidget {
  const _ArtistSkeleton({required this.aspectRatio});
  final double aspectRatio;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      AspectRatio(aspectRatio: aspectRatio, child: const ColoredBox(color: SideBColors.skeleton)),
      const SizedBox(height: 10),
      const SizedBox(height: 18, child: ColoredBox(color: SideBColors.skeleton)),
      const SizedBox(height: 6),
      const SizedBox(width: 100, height: 12, child: ColoredBox(color: SideBColors.skeleton)),
    ],
  );
}
