import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/layout/side_b_layout.dart';
import '../../../core/theme/side_b_theme.dart';
import '../../../core/widgets/async_state.dart';
import '../../../core/widgets/editorial_components.dart';
import '../../../core/widgets/olive_shimmer.dart';
import '../data/content_models.dart';
import 'cart_screen.dart';
import 'content_providers.dart';
import 'product_detail_screen.dart';

class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final padding = SideBLayout.horizontalPadding(width);
        final columns = width >= SideBLayout.expandedBreakpoint ? 3 : 2;
        return CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(
              child: EditorialHeader(
                eyebrow: 'Objetos y ediciones',
                title: 'La tienda\ndel otro lado.',
                description:
                    'Música y piezas seleccionadas para llevar contigo.',
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(right: padding, bottom: 8),
                child: const Align(
                  alignment: Alignment.centerRight,
                  child: CartButton(),
                ),
              ),
            ),
            products.when(
              loading: () => SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(padding, 0, padding, 112),
                  child: OliveShimmer(
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisSpacing: 22,
                        crossAxisSpacing: 16,
                        childAspectRatio: .78,
                      ),
                      itemCount: columns * 2,
                      itemBuilder: (_, __) => const _ProductSkeleton(),
                    ),
                  ),
                ),
              ),
              error: (_, __) => SliverFillRemaining(
                child: AsyncErrorView(
                  message: 'No pudimos cargar la tienda.',
                  onRetry: () => ref.invalidate(productsProvider),
                ),
              ),
              data: (items) => items.isEmpty
                  ? const SliverFillRemaining(
                      child: EmptyView(
                        message: 'Aún no hay productos disponibles.',
                      ),
                    )
                  : SliverPadding(
                      padding: EdgeInsets.fromLTRB(padding, 0, padding, 112),
                      sliver: SliverGrid(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) =>
                              _ProductCard(product: items[index]),
                          childCount: items.length,
                        ),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          mainAxisSpacing: 22,
                          crossAxisSpacing: 16,
                          childAspectRatio: .78,
                        ),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '${product.name}, ${_price(product.price)}',
    child: InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProductDetailScreen(productId: product.id),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: NetworkCover(url: product.image, aspectRatio: 1)),
          const SizedBox(height: 11),
          Text(
            (product.category ?? 'SIDE B').toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: SideBColors.accent),
          ),
          const SizedBox(height: 4),
          Text(
            product.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              Expanded(
                child: Text(
                  product.brand ?? 'SIDE B',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Text(
                _price(product.price),
                style: Theme.of(context).textTheme.labelMedium
                    ?.copyWith(color: SideBColors.graphite),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _ProductSkeleton extends StatelessWidget {
  const _ProductSkeleton();
  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: SkeletonBlock(radius: 3)),
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

String _price(num value) => '\$${value.toStringAsFixed(0)} MXN';
