import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/layout/side_b_layout.dart';
import '../../../core/theme/side_b_theme.dart';
import '../../../core/utils/text_formatters.dart';
import '../../../core/widgets/async_state.dart';
import '../../../core/widgets/editorial_components.dart';
import 'content_providers.dart';

class PostDetailScreen extends ConsumerWidget {
  const PostDetailScreen({super.key, required this.postId});
  final int postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(postProvider(postId));
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final padding = SideBLayout.horizontalPadding(width);
            final imageHeight = SideBLayout.featuredPostHeight(width);
            return state.when(
              loading: () => _DetailSkeleton(width: width),
              error: (_, __) => AsyncErrorView(
                message: 'No pudimos abrir esta publicación.',
                onRetry: () => ref.invalidate(postProvider(postId)),
              ),
              data: (post) => CustomScrollView(
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    backgroundColor: SideBColors.ivory,
                    leading: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(LucideIcons.arrowLeft),
                    ),
                    title: const Text('SIDE B'),
                  ),
                  SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 780),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            padding,
                            20,
                            padding,
                            32,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              NetworkCover(
                                url: post.image,
                                aspectRatio: 1.2,
                                height: imageHeight,
                              ),
                              const SizedBox(height: 24),
                              Text(
                                (post.author ?? 'Editorial').toUpperCase(),
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(color: SideBColors.accent),
                              ),
                              const SizedBox(height: 9),
                              Text(
                                post.title,
                                style: Theme.of(context).textTheme.displaySmall,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                [post.author, formatSpanishDate(post.date)]
                                    .whereType<String>()
                                    .where((value) => value.isNotEmpty)
                                    .join(' · '),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              if (post.authorRole != null) ...[
                                const SizedBox(height: 5),
                                Text(
                                  post.authorRole!,
                                  style: Theme.of(context).textTheme.labelMedium
                                      ?.copyWith(color: SideBColors.accent),
                                ),
                              ],
                              if (post.status != null) ...[
                                const SizedBox(height: 12),
                                _StatusLabel(status: post.status!),
                              ],
                              const SizedBox(height: 28),
                              HtmlArticleBody(
                                html: post.content ?? post.description,
                              ),
                              if (post.tags.isNotEmpty) ...[
                                const SizedBox(height: 30),
                                _TagList(tags: post.tags),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

}

class HtmlArticleBody extends StatelessWidget {
  const HtmlArticleBody({super.key, required this.html});

  final String html;

  @override
  Widget build(BuildContext context) {
    final blocks = _articleBlocks(html);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < blocks.length; index++) ...[
          _ArticleBlock(block: blocks[index]),
          if (index < blocks.length - 1) const SizedBox(height: 18),
        ],
      ],
    );
  }
}

class _ArticleBlock extends StatelessWidget {
  const _ArticleBlock({required this.block});

  final _HtmlBlock block;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final style = switch (block.tag) {
      'h2' => theme.headlineMedium?.copyWith(fontSize: 27, height: 1.05),
      'h3' => theme.titleLarge?.copyWith(fontSize: 18, height: 1.2),
      _ => theme.bodyLarge,
    };
    return Text.rich(
      TextSpan(style: style, children: _inlineSpans(block.html, style)),
    );
  }
}

class _StatusLabel extends StatelessWidget {
  const _StatusLabel({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: SideBColors.olive,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      status.toUpperCase(),
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: SideBColors.ivory,
        letterSpacing: .8,
      ),
    ),
  );
}

class _TagList extends StatelessWidget {
  const _TagList({required this.tags});

  final List<String> tags;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: tags
        .map(
          (tag) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: SideBColors.border),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(tag, style: Theme.of(context).textTheme.labelMedium),
          ),
        )
        .toList(growable: false),
  );
}

class _HtmlBlock {
  const _HtmlBlock(this.tag, this.html);

  final String tag;
  final String html;
}

List<_HtmlBlock> _articleBlocks(String html) {
  final matches = RegExp(
    r'<(p|h2|h3)\b[^>]*>([\s\S]*?)</\1>',
    caseSensitive: false,
  ).allMatches(html);
  if (matches.isEmpty) return [_HtmlBlock('p', html)];
  return matches
      .map(
        (match) => _HtmlBlock(
          match.group(1)!.toLowerCase(),
          match.group(2)!,
        ),
      )
      .toList(growable: false);
}

List<InlineSpan> _inlineSpans(String html, TextStyle? baseStyle) {
  final spans = <InlineSpan>[];
  final tagPattern = RegExp(r'</?(em|strong)\b[^>]*>', caseSensitive: false);
  var cursor = 0;
  var emphasis = false;
  var strong = false;

  for (final match in tagPattern.allMatches(html)) {
    if (match.start > cursor) {
      spans.add(
        _textSpan(html.substring(cursor, match.start), baseStyle, emphasis, strong),
      );
    }
    final token = match.group(0)!.toLowerCase();
    final tag = match.group(1)!.toLowerCase();
    final opening = !token.startsWith('</');
    if (tag == 'em') emphasis = opening;
    if (tag == 'strong') strong = opening;
    cursor = match.end;
  }
  if (cursor < html.length) {
    spans.add(_textSpan(html.substring(cursor), baseStyle, emphasis, strong));
  }
  return spans;
}

TextSpan _textSpan(String value, TextStyle? base, bool emphasis, bool strong) {
  final text = normalizeApiText(
    value
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'"),
  );
  return TextSpan(
    text: text,
    style: base?.copyWith(
      fontStyle: emphasis ? FontStyle.italic : null,
      fontWeight: strong ? FontWeight.w700 : null,
    ),
  );
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton({required this.width});
  final double width;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 780),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          SideBLayout.horizontalPadding(width),
          20,
          SideBLayout.horizontalPadding(width),
          24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 50),
            _DetailBlock(height: SideBLayout.featuredPostHeight(width)),
            const SizedBox(height: 25),
            const _DetailBlock(height: 12, width: 70),
            const SizedBox(height: 12),
            const _DetailBlock(height: 84),
            const SizedBox(height: 20),
            const _DetailBlock(height: 16, width: 160),
            const SizedBox(height: 30),
            const _DetailBlock(height: 180),
          ],
        ),
      ),
    ),
  );
}

class _DetailBlock extends StatelessWidget {
  const _DetailBlock({required this.height, this.width});
  final double height;
  final double? width;

  @override
  Widget build(BuildContext context) =>
      Container(height: height, width: width, color: SideBColors.skeleton);
}
