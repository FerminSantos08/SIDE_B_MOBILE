import '../../../core/network/api_client.dart';
import '../../content/data/content_models.dart';

class EditorialOptions {
  const EditorialOptions({required this.artists, required this.albums});
  final List<EditorialArtistOption> artists;
  final List<EditorialAlbumOption> albums;

  factory EditorialOptions.fromJson(Map<String, dynamic> json) =>
      EditorialOptions(
        artists: ((json['artists'] ?? []) as List)
            .map(
              (item) =>
                  EditorialArtistOption.fromJson(item as Map<String, dynamic>),
            )
            .toList(growable: false),
        albums: ((json['albums'] ?? []) as List)
            .map(
              (item) =>
                  EditorialAlbumOption.fromJson(item as Map<String, dynamic>),
            )
            .toList(growable: false),
      );
}

class EditorialArtistOption {
  const EditorialArtistOption({required this.id, required this.name});
  final int id;
  final String name;

  factory EditorialArtistOption.fromJson(Map<String, dynamic> json) =>
      EditorialArtistOption(
        id: json['id'] as int,
        name: json['nombre'] as String,
      );
}

class EditorialAlbumOption {
  const EditorialAlbumOption({
    required this.id,
    required this.artistId,
    required this.artist,
    required this.title,
  });
  final int id;
  final int artistId;
  final String artist;
  final String title;

  factory EditorialAlbumOption.fromJson(Map<String, dynamic> json) =>
      EditorialAlbumOption(
        id: json['id'] as int,
        artistId: json['artist_id'] as int,
        artist: json['artist'] as String,
        title: json['titulo'] as String,
      );
}

class PublicationDraft {
  const PublicationDraft({
    required this.title,
    required this.content,
    required this.state,
    this.description,
    this.tags,
    this.artistIds = const [],
    this.albumIds = const [],
  });
  final String title;
  final String? description;
  final String content;
  final String? tags;
  final String state;
  final List<int> artistIds;
  final List<int> albumIds;

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'content': content,
    'tags': tags,
    'state': state,
    'artist_ids': artistIds,
    'album_ids': albumIds,
  };
}

class EditorialRepository {
  EditorialRepository(this._api);
  final ApiClient _api;

  Future<EditorialOptions> options() async => EditorialOptions.fromJson(
    await _api.get('/posts/editorial/options') as Map<String, dynamic>,
  );

  Future<Post> create(PublicationDraft draft) async {
    final data =
        await _api.post('/posts', data: draft.toJson()) as Map<String, dynamic>;
    return Post.fromJson(data['post'] as Map<String, dynamic>);
  }
}
