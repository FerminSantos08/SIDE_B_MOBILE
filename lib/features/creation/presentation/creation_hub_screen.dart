import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/side_b_theme.dart';
import '../../../core/widgets/async_state.dart';
import '../../../core/widgets/editorial_components.dart';
import '../../auth/auth.dart';
import '../../content/presentation/content_providers.dart';
import '../data/editorial_repository.dart';
import 'creation_providers.dart';

class CreationHubScreen extends ConsumerStatefulWidget {
  const CreationHubScreen({super.key});

  @override
  ConsumerState<CreationHubScreen> createState() => _CreationHubScreenState();
}

class _CreationHubScreenState extends ConsumerState<CreationHubScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _tags = TextEditingController();
  final _content = TextEditingController();
  final _artistIds = <int>{};
  final _albumIds = <int>{};
  var _publicationState = 'borrador';
  var _saving = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _tags.dispose();
    _content.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).asData?.value;
    if (user == null || !user.canPublish) return const _NoCreationAccess();

    final options = ref.watch(editorialOptionsProvider);
    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        const SliverToBoxAdapter(
          child: EditorialHeader(
            eyebrow: 'Herramientas de creacion',
            title: 'Comparte\nalgo distinto.',
            description:
                'Escribe, relaciona y guarda una nueva publicacion editorial.',
          ),
        ),
        options.when(
          loading: () => const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => SliverFillRemaining(
            child: AsyncErrorView(
              message: 'No pudimos preparar el editor.',
              onRetry: () => ref.invalidate(editorialOptionsProvider),
            ),
          ),
          data: (data) => SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 132),
                  child: Form(
                    key: _form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _field(
                          controller: _title,
                          label: 'Titulo',
                          maxLength: 200,
                          validator: (value) =>
                              value == null || value.trim().length < 3
                              ? 'Escribe un titulo de al menos 3 caracteres.'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        _field(
                          controller: _description,
                          label: 'Descripcion breve',
                          maxLength: 500,
                          minLines: 2,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        _field(
                          controller: _tags,
                          label: 'Etiquetas',
                          hint: 'musica, cultura, entrevista',
                          maxLength: 255,
                        ),
                        const SizedBox(height: 16),
                        _field(
                          controller: _content,
                          label: 'Contenido',
                          hint: 'Cuenta la historia...',
                          minLines: 8,
                          maxLines: 14,
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Escribe el contenido de la publicacion.'
                              : null,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'ESTADO',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _publicationState,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'borrador',
                              child: Text('Borrador'),
                            ),
                            DropdownMenuItem(
                              value: 'revision',
                              child: Text('En revision'),
                            ),
                            DropdownMenuItem(
                              value: 'publicado',
                              child: Text('Publicado'),
                            ),
                            DropdownMenuItem(
                              value: 'archivado',
                              child: Text('Archivado'),
                            ),
                          ],
                          onChanged: _saving
                              ? null
                              : (value) => setState(
                                  () => _publicationState =
                                      value ?? _publicationState,
                                ),
                        ),
                        const SizedBox(height: 24),
                        _RelationSelector(
                          title: 'Artistas relacionados',
                          emptyMessage: 'Sin artistas relacionados.',
                          options: data.artists
                              .map(
                                (artist) =>
                                    _SelectableOption(artist.id, artist.name),
                              )
                              .toList(growable: false),
                          selected: _artistIds,
                          enabled: !_saving,
                          onChanged: (ids) {
                            setState(() {
                              _artistIds
                                ..clear()
                                ..addAll(ids);
                              _albumIds.removeWhere(
                                (albumId) => !data.albums
                                    .where((album) => album.id == albumId)
                                    .any(
                                      (album) =>
                                          _artistIds.contains(album.artistId),
                                    ),
                              );
                            });
                          },
                        ),
                        const SizedBox(height: 20),
                        _RelationSelector(
                          title: 'Albumes relacionados',
                          emptyMessage: _artistIds.isEmpty
                              ? 'Selecciona primero uno o mas artistas.'
                              : 'No hay albumes para los artistas seleccionados.',
                          options: data.albums
                              .where(
                                (album) => _artistIds.contains(album.artistId),
                              )
                              .map(
                                (album) => _SelectableOption(
                                  album.id,
                                  '${album.artist} — ${album.title}',
                                ),
                              )
                              .toList(growable: false),
                          selected: _albumIds,
                          enabled: !_saving && _artistIds.isNotEmpty,
                          onChanged: (ids) => setState(() {
                            _albumIds
                              ..clear()
                              ..addAll(ids);
                          }),
                        ),
                        const SizedBox(height: 28),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: SideBColors.accent,
                            minimumSize: const Size.fromHeight(52),
                          ),
                          onPressed: _saving ? null : _save,
                          icon: const Icon(Icons.publish_outlined),
                          label: Text(
                            _saving
                                ? 'GUARDANDO...'
                                : _publicationState == 'publicado'
                                ? 'PUBLICAR'
                                : 'GUARDAR PUBLICACION',
                          ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    String? hint,
    int? maxLength,
    int minLines = 1,
    int? maxLines = 1,
    String? Function(String?)? validator,
  }) => TextFormField(
    controller: controller,
    minLines: minLines,
    maxLines: maxLines,
    maxLength: maxLength,
    validator: validator,
    onChanged: (_) {
      if (_error != null) setState(() => _error = null);
    },
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      border: const OutlineInputBorder(),
      alignLabelWithHint: minLines > 1,
    ),
  );

  Future<void> _save() async {
    if (!_form.currentState!.validate() || _saving) return;
    final submittedState = _publicationState;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(editorialRepositoryProvider)
          .create(
            PublicationDraft(
              title: _title.text.trim(),
              description: _emptyToNull(_description.text),
              content: _content.text.trim(),
              tags: _emptyToNull(_tags.text),
              state: submittedState,
              artistIds: _artistIds.toList(growable: false),
              albumIds: _albumIds.toList(growable: false),
            ),
          );
      ref.invalidate(postsProvider);
      if (!mounted) return;
      setState(() {
        _title.clear();
        _description.clear();
        _tags.clear();
        _content.clear();
        _artistIds.clear();
        _albumIds.clear();
        _publicationState = 'borrador';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            submittedState == 'publicado'
                ? 'Publicacion creada.'
                : 'Publicacion guardada como borrador.',
          ),
        ),
      );
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _emptyToNull(String value) =>
      value.trim().isEmpty ? null : value.trim();
}

