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
  const OrdersScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('Mis pedidos.')),
    body: ref
        .watch(ordersProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => AsyncErrorView(
            message: 'No pudimos consultar tus pedidos.',
            onRetry: () => ref.invalidate(ordersProvider),
          ),
          data: (items) => items.isEmpty
              ? const EmptyView(message: 'Todavía no tienes pedidos.')
              : RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(ordersProvider);
                    await ref.read(ordersProvider.future);
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const Divider(height: 28),
                    itemBuilder: (context, index) {
                      final order = items[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          order.folio,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        subtitle: Text(
                          '${order.statusLabel}\n${formatSpanishDate(order.date)} · ${money(order.total)}',
                        ),
                        isThreeLine: true,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => OrderScreen(orderId: order.id),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
  );
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
                padding: const EdgeInsets.all(24),
                children: [
                  Icon(
                    order.paid
                        ? Icons.check_circle_outline
                        : Icons.receipt_long_outlined,
                    color: SideBColors.accent,
                    size: 44,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    order.paid
                        ? 'Tu compra está confirmada.'
                        : order.status == 'pendiente'
                        ? 'Tu pedido está listo para pagar.'
                        : order.statusLabel,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  Text('${order.folio} · ${order.statusLabel}'),
                  const SizedBox(height: 24),
                  PurchaseSummary(quote: order),
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
