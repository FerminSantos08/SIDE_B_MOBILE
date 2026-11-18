import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/layout/side_b_layout.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/side_b_theme.dart';
import '../../../core/widgets/async_state.dart';
import '../../../core/widgets/editorial_components.dart';
import '../data/content_models.dart';
import 'content_providers.dart';
import '../../wishlist/wishlist.dart';

class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({super.key, required this.productId});
  final int productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(productProvider(productId));
    return Scaffold(
      body: SafeArea(
        child: state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => AsyncErrorView(
            message: 'No pudimos abrir este producto.',
            onRetry: () => ref.invalidate(productProvider(productId)),
          ),
          data: (product) => _ProductDetail(product: product),
        ),
      ),
    );
  }
}

class _ProductDetail extends ConsumerStatefulWidget {
  const _ProductDetail({required this.product});
  final Product product;

  @override
  ConsumerState<_ProductDetail> createState() => _ProductDetailState();
}

class _ProductDetailState extends ConsumerState<_ProductDetail> {
  var _busy = false;
  int _imageIndex = 0;

  Future<void> _addToCart() async {
    await _runAction(
      () => ref.read(contentRepositoryProvider).addToCart(widget.product.id),
      'Agregado al carrito',
    );
    ref.invalidate(cartProvider);
  }

  Future<void> _runAction(
    Future<void> Function() action,
    String message,
  ) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } on ApiException catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final product = widget.product;
      final padding = SideBLayout.horizontalPadding(constraints.maxWidth);
      final images = product.images.isEmpty && product.image != null
          ? [product.image!]
          : product.images;
      return CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: SideBColors.ivory,
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
            ),
            title: const Text('SIDE B'),
          ),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 780),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(padding, 20, padding, 48),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (images.length <= 1)
                        NetworkCover(
                          url: product.image,
                          aspectRatio: 1,
                          fit: BoxFit.contain,
                        )
                      else
                        Column(
                          children: [
                            AspectRatio(
                              aspectRatio: 1,
                              child: PageView(
                                onPageChanged: (index) =>
                                    setState(() => _imageIndex = index),
                                children: images
                                    .map(
                                      (image) => NetworkCover(
                                        url: image,
                                        aspectRatio: 1,
                                        fit: BoxFit.contain,
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '${_imageIndex + 1} / ${images.length}',
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                          ],
                        ),
                      const SizedBox(height: 25),
                      Text(
                        (product.category ?? 'SIDE B').toUpperCase(),
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: SideBColors.accent),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        product.name,
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      if (product.brand != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          product.brand!,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 16,
                        runSpacing: 12,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            _price(product.price),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          _StockLabel(stock: product.stock),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _busy || (product.stock ?? 0) <= 0
                                  ? null
                                  : _addToCart,
                              icon: const Icon(Icons.shopping_bag_outlined),
                              label: Text(
                                _busy ? 'PROCESANDO...' : 'AGREGAR AL CARRITO',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          WishlistButton(productId: product.id),
                        ],
                      ),
                      if (product.description != null) ...[
                        const SizedBox(height: 28),
                        Text(
                          product.description!,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

class _StockLabel extends StatelessWidget {
  const _StockLabel({this.stock});
  final int? stock;
  @override
  Widget build(BuildContext context) {
    final available = (stock ?? 0) > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: available ? SideBColors.olive : SideBColors.error,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        available ? 'DISPONIBLE · $stock' : 'AGOTADO',
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(color: SideBColors.ivory),
      ),
    );
  }
}

String _price(num value) => '\$${value.toStringAsFixed(0)} MXN';
