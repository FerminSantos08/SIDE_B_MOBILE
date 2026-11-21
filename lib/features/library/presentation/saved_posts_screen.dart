import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/widgets/async_state.dart';
import '../../../core/utils/text_formatters.dart';
import '../../../core/widgets/editorial_components.dart';
import '../../auth/auth.dart';
import '../../content/presentation/post_detail_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../data/saved_posts_repository.dart';

class SavePostButton extends ConsumerStatefulWidget {
  const SavePostButton({super.key, required this.postId});
  final int postId;
  @override
  ConsumerState<SavePostButton> createState() => _SavePostButtonState();
}

class _SavePostButtonState extends ConsumerState<SavePostButton> {
  bool _busy = false;
  Future<void> _toggle() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(authProvider.future);
      if (!mounted) return;
      if (ref.read(authProvider).asData?.value == null) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const AuthScreen(register: false),
          ),
        );
        if (!mounted || ref.read(authProvider).asData?.value == null) return;
      }
      if (ref.read(savedPostsProvider).hasError)
        ref.invalidate(savedPostsProvider);
      final library = await ref.read(savedPostsProvider.future);
      if (!mounted) return;
      final repository = ref.read(savedPostsRepositoryProvider);
      if (library.ids.contains(widget.postId)) {
        await repository.remove(widget.postId);
      } else {
        await repository.save(widget.postId);
      }
      if (!mounted) return;
      ref.invalidate(savedPostsProvider);
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is ApiException
                  ? error.message
                  : 'No pudimos actualizar tus guardados.',
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final library = ref.watch(savedPostsProvider).asData?.value;
    final saved = library?.ids.contains(widget.postId) ?? false;
    return IconButton(
      tooltip: saved
          ? 'Quitar publicación de guardados'
          : 'Guardar publicación',
      onPressed: _busy ? null : _toggle,
      icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border),
    );
  }
}

class SavedPostsScreen extends ConsumerStatefulWidget {
  const SavedPostsScreen({super.key});
  @override
  ConsumerState<SavedPostsScreen> createState() => _SavedPostsScreenState();
}

class _SavedPostsScreenState extends ConsumerState<SavedPostsScreen> {
  final _removing = <int>{};
  Future<void> _remove(int id) async {
    if (_removing.contains(id)) return;
    setState(() => _removing.add(id));
    try {
      await ref.read(savedPostsRepositoryProvider).remove(id);
      if (mounted) ref.invalidate(savedPostsProvider);
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is ApiException
                  ? error.message
                  : 'No pudimos quitar la publicación.',
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => _removing.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Publicaciones guardadas.')),
      body: auth.isLoading
          ? const Center(child: CircularProgressIndicator())
          : auth.asData?.value == null
          ? Center(
              child: FilledButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AuthScreen(register: false),
                  ),
                ),
                child: const Text('INICIAR SESIÓN'),
              ),
            )
          : ref
                .watch(savedPostsProvider)
                .when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, _) => AsyncErrorView(
                    message: 'No pudimos cargar tus guardados.',
                    onRetry: () => ref.invalidate(savedPostsProvider),
                  ),
                  data: (library) => library.posts.isEmpty
                      ? const EmptyView(
                          message: 'Aún no tienes publicaciones guardadas disponibles. Guarda un artículo desde su marcador.',
                        )
                      : RefreshIndicator(
                          onRefresh: () async {
                            ref.invalidate(savedPostsProvider);
                            await ref.read(savedPostsProvider.future);
                          },
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 52),
                            itemCount: library.posts.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final post = library.posts[index];
                              return Card(
                                clipBehavior: Clip.antiAlias,
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  leading: SizedBox(
                                    width: 64,
                                    height: 64,
                                    child: NetworkCover(
                                      url: post.image,
                                      aspectRatio: 1,
                                    ),
                                  ),
                                  title: Text(
                                    post.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(fontSize: 24),
                                  ),
                                  subtitle: Text(
                                    [
                                          post.author ?? 'Editorial',
                                          formatSpanishDate(post.date),
                                        ]
                                        .where((text) => text.isNotEmpty)
                                        .join(' · '),
                                  ),
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) =>
                                          PostDetailScreen(postId: post.id),
                                    ),
                                  ),
                                  trailing: IconButton(
                                    tooltip: 'Quitar de guardados',
                                    onPressed: _removing.contains(post.id)
                                        ? null
                                        : () => _remove(post.id),
                                    icon: const Icon(
                                      Icons.bookmark_remove_outlined,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
    );
  }
}
