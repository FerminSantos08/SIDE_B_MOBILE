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
    this.coverToken,
  });
  final String title;
  final String? description;
  final String content;
  final String? tags;
  final String state;
  final List<int> artistIds;
  final String? coverToken;
  final List<int> albumIds;

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'content': content,
    'tags': tags,
    'state': state,
    'artist_ids': artistIds,
    'album_ids': albumIds,
    if (coverToken != null) 'cover_token': coverToken,
  };
}

class EditorialRepository {
  EditorialRepository(this._api);
  final ApiClient _api;

  Future<String> uploadCover(List<int> bytes) async {
    final data = await _api.postBytes(
      '/editorial/covers',
      bytes,
    ) as Map<String, dynamic>;
    return data['token'] as String;
  }

  Future<List<Post>> publications() async {
    final data = await _api.get('/editorial/posts') as Map<String, dynamic>;
    return (data['posts'] as List)
        .map((row) => Post.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<EditablePublication> editable(int id) async =>
      EditablePublication.fromJson(
        await _api.get('/editorial/posts/$id') as Map<String, dynamic>,
      );

  Future<EditablePublication> update(
    int id,
    PublicationDraft draft,
    String revision,
  ) async => EditablePublication.fromJson(
    await _api.put(
      '/editorial/posts/$id',
      data: {...draft.toJson(), 'revision': revision},
    ) as Map<String, dynamic>,
  );

  Future<EditorialOptions> options() async => EditorialOptions.fromJson(
    await _api.get('/posts/editorial/options') as Map<String, dynamic>,
  );

  Future<Post> create(PublicationDraft draft) async {
    final data =
        await _api.post('/posts', data: draft.toJson()) as Map<String, dynamic>;
    return Post.fromJson(data['post'] as Map<String, dynamic>);
  }
}

class EditablePublication {
  const EditablePublication({
    required this.post,
    required this.artistIds,
    required this.albumIds,
    required this.revision,
  });
  final Post post;
  final List<int> artistIds, albumIds;
  final String revision;
  factory EditablePublication.fromJson(Map<String, dynamic> json) =>
      EditablePublication(
        post: Post.fromJson(json['post'] as Map<String, dynamic>),
        artistIds: (json['artist_ids'] as List).cast<int>(),
        albumIds: (json['album_ids'] as List).cast<int>(),
        revision: json['revision'] as String,
      );
}
