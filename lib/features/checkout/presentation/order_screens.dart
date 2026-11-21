import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/side_b_theme.dart';
import '../../../core/utils/text_formatters.dart';
import '../../../core/widgets/async_state.dart';
import '../../content/presentation/content_providers.dart';
import '../data/checkout_repository.dart';
import 'checkout_providers.dart';
import 'checkout_screen.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key, this.showHistory = false});

  static const _recentLimit = 5;
  final bool showHistory;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: Text(showHistory ? 'Historial' : 'Pedidos')),
    body: ref
        .watch(ordersProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => AsyncErrorView(
            message: 'No pudimos consultar tus pedidos.',
            onRetry: () => ref.invalidate(ordersProvider),
          ),
          data: (items) {
            if (items.isEmpty) {
              return const EmptyView(message: 'Todavía no tienes pedidos.');
            }
            final ordered = [...items]
              ..sort((a, b) {
                final aDate = DateTime.tryParse(a.date);
                final bDate = DateTime.tryParse(b.date);
                final byDate = aDate != null && bDate != null
                    ? bDate.compareTo(aDate)
                    : aDate != null
                    ? -1
                    : bDate != null
                    ? 1
                    : 0;
                return byDate == 0 ? b.id.compareTo(a.id) : byDate;
              });
            final visible = showHistory
                ? ordered
                : ordered.take(_recentLimit).toList();
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(ordersProvider);
                await ref.read(ordersProvider.future);
              },
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                showHistory
                                    ? 'Historial de pedidos.'
                                    : 'Mis pedidos.',
                                style: Theme.of(context).textTheme.displaySmall,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                showHistory
                                    ? 'Todos tus pedidos, del más reciente al más antiguo.'
                                    : 'Consulta el estado de tus pedidos recientes.',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverList.separated(
                          itemCount: visible.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) =>
                              _OrderCard(order: visible[index]),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 52),
                        sliver: SliverToBoxAdapter(
                          child: !showHistory && ordered.length > _recentLimit
                              ? OutlinedButton(
                                  onPressed: () => Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) =>
                                          const OrdersScreen(showHistory: true),
                                    ),
                                  ),
                                  child: const Text('Ver todos los pedidos'),
                                )
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
  );
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final PurchaseOrder order;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final products = order.items.take(2).map((item) => item.name).join(' · ');
    final remaining = order.items.length - 2;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => OrderScreen(orderId: order.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(order.folio, style: text.titleLarge),
                  _OrderStatus(order: order),
                ],
              ),
              if (order.date.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(formatSpanishDate(order.date), style: text.bodyMedium),
              ],
              if (products.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  remaining > 0 ? '$products y $remaining más' : products,
                  style: text.bodyLarge,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(money(order.total), style: text.titleLarge),
                  ),
                  const Icon(Icons.arrow_forward, size: 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderStatus extends StatelessWidget {
  const _OrderStatus({required this.order});

  final PurchaseOrder order;

  @override
  Widget build(BuildContext context) {
    final color = switch (order.status) {
      'pendiente' => Theme.of(context).colorScheme.secondary,
      'cancelado' => Theme.of(context).colorScheme.error,
      'pagado' || 'entregado' =>
        Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFFA8C5A3)
            : SideBColors.success,
      _ => Theme.of(context).colorScheme.onSurface,
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          order.statusLabel,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: color, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class OrderScreen extends ConsumerStatefulWidget {
  const OrderScreen({super.key, required this.orderId});
  final int orderId;
  @override
  ConsumerState<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends ConsumerState<OrderScreen>
    with WidgetsBindingObserver {
  static const _channel = MethodChannel('side_b/payment');
  bool _opening = false, _leftForPayment = false, _checkingPayment = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(_confirmPayment);
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'returned' && mounted) {
        _leftForPayment = false;
        await _confirmPayment();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _channel.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _leftForPayment) {
      _leftForPayment = false;
      _confirmPayment();
    }
  }

  void _refresh() {
    ref.invalidate(orderProvider(widget.orderId));
    ref.invalidate(ordersProvider);
    ref.invalidate(cartProvider);
    ref.invalidate(productsProvider);
  }

  Future<void> _confirmPayment() async {
    if (!mounted || _checkingPayment) return;
    setState(() {
      _checkingPayment = true;
      _error = null;
    });
    try {
      await ref.read(checkoutRepositoryProvider).confirmPayment(widget.orderId);
    } catch (error) {
      if (mounted)
        setState(
          () => _error = error is ApiException
              ? error.message
              : 'No pudimos verificar el pago. Puedes volver a intentarlo.',
        );
    } finally {
      if (mounted) {
        setState(() => _checkingPayment = false);
        _refresh();
      }
    }
  }

  Future<void> _pay() async {
    if (_opening || _checkingPayment) return;
    setState(() {
      _opening = true;
      _error = null;
    });
    try {
      final url = await ref
          .read(checkoutRepositoryProvider)
          .paymentUrl(widget.orderId);
      final parsed = Uri.parse(url);
      if (!['http', 'https'].contains(parsed.scheme) ||
          parsed.userInfo.isNotEmpty)
        throw const FormatException('Enlace de pago no válido');
      _leftForPayment = true;
      await _channel.invokeMethod<void>('open', {'url': url});
    } catch (error) {
      _leftForPayment = false;
      if (mounted)
        setState(
          () => _error = error is ApiException
              ? error.message
              : 'No pudimos abrir el pago. Intenta de nuevo.',
        );
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Tu pedido.')),
    body: ref
        .watch(orderProvider(widget.orderId))
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => AsyncErrorView(
            message: 'No pudimos consultar el estado del pedido.',
            onRetry: _refresh,
          ),
          data: (order) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 52),
                children: [
                  Text(
                    order.folio,
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 14),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _OrderStatus(order: order),
                          const SizedBox(height: 12),
                          Text(
                            order.status == 'pendiente'
                                ? 'Tu pedido está listo para pagar.'
                                : order.paid && order.status != 'cancelado'
                                ? 'Tu compra está confirmada.'
                                : 'Estado de tu pedido',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          if (order.date.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(formatSpanishDate(order.date)),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Resumen de compra',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 8),
                          PurchaseSummary(quote: order),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  if (order.status == 'pendiente') ...[
                    const Text(
                      'Abriremos PayPal en tu navegador. Cuando termines, pulsa «Volver a SIDE B»; verificaremos el pago con el servidor.',
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _opening || _checkingPayment ? null : _pay,
                      child: Text(
                        _checkingPayment
                            ? 'VERIFICANDO…'
                            : _opening
                            ? 'ABRIENDO…'
                            : 'PAGAR CON PAYPAL',
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Si cancelas o cierras el navegador, este pedido permanece pendiente y puedes retomarlo aquí.',
                    ),
                  ],
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  TextButton(
                    onPressed: _checkingPayment ? null : _confirmPayment,
                    child: const Text('ACTUALIZAR ESTADO'),
                  ),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const OrdersScreen(),
                      ),
                    ),
                    child: const Text('MIS PEDIDOS'),
                  ),
                ],
              ),
            ),
          ),
        ),
  );
}
