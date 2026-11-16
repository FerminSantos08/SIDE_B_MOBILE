import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/side_b_theme.dart';
import '../../auth/auth.dart';
import '../../profile/presentation/profile_screen.dart';
import '../data/reactions_repository.dart';
import 'reaction_providers.dart';
import 'reaction_gesture_picker.dart';

IconData reactionIcon(String name) => switch (name) {
  'heart' => LucideIcons.heart,
  'music-2' => LucideIcons.music2,
  'headphones' => LucideIcons.headphones,
  'sparkles' => LucideIcons.sparkles,
  _ => LucideIcons.heart,
};

Color reactionColor(String hex) {
  final value = int.tryParse(hex.replaceFirst('#', ''), radix: 16);
  return value == null ? SideBColors.olive : Color(0xFF000000 | value);
}

class PostReactionsBar extends ConsumerStatefulWidget {
  const PostReactionsBar({
    super.key,
    required this.postId,
    this.initialCount = 0,
    this.color,
    this.compact = false,
  });
  final int postId, initialCount;
  final Color? color;
  final bool compact;

  @override
  ConsumerState<PostReactionsBar> createState() => _PostReactionsBarState();
}

class _PostReactionsBarState extends ConsumerState<PostReactionsBar> {
  bool _busy = false;

  void _message(String text) {
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  bool _selectorOpen = false;
  bool _committing = false;

  Future<void> _commit(String choice, ReactionCatalog catalog) async {
    if (_committing) return;
    _committing = true;
    final subscription = ref.listenManual(
      reactionSummaryProvider(widget.postId),
      (_, _) {},
    );
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
      setState(() => _busy = true);
      final previous = await ref.read(
        selectedReactionProvider(widget.postId).future,
      );
      if (!mounted) return;
      final repository = ref.read(reactionsRepositoryProvider);
      if (previous == choice) {
        await repository.remove(widget.postId);
      } else {
        await repository.select(widget.postId, choice, catalog);
      }
      if (!mounted) return;
      ref.invalidate(selectedReactionProvider(widget.postId));
      ref.invalidate(reactionSummaryProvider(widget.postId));
      try {
        final updated = await ref.read(
          reactionSummaryProvider(widget.postId).future,
        );
        if (mounted)
          ref
              .read(reactionUpdatesProvider.notifier)
              .update(widget.postId, updated);
      } catch (_) {
        _message('Reacción guardada. Actualiza para ver los conteos.');
      }
    } catch (error) {
      if (error is ApiException && error.statusCode == 401) {
        if (mounted) ref.invalidate(authProvider);
        _message('Tu sesión venció. Inicia sesión de nuevo para reaccionar.');
      } else {
        _message('No pudimos actualizar las reacciones. Intenta de nuevo.');
      }
    } finally {
      subscription.close();
      _committing = false;
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalogState = ref.watch(reactionCatalogProvider);
    final catalog = catalogState.asData?.value;
    if (catalog == null) {
      return _unavailableButton(
        catalogState.hasError
            ? () => ref.invalidate(reactionCatalogProvider)
            : null,
      );
    }
    if (!catalog.available) return _unavailableButton(null);
    final selected = ref.watch(selectedReactionProvider(widget.postId));
    final id = selected.asData?.value;
    final matching = catalog.types.where((type) => type.id == id);
    final active = matching.isEmpty ? null : matching.first;
    final total =
        ref.watch(reactionUpdatesProvider)[widget.postId]?.total ??
        widget.initialCount;
    final color = active == null ? widget.color : reactionColor(active.color);
    final summary = _selectorOpen
        ? ref.watch(reactionSummaryProvider(widget.postId)).asData?.value
        : ref.watch(reactionUpdatesProvider)[widget.postId];
    return ReactionGesturePicker(
      types: catalog.types,
      counts: summary?.counts,
      activeId: id,
      enabled: !_committing,
      iconFor: reactionIcon,
      colorFor: reactionColor,
      onVisibilityChanged: (visible) {
        if (mounted) setState(() => _selectorOpen = visible);
      },
      onSelected: (choice) => _commit(choice, catalog),
      builder: (context, open) => Semantics(
        selected: active != null,
        label:
            '${active?.label ?? 'Reaccionar'}, $total reacciones. Mantén presionado y desliza para elegir.',
        child: TextButton(
          key: ValueKey('reaction-trigger-${widget.postId}'),
          onPressed: _committing ? null : open,
          style: TextButton.styleFrom(
            foregroundColor: color,
            minimumSize: const Size(0, 48),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            backgroundColor: active == null
                ? null
                : reactionColor(active.color).withValues(alpha: .10),
          ),
          child: widget.compact
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _icon(active),
                        const SizedBox(width: 4),
                        Text('$total', style: const TextStyle(fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      active?.label ?? 'Reaccionar',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _icon(active),
                    const SizedBox(width: 6),
                    Text(active?.label ?? 'Reaccionar'),
                    const SizedBox(width: 6),
                    Text('$total'),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _icon(ReactionType? active) => _busy
      ? const SizedBox(
          width: 17,
          height: 17,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
      : Icon(reactionIcon(active?.symbol ?? 'heart'), size: 17);

  Widget _unavailableButton(VoidCallback? retry) => TextButton(
    onPressed: retry,
    style: TextButton.styleFrom(
      foregroundColor: widget.color,
      minimumSize: const Size(0, 48),
      padding: const EdgeInsets.symmetric(horizontal: 6),
    ),
    child: widget.compact
        ? const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.heart, size: 17),
              SizedBox(height: 3),
              Text('Reaccionar', style: TextStyle(fontSize: 11)),
            ],
          )
        : const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.heart, size: 17),
              SizedBox(width: 6),
              Text('Reaccionar'),
            ],
          ),
  );
}
