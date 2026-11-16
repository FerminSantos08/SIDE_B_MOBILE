import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/side_b_theme.dart';
import '../data/reactions_repository.dart';

/// Owns only the gesture and overlay. Persistence stays in PostReactionsBar.
class ReactionGesturePicker extends StatefulWidget {
  const ReactionGesturePicker({
    super.key,
    required this.types,
    required this.builder,
    required this.onSelected,
    required this.iconFor,
    required this.colorFor,
    this.counts,
    this.activeId,
    this.enabled = true,
    this.onVisibilityChanged,
  });

  final List<ReactionType> types;
  final Map<String, int>? counts;
  final String? activeId;
  final bool enabled;
  final Widget Function(BuildContext, VoidCallback) builder;
  final ValueChanged<String> onSelected;
  final ValueChanged<bool>? onVisibilityChanged;
  final IconData Function(String) iconFor;
  final Color Function(String) colorFor;

  @override
  State<ReactionGesturePicker> createState() => _ReactionGesturePickerState();
}

class _ReactionGesturePickerState extends State<ReactionGesturePicker>
    with WidgetsBindingObserver {
  final _anchorKey = GlobalKey();
  final _slots = <String, GlobalKey>{};
  OverlayEntry? _entry;
  Rect _capsule = Rect.zero;
  String? _hovered;
  bool _gestural = false;
  Offset? _lastPosition;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didUpdateWidget(covariant ReactionGesturePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled || widget.types.isEmpty) {
      _dismiss(notify: false);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _entry?.markNeedsBuild();
      });
    }
  }

  @override
  void didChangeMetrics() => _dismiss();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _dismiss();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dismiss(notify: false);
    super.dispose();
  }

  void _dismiss({bool notify = true}) {
    final entry = _entry;
    _entry = null;
    entry?.remove();
    entry?.dispose();
    _hovered = null;
    _lastPosition = null;
    _gestural = false;
    if (entry != null && notify) widget.onVisibilityChanged?.call(false);
  }

  void _show({required bool gestural}) {
    if (!widget.enabled || widget.types.isEmpty) return;
    if (_entry != null) _dismiss();
    final anchor = _anchorKey.currentContext?.findRenderObject();
    final overlay = Overlay.of(context, rootOverlay: true);
    final box = overlay.context.findRenderObject();
    if (anchor is! RenderBox || box is! RenderBox) return;
    final media = MediaQuery.of(context);
    final position = anchor.localToGlobal(Offset.zero, ancestor: box);
    final width = math.min(320.0, box.size.width - 24);
    final left = (position.dx + anchor.size.width / 2 - width / 2).clamp(
      12.0,
      math.max(12.0, box.size.width - width - 12),
    );
    // Reserve space for the lifted icon and independent floating label.
    final minTop = media.padding.top + 62;
    final maxTop = math.max(
      minTop,
      box.size.height - media.padding.bottom - media.viewInsets.bottom - 80,
    );
    final top = (position.dy - 78).clamp(minTop, maxTop);
    _capsule = Rect.fromLTWH(left.toDouble(), top.toDouble(), width, 64);
    _gestural = gestural;
    _hovered = gestural ? null : widget.activeId;
    _entry = OverlayEntry(builder: _buildOverlay);
    overlay.insert(_entry!);
    widget.onVisibilityChanged?.call(true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _entry != null && _lastPosition != null) {
        _track(_lastPosition!);
      }
    });
  }

  void _toggle() {
    if (_entry == null) {
      _show(gestural: false);
    } else {
      _dismiss();
    }
  }

  String? _reactionAt(Offset globalPosition) {
    for (final type in widget.types) {
      final box = _slots[type.id]?.currentContext?.findRenderObject();
      if (box is! RenderBox || !box.hasSize) continue;
      final rect = Rect.fromPoints(
        box.localToGlobal(Offset.zero),
        box.localToGlobal(box.size.bottomRight(Offset.zero)),
      );
      // Each measured slot includes its raised icon, but not the action button
      // below. Releasing back on the original button cancels the choice.
      final target = Rect.fromLTRB(
        rect.left,
        rect.top - 22,
        rect.right,
        rect.bottom + 6,
      );
      if (target.contains(globalPosition)) return type.id;
    }
    return null;
  }

  void _track(Offset position) {
    _lastPosition = position;
    if (_entry == null) return;
    final next = _reactionAt(position);
    if (next != _hovered) {
      _hovered = next;
      _entry?.markNeedsBuild();
    }
  }

  void _confirm(String id) {
    _dismiss();
    widget.onSelected(id);
  }

  Widget _buildOverlay(BuildContext context) {
    final hovered = widget.types.where((type) => type.id == _hovered);
    final active = hovered.isEmpty ? null : hovered.first;
    final index = active == null ? -1 : widget.types.indexOf(active);
    final slotWidth = (_capsule.width - 16) / widget.types.length;
    const labelWidth = 126.0;
    final labelLeft = index < 0
        ? _capsule.left
        : (_capsule.left + 8 + slotWidth * (index + .5) - labelWidth / 2).clamp(
            8.0,
            MediaQuery.sizeOf(context).width - labelWidth - 8,
          );
    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): _dismiss},
      child: Focus(
        autofocus: true,
        child: Material(
          type: MaterialType.transparency,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _dismiss,
                  onPanStart: (_) => _dismiss(),
                  child: Semantics(
                    label: 'Cerrar reacciones',
                    button: true,
                    onTap: _dismiss,
                  ),
                ),
              ),
              Positioned.fromRect(
                rect: _capsule,
                child: DecoratedBox(
                  key: const ValueKey('reaction-capsule'),
                  decoration: BoxDecoration(
                    color: SideBColors.ivory,
                    borderRadius: BorderRadius.circular(36),
                    border: Border.all(color: SideBColors.border),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33292A27),
                        blurRadius: 20,
                        offset: Offset(0, 7),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        for (final type in widget.types)
                          Expanded(
                            child: SizedBox.expand(
                              key: _slots.putIfAbsent(
                                type.id,
                                () => GlobalKey(),
                              ),
                              child: Semantics(
                                label:
                                    '${type.label}, ${widget.counts?[type.id] ?? 'cargando'} reacciones',
                                selected: widget.activeId == type.id,
                                button: true,
                                onTap: () => _confirm(type.id),
                                child: GestureDetector(
                                  key: ValueKey('reaction-option-${type.id}'),
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () => _confirm(type.id),
                                  child: MouseRegion(
                                    onEnter: (_) {
                                      _hovered = type.id;
                                      _entry?.markNeedsBuild();
                                    },
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        AnimatedSlide(
                                          duration: const Duration(
                                            milliseconds: 140,
                                          ),
                                          curve: Curves.easeOutCubic,
                                          offset: _hovered == type.id
                                              ? const Offset(0, -.34)
                                              : Offset.zero,
                                          child: AnimatedScale(
                                            key: ValueKey(
                                              'reaction-scale-${type.id}',
                                            ),
                                            duration: const Duration(
                                              milliseconds: 140,
                                            ),
                                            curve: Curves.easeOutCubic,
                                            scale: _hovered == type.id
                                                ? 1.28
                                                : 1,
                                            child: Container(
                                              width: 38,
                                              height: 38,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: widget
                                                    .colorFor(type.color)
                                                    .withValues(
                                                      alpha: _hovered == type.id
                                                          ? .24
                                                          : .10,
                                                    ),
                                                border:
                                                    widget.activeId == type.id
                                                    ? Border.all(
                                                        color: widget.colorFor(
                                                          type.color,
                                                        ),
                                                        width: 1.5,
                                                      )
                                                    : null,
                                              ),
                                              child: Icon(
                                                widget.iconFor(type.symbol),
                                                color: widget.colorFor(
                                                  type.color,
                                                ),
                                                size: 23,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 1),
                                        Text(
                                          '${widget.counts?[type.id] ?? '–'}',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: SideBColors.graphite,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              if (active != null)
                Positioned(
                  left: labelLeft,
                  top: _capsule.top - 54,
                  width: labelWidth,
                  child: IgnorePointer(
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 100),
                        child: Container(
                          key: ValueKey('reaction-label-${active.id}'),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: SideBColors.graphite,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            active.label,
                            maxLines: 1,
                            style: const TextStyle(
                              color: SideBColors.ivory,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    key: _anchorKey,
    behavior: HitTestBehavior.opaque,
    onLongPressStart: widget.enabled
        ? (details) {
            _show(gestural: true);
            _track(details.globalPosition);
          }
        : null,
    onLongPressMoveUpdate: widget.enabled
        ? (details) => _track(details.globalPosition)
        : null,
    onLongPressEnd: widget.enabled
        ? (details) {
            if (!_gestural || _entry == null) return;
            _track(details.globalPosition);
            final choice = _hovered;
            _dismiss();
            if (choice != null) widget.onSelected(choice);
          }
        : null,
    onLongPressCancel: _dismiss,
    child: widget.builder(context, _toggle),
  );
}
