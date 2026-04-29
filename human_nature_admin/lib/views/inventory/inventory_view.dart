import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:human_nature_admin/providers/product_provider.dart';
import 'package:human_nature_admin/views/inventory/edit_product_view.dart';

class InventoryView extends ConsumerStatefulWidget {
  const InventoryView({super.key});

  @override
  ConsumerState<InventoryView> createState() => _InventoryViewState();
}

class _InventoryViewState extends ConsumerState<InventoryView> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsStreamProvider);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // Search Bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Ürün ara...',
              prefixIcon: const Icon(LucideIcons.search, size: 20),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
          ),
          const SizedBox(height: 24),
          // Inventory Table
          Expanded(
            child: productsAsync.when(
              data: (products) {
                final filteredProducts = products.where((p) => 
                  p.title.toLowerCase().contains(_searchQuery) || 
                  p.category.toLowerCase().contains(_searchQuery)
                ).toList();

                if (filteredProducts.isEmpty) {
                  return const Center(child: Text('Ürün bulunamadı', style: TextStyle(color: Colors.grey)));
                }

                return ListView.builder(
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final p = filteredProducts[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      elevation: 0,
                      color: Colors.white,
                      child: ExpansionTile(
                        shape: const Border(),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(p.imageUrl, width: 40, height: 40, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const Icon(Icons.image)),
                        ),
                        title: Text(p.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: Text('${p.discountPrice} TL • Stok: ${p.stockCount}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                        children: [
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Kategori: ${p.category.toUpperCase()}', style: const TextStyle(fontSize: 13)),
                                          const SizedBox(height: 8),
                                          Wrap(
                                            spacing: 4,
                                            runSpacing: 4,
                                            children: [
                                              if (p.isNewArrival) const _Tag(label: 'YENİ', color: Colors.blue),
                                              if (p.isTrending) const _Tag(label: 'TREND', color: Colors.orange),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(LucideIcons.edit2, size: 18),
                                          tooltip: 'Düzenle',
                                          constraints: const BoxConstraints(),
                                          padding: const EdgeInsets.all(8),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(builder: (_) => EditProductView(product: p)),
                                            );
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(LucideIcons.trash2, size: 18, color: Colors.redAccent),
                                          tooltip: 'Sil',
                                          constraints: const BoxConstraints(),
                                          padding: const EdgeInsets.all(8),
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                title: const Text('Ürünü Sil'),
                                                content: Text('"${p.title}" ürününü silmek istediğinize emin misiniz?'),
                                                actions: [
                                                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İPTAL')),
                                                  ElevatedButton(
                                                    onPressed: () async {
                                                      await ref.read(firebaseServiceProvider).deleteProduct(p.id);
                                                      if (ctx.mounted) Navigator.pop(ctx);
                                                    },
                                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                                                    child: const Text('SİL'),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                if (p.description.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    p.description,
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, stackTrace) => Center(child: Text('Hata: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold)),
    );
  }
}
