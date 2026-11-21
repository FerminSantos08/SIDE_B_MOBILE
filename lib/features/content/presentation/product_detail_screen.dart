import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/layout/side_b_layout.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/async_state.dart';
import '../../../core/widgets/editorial_components.dart';
import '../data/content_models.dart';
import 'content_providers.dart';
import 'cart_screen.dart';
import 'shop_screen.dart' show ProductCard;
import '../../wishlist/wishlist.dart';

class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({super.key, required this.productId});
  final int productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(productProvider(productId));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tienda'),
        actions: const [CartButton()],
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => AsyncErrorView(
          message: 'No pudimos abrir este producto.',
          onRetry: () => ref.invalidate(productProvider(productId)),
        ),
        data: (product) => _ProductDetail(product: product),
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
    if (mounted) ref.invalidate(cartProvider);
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
      final theme = Theme.of(context);
      final width = constraints.maxWidth;
      final images = product.images.isNotEmpty
          ? product.images
          : [if (product.image case final image?) image];
      final gallery = Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            if (images.length <= 1)
              _cover(context, images.firstOrNull)
            else ...[
              AspectRatio(
                aspectRatio: 1,
                child: PageView.builder(
                  itemCount: images.length,
                  onPageChanged: (index) => setState(() => _imageIndex = index),
                  itemBuilder: (context, index) =>
                      _cover(context, images[index]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Foto ${_imageIndex.clamp(0, images.length - 1) + 1} de ${images.length}',
                  style: theme.textTheme.labelMedium,
                ),
              ),
            ],
          ],
        ),
      );
      final details = Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (product.category case final category?) ...[
                Text(
                  category.toUpperCase(),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Text(product.name, style: theme.textTheme.displaySmall),
              if (product.brand case final brand?) ...[
                const SizedBox(height: 6),
                Text(brand, style: theme.textTheme.bodyMedium),
              ],
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    _price(product.price),
                    style: theme.textTheme.titleLarge,
                  ),
                  _StockLabel(stock: product.stock),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _busy || (product.stock ?? 0) <= 0
                          ? null
                          : _addToCart,
                      icon: const Icon(Icons.shopping_cart_outlined, size: 19),
                      label: Text(_busy ? 'Agregando…' : 'Agregar al carrito'),
                    ),
                  ),
                  const SizedBox(width: 6),
                  WishlistButton(productId: product.id),
                ],
              ),
              if (product.description case final description?
                  when description.trim().isNotEmpty) ...[
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 16),
                Text('Descripción', style: theme.textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(description, style: theme.textTheme.bodyLarge),
              ],
            ],
          ),
        ),
      );
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 940),
          child: ListView(
            padding: SideBLayout.pageInsets(width, top: 20, bottom: 56),
            children: [
              if (width >= SideBLayout.expandedBreakpoint)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: gallery),
                    const SizedBox(width: 18),
                    Expanded(child: details),
                  ],
                )
              else ...[
                gallery,
                const SizedBox(height: 16),
                details,
              ],
              _RelatedProducts(product: product),
            ],
          ),
        ),
      );
    },
  );

  Widget _cover(BuildContext context, String? url) => NetworkCover(
    url: url,
    aspectRatio: 1,
    fit: BoxFit.contain,
    backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
  );
}

class _RelatedProducts extends ConsumerWidget {
  const _RelatedProducts({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(productsProvider).value;
    if (catalog == null) return const SizedBox.shrink();

    final category = product.category?.trim().toLowerCase();
    final alternatives = catalog.where((item) => item.id != product.id);
    final related = category == null || category.isEmpty
        ? <Product>[]
        : alternatives
              .where((item) => item.category?.trim().toLowerCase() == category)
              .take(4)
              .toList();
    final items = related.isNotEmpty ? related : alternatives.take(4).toList();
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 20),
          Text(
            related.isEmpty ? 'Más de la tienda' : 'Productos relacionados',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 12.0;
              final columns = constraints.maxWidth >= 600 ? 4 : 2;
              final width =
                  (constraints.maxWidth - gap * (columns - 1)) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final item in items)
                    SizedBox(
                      width: width,
                      child: ProductCard(product: item),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StockLabel extends StatelessWidget {
  const _StockLabel({this.stock});
  final int? stock;
  @override
  Widget build(BuildContext context) {
    final available = (stock ?? 0) > 0;
    final theme = Theme.of(context);
    final color = available
        ? theme.colorScheme.onSurface
        : theme.colorScheme.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: available
            ? theme.colorScheme.surfaceContainerHigh
            : color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        available
            ? (stock == 1 ? '1 disponible' : '$stock disponibles')
            : 'Agotado',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color),
      ),
    );
  }
}

String _price(num value) => '\$${value.toStringAsFixed(2)} MXN';
