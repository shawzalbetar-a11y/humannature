import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:human_nature_admin/providers/product_provider.dart';

class OverviewPage extends ConsumerWidget {
  const OverviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsStreamProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'HOŞ GELDİNİZ',
              style: TextStyle(letterSpacing: 2, fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'MAĞAZA ÖZETİ',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _StatCard(
                    title: 'TOPLAM ÜRÜN',
                    value: productsAsync.when(
                      data: (data) => data.length.toString(),
                      loading: () => '...',
                      error: (e, stackTrace) => '!',
                    ),
                    icon: LucideIcons.package,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    title: 'YENİ EKLENEN',
                    value: productsAsync.when(
                      data: (data) => data.where((p) => p.isNewArrival).length.toString(),
                      loading: () => '...',
                      error: (e, stackTrace) => '!',
                    ),
                    icon: LucideIcons.sparkles,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    title: 'TREND ÜRÜNLER',
                    value: productsAsync.when(
                      data: (data) => data.where((p) => p.isTrending).length.toString(),
                      loading: () => '...',
                      error: (e, stackTrace) => '!',
                    ),
                    icon: LucideIcons.trendingUp,
                    color: Colors.red,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'SON EKLENEN ÜRÜNLER',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: productsAsync.when(
                data: (products) {
                  if (products.isEmpty) {
                    return const Center(child: Text('Henüz ürün eklenmedi.'));
                  }
                  return ListView.builder(
                    itemCount: products.length > 5 ? 5 : products.length,
                    itemBuilder: (context, index) {
                      final p = products[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(p.imageUrl),
                            backgroundColor: Colors.grey.shade200,
                          ),
                          title: Text(p.title),
                          subtitle: Text('${p.category} > ${p.subCategory ?? ""}'),
                          trailing: Text('${p.discountPrice} TL', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, stack) => Center(child: Text('Hata: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 116,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const Icon(LucideIcons.moreVertical, size: 14, color: Colors.grey),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                title,
                style: TextStyle(fontSize: 9, color: Colors.grey.shade600, fontWeight: FontWeight.w600, letterSpacing: 0.5),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
