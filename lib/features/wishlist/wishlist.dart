import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../core/widgets/async_state.dart';
import '../../core/widgets/editorial_components.dart';
import '../auth/auth.dart';
import '../content/data/content_models.dart';
import '../content/presentation/content_providers.dart';
import '../content/presentation/product_detail_screen.dart';
import '../profile/presentation/profile_screen.dart';

class ProductWishlist {
  ProductWishlist({required this.products, required this.ids});
  final List<Product> products;
  final Set<int> ids;
  factory ProductWishlist.fromJson(Map<String, dynamic> data) =>
      ProductWishlist(
        products: (data['items'] as List)
            .map((row) => Product.fromJson(row as Map<String, dynamic>))
            .toList(),
        ids: (data['saved_ids'] as List).cast<int>().toSet(),
      );
}

final wishlistProvider = FutureProvider.autoDispose<ProductWishlist>((
  ref,
) async {
  final auth = ref.watch(authProvider);
  final api = ref.watch(apiClientProvider);
  if (auth.asData?.value == null) return ProductWishlist(products: [], ids: {});
  return ProductWishlist.fromJson(
    await api.get('/wishlist') as Map<String, dynamic>,
  );
});

class WishlistButton extends ConsumerStatefulWidget {
  const WishlistButton({super.key, required this.productId});
  final int productId;
  @override
  ConsumerState<WishlistButton> createState() => _WishlistButtonState();
}

class _WishlistButtonState extends ConsumerState<WishlistButton> {
  bool _busy = false;
  Future<void> _toggle() async {
    if (_busy) return;
    setState(() => _busy = true);
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
      if (ref.read(wishlistProvider).hasError) ref.invalidate(wishlistProvider);
      final list = await ref.read(wishlistProvider.future);
      if (!mounted) return;
      final repository = ref.read(contentRepositoryProvider);
      if (list.ids.contains(widget.productId)) {
        await repository.removeFromWishlist(widget.productId);
      } else {
        await repository.addToWishlist(widget.productId);
      }
      if (mounted) ref.invalidate(wishlistProvider);
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is ApiException
                  ? error.message
                  : 'No pudimos actualizar la lista de deseos.',
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final saved =
        ref
            .watch(wishlistProvider)
            .asData
            ?.value
            .ids
            .contains(widget.productId) ??
        false;
    return IconButton(
      onPressed: _busy ? null : _toggle,
      tooltip: saved
          ? 'Quitar de lista de deseos'
          : 'Guardar en lista de deseos',
      icon: Icon(saved ? Icons.favorite : Icons.favorite_border),
    );
  }
}

class WishlistScreen extends ConsumerStatefulWidget {
  const WishlistScreen({super.key});
  @override
  ConsumerState<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends ConsumerState<WishlistScreen> {
  final _busy = <int>{};
  Future<void> _cart(Product product) async => _run(product.id, () async {
    await ref.read(contentRepositoryProvider).addToCart(product.id);
    if (mounted) {
      ref.invalidate(cartProvider);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Agregado al carrito.')));
    }
  });
  Future<void> _run(int id, Future<void> Function() action) async {
    if (_busy.contains(id)) return;
    setState(() => _busy.add(id));
    try {
      await action();
      if (mounted) ref.invalidate(wishlistProvider);
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is ApiException
                  ? error.message
                  : 'No pudimos completar la acción.',
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => _busy.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Lista de deseos.')),
      body: user.isLoading
          ? const Center(child: CircularProgressIndicator())
          : user.asData?.value == null
          ? Center(
              child: FilledButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AuthScreen(register: false),
                  ),
                ),
                child: const Text('INICIAR SESIÓN'),
              ),
            )
          : ref
                .watch(wishlistProvider)
                .when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, _) => AsyncErrorView(
                    message: 'No pudimos cargar tu lista de deseos.',
                    onRetry: () => ref.invalidate(wishlistProvider),
                  ),
                  data: (list) => list.products.isEmpty
                      ? const EmptyView(
                          message: 'Tu lista de deseos está vacía. Guarda productos con el corazón.',
                        )
                      : RefreshIndicator(
                          onRefresh: () async {
                            ref.invalidate(wishlistProvider);
                            await ref.read(wishlistProvider.future);
                          },
                          child: ListView.separated(
                            padding: const EdgeInsets.all(20),
                            itemCount: list.products.length,
                            separatorBuilder: (_, _) =>
                                const Divider(height: 28),
                            itemBuilder: (context, index) {
                              final product = list.products[index];
                              return Column(
                                children: [
                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: SizedBox(
                                      width: 72,
                                      height: 72,
                                      child: NetworkCover(
                                        url: product.image,
                                        aspectRatio: 1,
                                      ),
                                    ),
                                    title: Text(product.name),
                                    subtitle: Text(
                                      '\$${product.price.toStringAsFixed(2)} MXN',
                                    ),
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => ProductDetailScreen(
                                          productId: product.id,
                                        ),
                                      ),
                                    ),
                                    trailing: IconButton(
                                      tooltip: 'Quitar ${product.name}',
                                      onPressed: _busy.contains(product.id)
                                          ? null
                                          : () => _run(
                                              product.id,
                                              () => ref
                                                  .read(
                                                    contentRepositoryProvider,
                                                  )
                                                  .removeFromWishlist(
                                                    product.id,
                                                  ),
                                            ),
                                      icon: const Icon(Icons.favorite),
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: OutlinedButton.icon(
                                      onPressed:
                                          _busy.contains(product.id) ||
                                              (product.stock ?? 0) <= 0
                                          ? null
                                          : () => _cart(product),
                                      icon: const Icon(
                                        Icons.shopping_bag_outlined,
                                      ),
                                      label: Text(
                                        (product.stock ?? 0) <= 0
                                            ? 'AGOTADO'
                                            : 'AGREGAR AL CARRITO',
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                ),
    );
  }
}
