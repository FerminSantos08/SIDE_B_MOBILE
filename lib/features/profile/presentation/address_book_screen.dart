import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/widgets/async_state.dart';
import '../../checkout/data/checkout_repository.dart';
import '../../checkout/presentation/checkout_providers.dart';
import '../data/profile_repository.dart';

class AddressBookScreen extends ConsumerStatefulWidget {
  const AddressBookScreen({super.key});
  @override
  ConsumerState<AddressBookScreen> createState() => _AddressBookScreenState();
}

class _AddressBookScreenState extends ConsumerState<AddressBookScreen> {
  bool _busy = false;
  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      ref.invalidate(profileAddressesProvider);
      ref.invalidate(deliveryAddressesProvider);
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is ApiException
                  ? error.message
                  : 'No pudimos actualizar la dirección.',
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove(DeliveryAddress item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar dirección?'),
        content: Text(
          '${item.label}\n${item.address}\n\nLos pedidos que ya creaste conservarán su dirección.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ELIMINAR'),
          ),
        ],
      ),
    );
    if (mounted && confirmed == true)
      await _run(
        () => ref.read(profileRepositoryProvider).removeAddress(item.id),
      );
  }

  void _edit([DeliveryAddress? item]) => Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => AddressEditorScreen(address: item)),
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Mis direcciones.')),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _busy ? null : () => _edit(),
      icon: const Icon(Icons.add),
      label: const Text('AÑADIR DIRECCIÓN'),
    ),
    body: ref
        .watch(profileAddressesProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => AsyncErrorView(
            message: 'No pudimos cargar tus direcciones.',
            onRetry: () => ref.invalidate(profileAddressesProvider),
          ),
          data: (items) => items.isEmpty
              ? const EmptyView(
                  message: 'Aún no tienes direcciones. Añade la primera para tus compras.',
                )
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 620),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 110),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.isDefault
                                      ? '${item.label} · Principal'
                                      : item.label,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  item.address,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    if (!item.isDefault)
                                      OutlinedButton(
                                        onPressed: _busy
                                            ? null
                                            : () => _run(
                                                () => ref
                                                    .read(
                                                      profileRepositoryProvider,
                                                    )
                                                    .setDefault(item.id),
                                              ),
                                        child: const Text(
                                          'USAR COMO PRINCIPAL',
                                        ),
                                      ),
                                    IconButton(
                                      tooltip: 'Editar ${item.label}',
                                      onPressed: _busy
                                          ? null
                                          : () => _edit(item),
                                      icon: const Icon(Icons.edit_outlined),
                                    ),
                                    IconButton(
                                      tooltip: 'Eliminar ${item.label}',
                                      onPressed: _busy
                                          ? null
                                          : () => _remove(item),
                                      icon: const Icon(Icons.delete_outline),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
        ),
  );
}

class AddressEditorScreen extends ConsumerStatefulWidget {
  const AddressEditorScreen({super.key, this.address});
  final DeliveryAddress? address;
  @override
  ConsumerState<AddressEditorScreen> createState() =>
      _AddressEditorScreenState();
}

class _AddressEditorScreenState extends ConsumerState<AddressEditorScreen> {
  final _form = GlobalKey<FormState>();
  late final _label = TextEditingController(
    text: widget.address?.label ?? 'Casa',
  );
  late final _address = TextEditingController(
    text: widget.address?.address ?? '',
  );
  late bool _default = widget.address?.isDefault ?? false;
  bool _busy = false;
  String? _error;
  @override
  void dispose() {
    _label.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(profileRepositoryProvider)
          .saveAddress(
            id: widget.address?.id,
            label: _label.text,
            address: _address.text,
            isDefault: _default,
          );
      if (!mounted) return;
      ref.invalidate(profileAddressesProvider);
      ref.invalidate(deliveryAddressesProvider);
      Navigator.of(context).pop();
    } catch (error) {
      if (mounted)
        setState(
          () => _error = error is ApiException ? error.message : 'No pudimos guardar la dirección. Conservamos lo que escribiste.',
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.address == null ? 'Nueva dirección.' : 'Editar dirección.',
      ),
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 52),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _label,
                        enabled: !_busy,
                        maxLength: 60,
                        decoration: const InputDecoration(
                          labelText: 'Etiqueta',
                          hintText: 'Casa, trabajo…',
                        ),
                        validator: (value) => (value ?? '').trim().isEmpty
                            ? 'Escribe una etiqueta.'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _address,
                        enabled: !_busy,
                        minLines: 4,
                        maxLines: 6,
                        maxLength: 255,
                        autofillHints: const [AutofillHints.fullStreetAddress],
                        decoration: const InputDecoration(
                          labelText: 'Dirección completa',
                          hintText: 'Calle, número, colonia, municipio, estado y código postal',
                          alignLabelWithHint: true,
                        ),
                        validator: (value) => (value ?? '').trim().isEmpty
                            ? 'Escribe la dirección.'
                            : null,
                      ),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _default,
                        onChanged: _busy
                            ? null
                            : (value) => setState(() => _default = value!),
                        title: const Text('Usar como principal'),
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: _busy ? null : _save,
                        child: Text(_busy ? 'GUARDANDO…' : 'GUARDAR DIRECCIÓN'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
