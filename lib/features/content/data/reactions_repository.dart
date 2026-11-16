import '../../../core/network/api_client.dart';

class ReactionType {
  const ReactionType({
    required this.id,
    required this.label,
    required this.symbol,
    this.color = '#858C77',
  });
  final String id, label, symbol;
  final String color;

  factory ReactionType.fromJson(Map<String, dynamic> json) => ReactionType(
    id: json['id'] as String,
    label: json['label'] as String,
    symbol: json['symbol'] as String,
    color: json['color'] as String? ?? '#858C77',
  );
}

class ReactionCatalog {
  ReactionCatalog({required this.enabled, required List<ReactionType> types})
    : types = List.unmodifiable(types) {
    if (types.length > maxTypes ||
        types.map((type) => type.id).toSet().length != types.length) {
      throw const FormatException('Catálogo de reacciones no válido');
    }
    if (enabled && types.isEmpty) {
      throw const FormatException('Faltan los tipos de reacción');
    }
  }

  static const maxTypes = 5;
  final bool enabled;
  final List<ReactionType> types;
  bool get available => enabled && types.isNotEmpty;

  factory ReactionCatalog.fromJson(Map<String, dynamic> json) =>
      ReactionCatalog(
        enabled: json['enabled'] as bool,
        types: (json['types'] as List)
            .map((item) => ReactionType.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
}

class ReactionSummary {
  ReactionSummary({required this.enabled, required Map<String, int> counts})
    : counts = Map.unmodifiable(counts);
  final bool enabled;
  final Map<String, int> counts;
  int get total => counts.values.fold(0, (sum, count) => sum + count);

  factory ReactionSummary.fromJson(Map<String, dynamic> json) =>
      ReactionSummary(
        enabled: json['enabled'] as bool,
        counts: (json['counts'] as Map<String, dynamic>).map(
          (key, value) => MapEntry(key, (value as num).toInt()),
        ),
      );
}

class ReactionsRepository {
  ReactionsRepository(this._api);
  final ApiClient _api;

  Future<ReactionCatalog> catalog() async => ReactionCatalog.fromJson(
    await _api.get('/reactions/types') as Map<String, dynamic>,
  );

  Future<ReactionSummary> summary(int postId) async => ReactionSummary.fromJson(
    await _api.get('/posts/$postId/reactions') as Map<String, dynamic>,
  );

  Future<String?> selected(int postId) async {
    final data =
        await _api.get('/posts/$postId/reaction') as Map<String, dynamic>;
    return data['reaction_id'] as String?;
  }

  Future<void> select(
    int postId,
    String reactionId,
    ReactionCatalog catalog,
  ) async {
    if (!catalog.available ||
        !catalog.types.any((type) => type.id == reactionId)) {
      throw ArgumentError('Tipo de reacción no disponible');
    }
    await _api.put(
      '/posts/$postId/reaction',
      data: {'reaction_id': reactionId},
    );
  }

  Future<void> remove(int postId) async {
    await _api.delete('/posts/$postId/reaction');
  }
}
