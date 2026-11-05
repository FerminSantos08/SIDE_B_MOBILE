import '../../../core/network/api_client.dart';
import 'content_models.dart';

class ContentRepository {
  ContentRepository(this._api);
  final ApiClient _api;
  Future<List<Post>> posts() async {
    final j = await _api.get('/posts') as Map<String, dynamic>;
    return (j['posts'] as List)
        .map((x) => Post.fromJson(x as Map<String, dynamic>))
        .toList();
  }

  Future<Post> post(int id) async {
    final j = await _api.get('/posts/$id') as Map<String, dynamic>;
    return Post.fromJson(j['post'] as Map<String, dynamic>);
  }

  Future<List<Artist>> artists() async {
    final j = await _api.get('/artists') as Map<String, dynamic>;
    return (j['artists'] as List)
        .map((x) => Artist.fromJson(x as Map<String, dynamic>))
        .toList();
  }

  Future<Artist> artist(int id) async =>
      Artist.fromJson(await _api.get('/artists/$id') as Map<String, dynamic>);
  Future<List<Product>> products() async {
    final j = await _api.get('/products') as Map<String, dynamic>;
    return (j['products'] as List)
        .map((x) => Product.fromJson(x as Map<String, dynamic>))
        .toList();
  }

  Future<Product> product(int id) async =>
      Product.fromJson(await _api.get('/products/$id') as Map<String, dynamic>);

  Future<void> addToCart(int productId) =>
      _api.post('/cart/items', data: {'product_id': productId});

  Future<void> addToWishlist(int productId) =>
      _api.post('/wishlist/items', data: {'product_id': productId});

  Future<void> removeFromWishlist(int productId) =>
      _api.delete('/wishlist/items/$productId');
}
