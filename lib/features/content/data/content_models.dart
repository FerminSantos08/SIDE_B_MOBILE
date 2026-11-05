import '../../../core/utils/text_formatters.dart';

class Post {
  const Post({
    required this.id,
    required this.title,
    required this.description,
    required this.slug,
    this.content,
    this.image,
    this.author,
    this.date,
    this.tags = const [],
    this.status,
    this.authorRole,
  });
  final int id;
  final String title, description, slug;
  final String? content, image, author, date, status, authorRole;
  final List<String> tags;
  factory Post.fromJson(Map<String, dynamic> j) => Post(
    id: j['id'] as int,
    title: normalizeApiText(j['titulo'] as String),
    description: normalizeApiText((j['descripcion'] ?? '') as String),
    slug: j['slug'] as String,
    content: _nullableText(j['contenido']),
    image: j['imagen'] as String?,
    author: _nullableText(j['autor']),
    date: j['fecha_publicacion']?.toString(),
    tags: _tags(j['tags']),
    status: _nullableText(j['estado']),
    authorRole: _nullableText(j['rol_autor']),
  );
}

String? _nullableText(dynamic value) {
  final text = value as String?;
  return text == null ? null : normalizeApiText(text);
}

List<String> _tags(dynamic value) {
  final raw = _nullableText(value);
  if (raw == null || raw.trim().isEmpty) return const [];
  return raw
      .split(',')
      .map((tag) => tag.trim())
      .where((tag) => tag.isNotEmpty)
      .toList(growable: false);
}

class Artist {
  const Artist({
    required this.id,
    required this.name,
    this.genre,
    this.image,
    this.bio,
    this.albums = const [],
    this.posts = const [],
  });
  final int id;
  final String name;
  final String? genre, image, bio;
  final List<Album> albums;
  final List<Post> posts;
  factory Artist.fromJson(Map<String, dynamic> j) => Artist(
    id: j['id'] as int,
    name: normalizeApiText(j['nombre'] as String),
    genre: _nullableText(j['genero']),
    image: j['imagen'] as String?,
    bio: _nullableText(j['biografia']),
    albums: ((j['albums'] ?? []) as List)
        .map((x) => Album.fromJson(x as Map<String, dynamic>))
        .toList(),
    posts: ((j['posts'] ?? []) as List)
        .map((x) => Post.fromJson(x as Map<String, dynamic>))
        .toList(),
  );
}

class Album {
  const Album({
    required this.id,
    required this.title,
    this.cover,
    this.type,
    this.releaseDate,
  });
  final int id;
  final String title;
  final String? cover, type, releaseDate;
  factory Album.fromJson(Map<String, dynamic> j) => Album(
    id: j['id'] as int,
    title: normalizeApiText(j['titulo'] as String),
    cover: j['portada'] as String?,
    type: _nullableText(j['tipo']),
    releaseDate: j['fecha_lanzamiento']?.toString(),
  );
}

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.price,
    this.category,
    this.brand,
    this.image,
    this.images = const [],
    this.description,
    this.stock,
  });
  final int id;
  final String name;
  final num price;
  final String? category, brand, image, description;
  final List<String> images;
  final int? stock;
  factory Product.fromJson(Map<String, dynamic> j) => Product(
    id: j['id'] as int,
    name: normalizeApiText(j['nombre'] as String),
    price: j['precio'] as num,
    category: _nullableText(j['categoria']),
    brand: _nullableText(j['marca']),
    image: j['imagen'] as String?,
    images: [j['imagen'], j['imagen_2'], j['imagen_3'], j['imagen_4']]
        .whereType<String>()
        .where((image) => image.isNotEmpty)
        .toList(growable: false),
    description: _nullableText(j['descripcion']),
    stock: j['stock'] as int?,
  );
}
