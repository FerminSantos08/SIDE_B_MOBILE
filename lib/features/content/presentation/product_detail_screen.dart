import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/layout/side_b_layout.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/side_b_theme.dart';
import '../../../core/widgets/async_state.dart';
import '../../../core/widgets/editorial_components.dart';
import '../data/content_models.dart';
import 'content_providers.dart';

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
  var _saved = false;
  var _busy = false;

  Future<void> _addToCart() async {
    await _runAction(() => ref.read(contentRepositoryProvider).addToCart(widget.product.id), 'Agregado al carrito');
  }

  Future<void> _toggleWishlist() async {
    await _runAction(
      () => _saved
          ? ref.read(contentRepositoryProvider).removeFromWishlist(widget.product.id)
          : ref.read(contentRepositoryProvider).addToWishlist(widget.product.id),
      _saved ? 'Eliminado de lista de deseos' : 'Guardado en lista de deseos',
      toggleSaved: true,
    );
  }

  Future<void> _runAction(Future<void> Function() action, String message, {bool toggleSaved = false}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) {
        if (toggleSaved) setState(() => _saved = !_saved);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } on ApiException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final product = widget.product;
      final padding = SideBLayout.horizontalPadding(constraints.maxWidth);
      final images = product.images.isEmpty && product.image != null ? [product.image!] : product.images;
      return CustomScrollView(slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: SideBColors.ivory,
          leading: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back)),
          title: const Text('SIDE B'),
        ),
        SliverToBoxAdapter(child: Center(child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 780),
          child: Padding(
            padding: EdgeInsets.fromLTRB(padding, 20, padding, 48),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (images.length <= 1)
                NetworkCover(url: product.image, aspectRatio: 1)
              else
                SizedBox(height: 360, child: PageView(children: images.map((image) => NetworkCover(url: image, aspectRatio: 1)).toList())),
              const SizedBox(height: 25),
              Text((product.category ?? 'SIDE B').toUpperCase(), style: Theme.of(context).textTheme.labelMedium?.copyWith(color: SideBColors.accent)),
              const SizedBox(height: 8),
              Text(product.name, style: Theme.of(context).textTheme.displaySmall),
              if (product.brand != null) ...[const SizedBox(height: 8), Text(product.brand!, style: Theme.of(context).textTheme.titleLarge)],
              const SizedBox(height: 20),
              Row(children: [Text(_price(product.price), style: Theme.of(context).textTheme.titleLarge), const Spacer(), _StockLabel(stock: product.stock)]),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: FilledButton.icon(
                  onPressed: _busy || (product.stock ?? 0) <= 0 ? null : _addToCart,
                  icon: const Icon(Icons.shopping_bag_outlined),
                  label: Text(_busy ? 'PROCESANDO...' : 'AGREGAR AL CARRITO'),
                )),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: _busy ? null : _toggleWishlist,
                  tooltip: _saved ? 'Quitar de lista de deseos' : 'Guardar en lista de deseos',
                  icon: Icon(_saved ? Icons.favorite : Icons.favorite_border),
                ),
              ]),
              if (product.description != null) ...[const SizedBox(height: 28), Text(product.description!, style: Theme.of(context).textTheme.bodyLarge)],
            ]),
          ),
        ))),
      ]);
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
      decoration: BoxDecoration(color: available ? SideBColors.olive : SideBColors.error, borderRadius: BorderRadius.circular(20)),
      child: Text(available ? 'DISPONIBLE · $stock' : 'AGOTADO', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: SideBColors.ivory)),
    );
  }
}

String _price(num value) => '\$${value.toStringAsFixed(0)} MXN';
