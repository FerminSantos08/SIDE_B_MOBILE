import 'dart:math';

import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';

int moneyCents(dynamic value) =>
    ((num.tryParse(value.toString()) ?? 0) * 100).round();
String money(int cents) => '\$${(cents / 100).toStringAsFixed(2)} MXN';

String checkoutRequestId() {
  final random = Random.secure();
  final bytes = List.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 15) | 64;
  bytes[8] = (bytes[8] & 63) | 128;
  final hex = bytes
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

class DeliveryAddress {
  const DeliveryAddress({
    required this.id,
    required this.label,
    required this.address,
    required this.isDefault,
  });
  final int id;
  final String label, address;
  final bool isDefault;
  factory DeliveryAddress.fromJson(Map<String, dynamic> json) =>
      DeliveryAddress(
        id: json['id'] as int,
        label: json['label'] as String,
        address: json['address'] as String,
        isDefault: json['is_default'] == true || json['is_default'] == 1,
      );
}

class PurchaseItem {
  PurchaseItem.fromJson(Map<String, dynamic> json)
    : name = json['name'] as String,
      quantity = json['quantity'] as int,
      price = moneyCents(json['price']),
      image = ApiConfig.mediaUrl(json['image'] as String?);
  final String name;
  final int quantity, price;
  final String? image;
  int get total => quantity * price;
}

class PurchaseQuote {
  PurchaseQuote.fromJson(Map<String, dynamic> json)
    : address = json['address'] as String,
      subtotal = moneyCents(json['subtotal']),
      shipping = moneyCents(json['shipping']),
      discount = moneyCents(json['discount'] ?? 0),
      tax = moneyCents(json['tax'] ?? 0),
      total = moneyCents(json['total']),
      items = (json['items'] as List)
          .map((item) => PurchaseItem.fromJson(item as Map<String, dynamic>))
          .toList();
  final String address;
  final int subtotal, shipping, discount, tax, total;
  final List<PurchaseItem> items;
}

class PurchaseOrder extends PurchaseQuote {
  PurchaseOrder.fromJson(Map<String, dynamic> json)
    : id = json['id'] as int,
      status = json['status'] as String,
      paid = json['paid'] == true,
      date = json['date'] as String,
      super.fromJson(json);
  final int id;
  final String status, date;
  final bool paid;
  String get folio => 'SB-${id.toString().padLeft(6, '0')}';
  String get statusLabel => switch (status) {
    'pendiente' => 'Pago pendiente',
    'pagado' => 'Pago confirmado',
    'preparando' => 'Preparando pedido',
    'enviado' => 'En camino',
    'entregado' => 'Entregado',
    'cancelado' => 'Cancelado',
    _ => status,
  };
}

class CheckoutRepository {
  CheckoutRepository(this.api);
  final ApiClient api;
  Future<List<DeliveryAddress>> addresses() async {
    final data = await api.get('/checkout/addresses') as Map<String, dynamic>;
    return (data['addresses'] as List)
        .map((row) => DeliveryAddress.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Map<String, dynamic> delivery({int? addressId, String? address}) =>
      addressId != null
      ? {'address_id': addressId}
      : {'address': address?.trim()};
  Future<PurchaseQuote> quote({int? addressId, String? address}) async =>
      PurchaseQuote.fromJson(
        await api.post(
          '/checkout/quote',
          data: delivery(addressId: addressId, address: address),
        ) as Map<String, dynamic>,
      );
  Future<PurchaseOrder> create({
    required String requestId,
    required int expectedTotal,
    int? addressId,
    String? address,
  }) async => PurchaseOrder.fromJson(
    await api.post(
      '/orders',
      data: {
        ...delivery(addressId: addressId, address: address),
        'request_id': requestId,
        'expected_total': (expectedTotal / 100).toStringAsFixed(2),
      },
    ) as Map<String, dynamic>,
  );
  Future<List<PurchaseOrder>> orders() async {
    final data = await api.get('/orders') as Map<String, dynamic>;
    return (data['orders'] as List)
        .map((row) => PurchaseOrder.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<PurchaseOrder> order(int id) async => PurchaseOrder.fromJson(
    await api.get('/orders/$id') as Map<String, dynamic>,
  );
  Future<PurchaseOrder> confirmPayment(int id) async => PurchaseOrder.fromJson(
    await api.post('/orders/$id/payment-confirm') as Map<String, dynamic>,
  );
  Future<String> paymentUrl(int id) async {
    final data =
        await api.post('/orders/$id/payment-session') as Map<String, dynamic>;
    return data['url'] as String;
  }
}
