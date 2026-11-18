import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/async_state.dart';
import '../../auth/auth.dart';
import 'creation_hub_screen.dart';
import 'creation_providers.dart';

String editorialStateLabel(String? state) => switch (state) {
  'borrador' => 'Borrador',
  'revision' => 'En revisión',
  'publicado' => 'Publicado',
  'archivado' => 'Archivado',
  _ => state ?? '',
};

class EditorialManagementScreen extends ConsumerStatefulWidget {
  const EditorialManagementScreen({super.key});
  @override
  ConsumerState<EditorialManagementScreen> createState() =>
      _EditorialManagementScreenState();
}

class _EditorialManagementScreenState
    extends ConsumerState<EditorialManagementScreen> {
  String _filter = 'todos';
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).asData?.value;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          user?.canManageAllPosts == true
              ? 'Administración editorial.'
              : 'Mis publicaciones.',
        ),
      ),
      floatingActionButton: user?.canPublish == true
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const PublicationEditorScreen(),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('CREAR PUBLICACIÓN'),
            )
          : null,
      body: user?.canPublish != true
          ? const EmptyView(
              message:
                  'Tu cuenta no tiene acceso a la administración editorial.',
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: DropdownButtonFormField<String>(
                    initialValue: _filter,
                    decoration: const InputDecoration(labelText: 'Estado'),
                    items: [
                      const DropdownMenuItem(
                        value: 'todos',
                        child: Text('Todos'),
                      ),
                      for (final state in [
                        'borrador',
                        'revision',
                        'publicado',
                        'archivado',
                      ])
                        DropdownMenuItem(
                          value: state,
                          child: Text(editorialStateLabel(state)),
                        ),
                    ],
                    onChanged: (value) => setState(() => _filter = value!),
                  ),
                ),
                Expanded(
                  child: ref
                      .watch(managedPostsProvider)
                      .when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (_, _) => AsyncErrorView(
                          message: 'No pudimos cargar las publicaciones.',
                          onRetry: () => ref.invalidate(managedPostsProvider),
                        ),
                        data: (posts) {
                          final items = posts
                              .where(
                                (post) =>
                                    _filter == 'todos' ||
                                    post.status == _filter,
                              )
                              .toList();
                          return RefreshIndicator(
                            onRefresh: () async {
                              ref.invalidate(managedPostsProvider);
                              await ref.read(managedPostsProvider.future);
                            },
                            child: ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                16,
                                20,
                                110,
                              ),
                              itemCount: items.isEmpty ? 1 : items.length,
                              separatorBuilder: (_, _) =>
                                  const Divider(height: 24),
                              itemBuilder: (context, index) {
                                if (items.isEmpty)
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 32),
                                    child: Text(
                                      'No hay publicaciones con este estado.',
                                    ),
                                  );
                                final post = items[index];
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(post.title),
                                  subtitle: Text(
                                    '${editorialStateLabel(post.status)} · ${post.author ?? 'Editorial'}',
                                  ),
                                  trailing: const Icon(Icons.edit_outlined),
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => PublicationEditorScreen(
                                        postId: post.id,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                ),
              ],
            ),
    );
  }
}

class PublicationEditorScreen extends ConsumerWidget {
  const PublicationEditorScreen({super.key, this.postId});
  final int? postId;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(
      title: Text(
        postId == null ? 'Nueva publicación.' : 'Editar publicación.',
      ),
    ),
    body: postId == null
        ? const CreationHubScreen()
        : ref
              .watch(editablePostProvider(postId!))
              .when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => AsyncErrorView(
                  message: 'No pudimos abrir el editor. Comprueba que tengas permiso.',
                  onRetry: () => ref.invalidate(editablePostProvider(postId!)),
                ),
                data: (value) => CreationHubScreen(
                  key: ValueKey(value.post.id),
                  initial: value,
                ),
              ),
  );
}
