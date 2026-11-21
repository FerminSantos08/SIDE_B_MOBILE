import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/layout/side_b_layout.dart';
import '../../../core/widgets/async_state.dart';
import '../../../core/widgets/editorial_components.dart';
import '../../../core/widgets/olive_shimmer.dart';
import '../data/content_models.dart';
import 'cart_screen.dart';
import 'content_providers.dart';
import 'product_detail_screen.dart';

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  String? _category;

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsProvider);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= SideBLayout.expandedBreakpoint ? 3 : 2;
        final padding = SideBLayout.horizontalPadding(width);
        final gutter =
            padding +
            ((width - SideBLayout.maxContentWidth) / 2).clamp(
              0.0,
              double.infinity,
            );
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(productsProvider);
            await ref.read(productsProvider.future);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(
                child: EditorialHeader(
                  eyebrow: 'Objetos y ediciones',
                  title: 'La tienda',
                  subtitle: 'del otro lado.',
                  trailing: CartButton(),
                  description:
                      'Música y piezas seleccionadas para llevar contigo.',
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(gutter, 0, gutter, 8),
                  child: Text(
                    'Catálogo',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
              ),
              products.when(
                loading: () => SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: gutter),
                  sliver: const SliverToBoxAdapter(
                    child: OliveShimmer(child: _ProductSkeleton()),
                  ),
                ),
                error: (_, _) => SliverFillRemaining(
                  hasScrollBody: false,
                  child: AsyncErrorView(
                    message: 'No pudimos cargar la tienda.',
                    onRetry: () => ref.invalidate(productsProvider),
                  ),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyView(
                        message: 'Aún no hay productos disponibles.',
                      ),
                    );
                  }
                  final categories =
                      items
                          .map((item) => item.category)
                          .whereType<String>()
                          .where((category) => category.trim().isNotEmpty)
                          .toSet()
                          .toList()
                        ..sort();
                  final active = categories.contains(_category)
                      ? _category
                      : null;
                  final visible = active == null
                      ? items
                      : items.where((item) => item.category == active).toList();
                  return SliverPadding(
                    padding: EdgeInsets.fromLTRB(gutter, 0, gutter, 52),
                    sliver: SliverMainAxisGroup(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (categories.length > 1)
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    children: [
                                      ChoiceChip(
                                        label: const Text('Todos'),
                                        selected: active == null,
                                        onSelected: (_) =>
                                            setState(() => _category = null),
                                      ),
                                      for (final category in categories)
                                        ChoiceChip(
                                          label: Text(category),
                                          selected: active == category,
                                          onSelected: (_) => setState(
                                            () => _category = category,
                                          ),
                                        ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                        SliverList.builder(
                          itemCount: (visible.length / columns).ceil(),
                          itemBuilder: (context, row) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (
                                  var column = 0;
                                  column < columns;
                                  column++
                                ) ...[
                                  if (column > 0) const SizedBox(width: 12),
                                  Expanded(
                                    child:
                                        row * columns + column < visible.length
                                        ? ProductCard(
                                            product:
                                                visible[row * columns + column],
                                          )
                                        : const SizedBox.shrink(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    final cover = NetworkCover(
      url: product.image,
      aspectRatio: 1,
      fit: BoxFit.contain,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
    );
    return Semantics(
      label: '${product.name}, ${_price(product.price)}',
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ProductDetailScreen(productId: product.id),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              cover,
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (product.category case final category?) ...[
                      Text(
                        category.toUpperCase(),
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                      ),
                      const SizedBox(height: 5),
                    ],
                    Text(
                      product.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (product.brand case final brand?) ...[
                      const SizedBox(height: 4),
                      Text(
                        brand,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      _price(product.price),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    if (product.stock == 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Agotado',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductSkeleton extends StatelessWidget {
  const _ProductSkeleton();
  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SkeletonBlock(height: 180),
      SizedBox(height: 11),
      SkeletonBlock(width: 90, height: 12),
      SizedBox(height: 4),
      SkeletonBlock(height: 20),
      SizedBox(height: 3),
      Row(
        children: [
          Expanded(child: SkeletonBlock(height: 12)),
          SizedBox(width: 28),
          SkeletonBlock(width: 52, height: 12),
        ],
      ),
    ],
  );
}

String _price(num value) => '\$${value.toStringAsFixed(2)} MXN';
