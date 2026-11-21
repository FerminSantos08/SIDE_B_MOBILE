import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/widgets/async_state.dart';
import '../../content/presentation/content_providers.dart';
import '../data/checkout_repository.dart';
import 'checkout_providers.dart';
import 'order_screens.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});
  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _address = TextEditingController();
  final _form = GlobalKey<FormState>();
  final _requestId = checkoutRequestId();
  int? _addressId;
  bool _initialized = false, _busy = false;
  PurchaseQuote? _quote;
  String? _error;
  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  Future<void> _review() async {
    if (!_form.currentState!.validate() || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final quote = await ref
          .read(checkoutRepositoryProvider)
          .quote(addressId: _addressId, address: _address.text);
      if (mounted) {
        FocusScope.of(context).unfocus();
        setState(() => _quote = quote);
      }
    } catch (error) {
      if (mounted)
        setState(
          () => _error = error is ApiException
              ? error.message
              : 'No pudimos preparar tu compra. Intenta de nuevo.',
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirm() async {
    if (_busy || _quote == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final order = await ref
          .read(checkoutRepositoryProvider)
          .create(
            requestId: _requestId,
            expectedTotal: _quote!.total,
            addressId: _addressId,
            address: _address.text,
          );
      if (!mounted) return;
      ref.invalidate(cartProvider);
      ref.invalidate(ordersProvider);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => OrderScreen(orderId: order.id)),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error is ApiException
            ? error.message
            : 'No pudimos crear el pedido. Puedes reintentar.';
        if (error is ApiException && error.statusCode == 409) _quote = null;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final addresses = ref.watch(deliveryAddressesProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(_quote == null ? 'Envío.' : 'Revisa tu compra.'),
      ),
      body: addresses.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => AsyncErrorView(
          message: 'No pudimos consultar tus direcciones.',
          onRetry: () => ref.invalidate(deliveryAddressesProvider),
        ),
        data: (items) {
          if (_addressId != null &&
              !items.any((item) => item.id == _addressId)) {
            _addressId = null;
            _quote = null;
          }
          if (!_initialized) {
            _initialized = true;
            final preferred = items.where((item) => item.isDefault);
            _addressId = preferred.isEmpty ? null : preferred.first.id;
          }
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    'SIDE B / TU COMPRA',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 16),
                  if (_quote == null)
                    Form(
                      key: _form,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '¿Dónde lo enviamos?',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<int>(
                            initialValue: _addressId ?? 0,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Dirección de envío',
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: 0,
                                child: Text('Usar otra dirección'),
                              ),
                              ...items.map(
                                (item) => DropdownMenuItem(
                                  value: item.id,
                                  child: Text(
                                    item.label,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                            onChanged: _busy
                                ? null
                                : (value) => setState(
                                    () =>
                                        _addressId = value == 0 ? null : value,
                                  ),
                          ),
                          const SizedBox(height: 16),
                          if (_addressId != null)
                            Text(
                              items
                                  .firstWhere((item) => item.id == _addressId)
                                  .address,
                            )
                          else
                            TextFormField(
                              controller: _address,
                              minLines: 3,
                              maxLines: 5,
                              maxLength: 255,
                              enabled: !_busy,
                              autofillHints: const [
                                AutofillHints.fullStreetAddress,
                              ],
                              decoration: const InputDecoration(
                                labelText: 'Dirección completa',
                                hintText: 'Calle, número, colonia, municipio, estado y código postal',
                                alignLabelWithHint: true,
                              ),
                              validator: (value) =>
                                  _addressId == null &&
                                      (value ?? '').trim().isEmpty
                                  ? 'Escribe la dirección de envío.'
                                  : null,
                            ),
                          const SizedBox(height: 16),
                          const Text(
                            'El resumen incluirá el costo de envío antes de continuar al pago.',
                          ),
                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: _busy ? null : _review,
                            child: Text(
                              _busy ? 'CONSULTANDO…' : 'REVISAR COMPRA',
                            ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    Text(
                      'Tu pedido, antes de pagar.',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 20),
                    PurchaseSummary(quote: _quote!),
                    const SizedBox(height: 24),
                    const Text(
                      'El pago se realiza con PayPal. Si lo interrumpes, podrás retomarlo desde Mis pedidos.',
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _busy ? null : _confirm,
                      child: Text(
                        _busy ? 'CREANDO PEDIDO…' : 'CREAR PEDIDO Y CONTINUAR',
                      ),
                    ),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() {
                              _quote = null;
                              _error = null;
                            }),
                      child: const Text('CAMBIAR DIRECCIÓN'),
                    ),
                  ],
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class PurchaseSummary extends StatelessWidget {
  const PurchaseSummary({super.key, required this.quote});
  final PurchaseQuote quote;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final item in quote.items)
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(item.name),
          subtitle: Text('${item.quantity} × ${money(item.price)}'),
          trailing: Text(money(item.total)),
        ),
      const Divider(height: 32),
      _total('Subtotal', quote.subtotal),
      _total('Envío', quote.shipping),
      if (quote.discount != 0) _total('Descuento', -quote.discount),
      if (quote.tax != 0) _total('Impuestos', quote.tax),
      const SizedBox(height: 8),
      _total('Total', quote.total),
      const SizedBox(height: 24),
      Text(
        'ENTREGA',
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(color: Theme.of(context).colorScheme.secondary),
      ),
      const SizedBox(height: 8),
      Text(quote.address),
    ],
  );
  Widget _total(String label, int value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Text(money(value), style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    ),
  );
}