class _RelationSelector extends StatelessWidget {
  const _RelationSelector({
    required this.title,
    required this.emptyMessage,
    required this.options,
    required this.selected,
    required this.enabled,
    required this.onChanged,
  });
  final String title;
  final String emptyMessage;
  final List<_SelectableOption> options;
  final Set<int> selected;
  final bool enabled;
  final ValueChanged<Set<int>> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title.toUpperCase(), style: Theme.of(context).textTheme.labelMedium),
      const SizedBox(height: 8),
      if (options.isEmpty)
        Text(emptyMessage, style: Theme.of(context).textTheme.bodyMedium)
      else
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options
              .map((option) {
                final isSelected = selected.contains(option.id);
                return FilterChip(
                  label: Text(option.label),
                  selected: isSelected,
                  selectedColor: SideBColors.olive.withOpacity(.35),
                  onSelected: !enabled
                      ? null
                      : (value) {
                          final next = {...selected};
                          value ? next.add(option.id) : next.remove(option.id);
                          onChanged(next);
                        },
                );
              })
              .toList(growable: false),
        ),
    ],
  );
}

class _SelectableOption {
  const _SelectableOption(this.id, this.label);
  final int id;
  final String label;
}

class _NoCreationAccess extends StatelessWidget {
  const _NoCreationAccess();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(24),
      child: Text('Tu cuenta no tiene permiso para crear publicaciones.'),
    ),
  );
}
