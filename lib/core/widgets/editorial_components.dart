import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../features/content/data/content_models.dart';
import '../theme/side_b_theme.dart';
import '../utils/text_formatters.dart';

class EditorialHeader extends StatelessWidget {
  const EditorialHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.description,
  });
  final String eyebrow;
  final String title;
  final String? description;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final horizontal = constraints.maxWidth < 600 ? 20.0 : 32.0;
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Padding(
            padding: EdgeInsets.fromLTRB(horizontal, 24, horizontal, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow.toUpperCase(),
                  style: Theme.of(context).textTheme.labelMedium
                      ?.copyWith(color: SideBColors.accent),
                ),
                const SizedBox(height: 9),
                Text(title, style: Theme.of(context).textTheme.displaySmall),
                if (description != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    description!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    },
  );
}

class NetworkCover extends StatelessWidget {
  const NetworkCover({
    super.key,
    this.url,
    required this.aspectRatio,
    this.height,
    this.child,
  });
  final String? url;
  final double aspectRatio;
  final double? height;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final cover = ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: SideBColors.olive),
          if (url != null)
            Image.network(
              url!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox(),
            ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xB3292A27)],
              ),
            ),
          ),
          if (child != null) child!,
        ],
      ),
    );
    if (height != null) return SizedBox(height: height, child: cover);
    return AspectRatio(aspectRatio: aspectRatio, child: cover);
  }
}

class FeaturedPostCard extends StatelessWidget {
  const FeaturedPostCard({
    super.key,
    required this.post,
    required this.onTap,
    this.height,
  });
  final Post post;
  final VoidCallback onTap;
  final double? height;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: post.title,
    child: InkWell(
      onTap: onTap,
      child: NetworkCover(
        url: post.image,
        aspectRatio: 1.55,
        height: height,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                _tag(post).toUpperCase(),
                style: Theme.of(context).textTheme.labelMedium
                    ?.copyWith(color: SideBColors.ivory),
              ),
              const SizedBox(height: 8),
              Text(
                post.title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineMedium
                    ?.copyWith(color: SideBColors.ivory),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _meta(post),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium
                          ?.copyWith(color: SideBColors.ivory),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    LucideIcons.arrowUpRight,
                    color: SideBColors.ivory,
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class CompactPostCard extends StatelessWidget {
  const CompactPostCard({super.key, required this.post, required this.onTap});
  final Post post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: post.title,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 84,
              child: NetworkCover(url: post.image, aspectRatio: 1),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _tag(post).toUpperCase(),
                    style: Theme.of(context).textTheme.labelMedium
                        ?.copyWith(color: SideBColors.accent),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    post.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _meta(post),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 23),
              child: Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: SideBColors.graphite,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class EditorialPostCard extends StatelessWidget {
  const EditorialPostCard({super.key, required this.post, required this.onTap});
  final Post post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: post.title,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NetworkCover(url: post.image, aspectRatio: 1.35),
            const SizedBox(height: 13),
            Text(
              _tag(post).toUpperCase(),
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(color: SideBColors.accent),
            ),
            const SizedBox(height: 7),
            Text(
              post.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 9),
            Text(
              post.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 10),
            Text(_meta(post), style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
      ),
    ),
  );
}

String _tag(Post post) => post.author ?? 'Editorial';

String _meta(Post post) => [
  if (post.author != null) 'Por ${post.author}',
  if (post.date != null) formatSpanishDate(post.date),
].where((value) => value.isNotEmpty).join(' · ');
