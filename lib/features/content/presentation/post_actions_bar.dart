import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/config/api_config.dart';
import '../data/content_models.dart';
import 'post_reactions_bar.dart';

class PostActionsBar extends StatelessWidget {
  const PostActionsBar({
    super.key,
    required this.post,
    required this.onComment,
    this.color,
  });
  final Post post;
  final VoidCallback onComment;
  final Color? color;
  static const _shareChannel = MethodChannel('side_b/share');

  Future<void> _share(BuildContext context) async {
    final configured = const String.fromEnvironment('WEB_BASE_URL');
    final base = configured.isEmpty
        ? Uri(scheme: 'http', host: Uri.parse(ApiConfig.baseUrl).host)
        : Uri.parse(configured.endsWith('/') ? configured : '$configured/');
    final url = base
        .resolve('publicacion.php')
        .replace(queryParameters: {'slug': post.slug})
        .toString();
    try {
      try {
        await _shareChannel.invokeMethod<void>('share', {
          'title': post.title,
          'url': url,
        });
      } on MissingPluginException {
        await Clipboard.setData(ClipboardData(text: url));
        if (context.mounted)
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Enlace copiado.')));
      }
    } on PlatformException {
      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No pudimos abrir las opciones para compartir.'),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Expanded(
        flex: 4,
        child: PostReactionsBar(
          postId: post.id,
          initialCount: post.reactionsCount,
          color: color,
          compact: true,
        ),
      ),
      Expanded(
        flex: 3,
        child: TextButton(
          onPressed: onComment,
          style: TextButton.styleFrom(
            foregroundColor: color,
            minimumSize: const Size(0, 48),
            padding: const EdgeInsets.symmetric(horizontal: 4),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.messageCircle, size: 17),
                  const SizedBox(width: 4),
                  Text(
                    '${post.commentsCount}',
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              const Text(
                'Comentar',
                maxLines: 1,
                style: TextStyle(fontSize: 11),
              ),
            ],
          ),
        ),
      ),
      Expanded(
        flex: 3,
        child: TextButton(
          onPressed: () => _share(context),
          style: TextButton.styleFrom(
            foregroundColor: color,
            minimumSize: const Size(0, 48),
            padding: const EdgeInsets.symmetric(horizontal: 4),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.share2, size: 17),
              SizedBox(height: 3),
              Text('Compartir', maxLines: 1, style: TextStyle(fontSize: 11)),
            ],
          ),
        ),
      ),
    ],
  );
}
