import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/side_b_theme.dart';
import '../../../core/utils/text_formatters.dart';
import '../../auth/auth.dart';
import '../../profile/presentation/profile_screen.dart';
import '../data/content_models.dart';
import 'content_providers.dart';

class PostCommentsSection extends ConsumerStatefulWidget {
  const PostCommentsSection({super.key, required this.postId});
  final int postId;

  @override
  ConsumerState<PostCommentsSection> createState() =>
      _PostCommentsSectionState();
}

class _PostCommentsSectionState extends ConsumerState<PostCommentsSection> {
  final _text = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _sending = false;
  bool _sessionExpired = false;
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_sending || !_form.currentState!.validate()) return;
    setState(() {
      _sending = true;
      _error = null;
      _sessionExpired = false;
    });
    try {
      await ref
          .read(contentRepositoryProvider)
          .addComment(widget.postId, _text.text);
      if (!mounted) return;
      _text.clear();
      ref.invalidate(commentsProvider(widget.postId));
      ref.invalidate(postsProvider);
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tu comentario se publicó.')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _sessionExpired = error is ApiException && error.statusCode == 401;
        _error = _sessionExpired
            ? 'Tu sesión venció. Inicia sesión de nuevo para publicar.'
            : 'No pudimos publicar tu comentario. Conservamos tu texto para que puedas reintentar.';
      });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _login() => Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const AuthScreen(register: false)),
  );

  @override
  Widget build(BuildContext context) {
    final comments = ref.watch(commentsProvider(widget.postId));
    final auth = ref.watch(authProvider);
    final user = auth.asData?.value;
    final theme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: Text('Comentarios', style: theme.headlineMedium)),
            if (comments.hasValue)
              Text('${comments.requireValue.length}', style: theme.titleLarge),
            IconButton(
              tooltip: 'Actualizar comentarios',
              onPressed: comments.isLoading
                  ? null
                  : () => ref.invalidate(commentsProvider(widget.postId)),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (user != null) ...[
          Text('Comenta como ${user.name}', style: theme.labelLarge),
          const SizedBox(height: 10),
          Form(
            key: _form,
            child: TextFormField(
              controller: _text,
              enabled: !_sending,
              minLines: 3,
              maxLines: 6,
              maxLength: 500,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Tu comentario',
                hintText: 'Comparte lo que te hizo pensar esta lectura…',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final text = (value ?? '').trim();
                if (text.isEmpty) {
                  return 'Escribe un comentario antes de publicar.';
                }
                if (text.runes.length > 500) {
                  return 'El máximo es de 500 caracteres.';
                }
                return null;
              },
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _sending ? null : _send,
              icon: _sending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_outlined, size: 18),
              label: Text(_sending ? 'PUBLICANDO…' : 'PUBLICAR COMENTARIO'),
            ),
          ),
        ] else if (auth.isLoading) ...[
          const Text('Recuperando tu sesión…'),
          const LinearProgressIndicator(),
        ] else if (auth.hasError) ...[
          const Text('No pudimos recuperar tu sesión para comentar.'),
          TextButton(
            onPressed: () => ref.invalidate(authProvider),
            child: const Text('REINTENTAR SESIÓN'),
          ),
        ] else ...[
          const Text('Inicia sesión para participar en la conversación.'),
          OutlinedButton(
            onPressed: _login,
            child: const Text('INICIAR SESIÓN'),
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          if (_sessionExpired)
            TextButton(onPressed: _login, child: const Text('INICIAR SESIÓN')),
        ],
        const SizedBox(height: 24),
        comments.when(
          skipLoadingOnRefresh: false,
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: LinearProgressIndicator(
              semanticsLabel: 'Cargando comentarios',
            ),
          ),
          error: (error, stackTrace) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('No pudimos cargar los comentarios.'),
              TextButton(
                onPressed: () =>
                    ref.invalidate(commentsProvider(widget.postId)),
                child: const Text('REINTENTAR'),
              ),
            ],
          ),
          data: (items) => items.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Todavía no hay comentarios. Sé la primera persona en comentar.',
                  ),
                )
              : Column(
                  children: [
                    for (final item in items) _CommentTile(comment: item),
                  ],
                ),
        ),
      ],
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment});
  final PostComment comment;

  @override
  Widget build(BuildContext context) {
    final name = comment.author.trim();
    final date = DateTime.tryParse(comment.date ?? '');
    final timestamp = date == null
        ? formatSpanishDate(comment.date)
        : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} · ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipOval(
            child: SizedBox(
              width: 40,
              height: 40,
              child: comment.avatarUrl == null || comment.avatarUrl!.isEmpty
                  ? _initial(name)
                  : Image.network(
                      comment.avatarUrl!,
                      fit: BoxFit.cover,
                      excludeFromSemantics: true,
                      errorBuilder: (context, error, stackTrace) =>
                          _initial(name),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? 'Comunidad SIDE B' : name,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                if (timestamp.isNotEmpty)
                  Text(timestamp, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 8),
                Text(
                  comment.text,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _initial(String name) => CircleAvatar(
    backgroundColor: SideBColors.olive,
    foregroundColor: SideBColors.ivory,
    child: Text(name.isEmpty ? '?' : name.characters.first.toUpperCase()),
  );
}
