import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/async_state.dart';
import '../../../core/widgets/editorial_components.dart';
import '../data/content_models.dart';
import 'content_providers.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Tu carrito.')),
      body: cart.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => AsyncErrorView(
          message: 'Inicia sesión para ver tu carrito.',
          onRetry: () => ref.invalidate(cartProvider),
        ),
        data: (items) => items.isEmpty
            ? const EmptyView(message: 'Tu carrito está vacío.')
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  ...items.map((item) => _CartItemRow(item: item)),
                  const Divider(height: 36),
                  Text('Total', style: Theme.of(context).textTheme.titleLarge),
                  Text(
                    _money(
                      items.fold<num>(
                        0,
                        (sum, item) => sum + item.product.price * item.quantity,
                      ),
                    ),
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                ],
              ),
      ),
    );
  }
}

class CartButton extends ConsumerWidget {
  const CartButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      onPressed: () =>
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const CartScreen())),
      tooltip: 'Mi carrito',
      icon: const Icon(Icons.shopping_bag_outlined),
    );
  }
}

class _CartItemRow extends ConsumerWidget {
  const _CartItemRow({required this.item});
  final CartItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Row(
      children: [
        SizedBox(
          width: 78,
          child: NetworkCover(url: item.product.image, aspectRatio: 1),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.product.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                _money(item.product.price),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: item.quantity > 1
                        ? () => _setQuantity(ref, item.quantity - 1)
                        : null,
                    icon: const Icon(Icons.remove),
                  ),
                  Text('${item.quantity}'),
                  IconButton(
                    onPressed: () => _setQuantity(ref, item.quantity + 1),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () async {
            await ref
                .read(contentRepositoryProvider)
                .removeCartItem(item.product.id);
            ref.invalidate(cartProvider);
          },
          icon: const Icon(Icons.close),
        ),
      ],
    ),
  );

  Future<void> _setQuantity(WidgetRef ref, int quantity) async {
    await ref
        .read(contentRepositoryProvider)
        .updateCartItem(item.product.id, quantity);
    ref.invalidate(cartProvider);
  }
}

String _money(num value) => '\$${value.toStringAsFixed(0)} MXN';
