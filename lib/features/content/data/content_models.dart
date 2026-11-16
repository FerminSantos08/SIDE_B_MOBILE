import '../../../core/utils/text_formatters.dart';
import '../../../core/config/api_config.dart';

class PostComment {
  const PostComment({
    required this.id,
    required this.text,
    required this.author,
    required this.date,
    this.avatarUrl,
  });

  final int id;
  final String text, author;
  final String? date;
  final String? avatarUrl;

  factory PostComment.fromJson(Map<String, dynamic> json) => PostComment(
    id: json['id'] as int,
    text: normalizeApiText(json['comentario'] as String),
    author: normalizeApiText(json['autor'] as String),
    date: json['fecha']?.toString(),
    avatarUrl: ApiConfig.mediaUrl(json['avatar_url'] as String?),
  );
}

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
    this.commentsCount = 0,
    this.reactionsCount = 0,
  });
  final int id;
  final String title, description, slug;
  final String? content, image, author, date, status, authorRole;
  final List<String> tags;
  final int commentsCount;
  final int reactionsCount;
  factory Post.fromJson(Map<String, dynamic> j) => Post(
    id: j['id'] as int,
    title: normalizeApiText(j['titulo'] as String),
    description: normalizeApiText((j['descripcion'] ?? '') as String),
    slug: j['slug'] as String,
    content: _nullableText(j['contenido']),
    image: ApiConfig.mediaUrl(j['imagen'] as String?),
    author: _nullableText(j['autor']),
    date: j['fecha_publicacion']?.toString(),
    tags: _tags(j['tags']),
    status: _nullableText(j['estado']),
    authorRole: _nullableText(j['rol_autor']),
    commentsCount: (j['comments_count'] as num?)?.toInt() ?? 0,
    reactionsCount: (j['reactions_count'] as num?)?.toInt() ?? 0,
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
    image: ApiConfig.mediaUrl(j['imagen'] as String?),
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
    cover: ApiConfig.mediaUrl(j['portada'] as String?),
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
    image: ApiConfig.mediaUrl(j['imagen'] as String?),
    images: [j['imagen'], j['imagen_2'], j['imagen_3'], j['imagen_4']]
        .whereType<String>()
        .where((image) => image.isNotEmpty)
        .map((image) => ApiConfig.mediaUrl(image)!)
        .toList(growable: false),
    description: _nullableText(j['descripcion']),
    stock: j['stock'] as int?,
  );
}

class CartItem {
  const CartItem({required this.product, required this.quantity});
  final Product product;
  final int quantity;

  factory CartItem.fromJson(Map<String, dynamic> json) {
    final nestedProduct = json['producto'] ?? json['product'];
    final productJson = nestedProduct is Map<String, dynamic>
        ? nestedProduct
        : json;
    final rawQuantity = json['cantidad'] ?? json['quantity'] ?? 1;
    return CartItem(
      product: Product.fromJson(productJson),
      quantity: rawQuantity is num ? rawQuantity.toInt() : 1,
    );
  }
}
