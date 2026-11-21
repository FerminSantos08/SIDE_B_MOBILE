import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/async_state.dart';
import '../../../core/theme/side_b_theme.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/editorial_components.dart';
import '../data/content_models.dart';
import 'content_providers.dart';
import '../../checkout/presentation/checkout_screen.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Carrito')),
      body: cart.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AsyncErrorView(
          message: error is ApiException && error.statusCode == 401
              ? 'Inicia sesión para ver tu carrito.'
              : 'No pudimos cargar tu carrito. Revisa tu conexión e inténtalo de nuevo.',
          onRetry: () async {
            if (error is ApiException && error.statusCode == 401) {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AuthScreen(register: false),
                ),
              );
            }
            if (context.mounted) ref.invalidate(cartProvider);
          },
        ),
        data: (items) => items.isEmpty
            ? const EmptyView(message: 'Tu carrito está vacío.')
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 52),
                children: [
                  Text(
                    'Tu carrito.',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 20),
                  ...items.map(
                    (item) => _CartItemRow(
                      key: ValueKey(item.product.id),
                      item: item,
                    ),
                  ),
                  Card(
                    color: SideBColors.graphite,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Resumen del pedido',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(color: SideBColors.paper),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            alignment: WrapAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Subtotal',
                                style: TextStyle(color: SideBColors.ivory),
                              ),
                              Text(
                                _money(
                                  items.fold<num>(
                                    0,
                                    (sum, item) =>
                                        sum +
                                        item.product.price * item.quantity,
                                  ),
                                ),
                                style: const TextStyle(
                                  color: SideBColors.paper,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'El envío se calcula en el siguiente paso.',
                            style: TextStyle(color: SideBColors.ivory),
                          ),
                          const SizedBox(height: 20),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: SideBColors.paper,
                              foregroundColor: SideBColors.graphite,
                            ),
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const CheckoutScreen(),
                              ),
                            ),
                            child: const Text('CONTINUAR CON LA COMPRA'),
                          ),
                        ],
                      ),
                    ),
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
      icon: const Icon(Icons.shopping_cart_outlined, size: 20),
    );
  }
}

class _CartItemRow extends ConsumerStatefulWidget {
  const _CartItemRow({super.key, required this.item});
  final CartItem item;
  @override
  ConsumerState<_CartItemRow> createState() => _CartItemRowState();
}

class _CartItemRowState extends ConsumerState<_CartItemRow> {
  bool _busy = false;
  CartItem get item => widget.item;

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) ref.invalidate(cartProvider);
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is ApiException
                  ? error.message
                  : 'No pudimos actualizar el carrito.',
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            SizedBox(
              width: 78,
              child: NetworkCover(
                url: item.product.image,
                aspectRatio: 1,
                fit: BoxFit.contain,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              ),
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
                    '${_money(item.product.price)} por unidad',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (item.quantity > 1)
                    Text(
                      'Total: ${_money(item.product.price * item.quantity)}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      IconButton(
                        tooltip: 'Reducir cantidad',
                        onPressed: !_busy && item.quantity > 1
                            ? () => _setQuantity(item.quantity - 1)
                            : null,
                        icon: const Icon(Icons.remove),
                      ),
                      Text('${item.quantity}'),
                      IconButton(
                        tooltip: 'Aumentar cantidad',
                        onPressed:
                            _busy || item.quantity >= (item.product.stock ?? 0)
                            ? null
                            : () => _setQuantity(item.quantity + 1),
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Quitar del carrito',
              onPressed: _busy
                  ? null
                  : () => _run(
                      () => ref
                          .read(contentRepositoryProvider)
                          .removeCartItem(item.product.id),
                    ),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _setQuantity(int quantity) => _run(
    () => ref
        .read(contentRepositoryProvider)
        .updateCartItem(item.product.id, quantity),
  );
}

String _money(num value) => '\$${value.toStringAsFixed(2)} MXN';
