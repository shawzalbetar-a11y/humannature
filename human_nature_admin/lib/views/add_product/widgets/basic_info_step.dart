import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:human_nature_admin/providers/product_provider.dart';
import 'package:human_nature_admin/providers/categories_provider.dart';

/// Turkish-safe slug generator
String _makeSlug(String text) {
  const charMap = {
    'ç': 'c', 'Ç': 'C', 'ğ': 'g', 'Ğ': 'G', 'ı': 'i', 'İ': 'I',
    'ö': 'o', 'Ö': 'O', 'ş': 's', 'Ş': 'S', 'ü': 'u', 'Ü': 'U',
  };
  return text
      .split('')
      .map((ch) => charMap[ch] ?? ch)
      .join('')
      .toLowerCase()
      .trim()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
}

class BasicInfoStep extends ConsumerWidget {
  const BasicInfoStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(productFormProvider);
    final formNotifier = ref.read(productFormProvider.notifier);
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return categoriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Kategoriler yüklenemedi: $e'),
      data: (categories) {
        // Find subcategories for the selected category
        final selectedCat = categories.firstWhere(
          (c) => c['slug'] == formState.category,
          orElse: () => <String, dynamic>{},
        );
        final subCategories = (selectedCat['subCategories'] as List<dynamic>?)
                ?.cast<Map<String, dynamic>>() ??
            [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ÜRÜN TEMEL BİLGİLERİ',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 24),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Ürün Başlığı',
                hintText: 'Örn: Klasik İtalyan Takım Elbise',
              ),
              onChanged: formNotifier.updateTitle,
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: formState.productCode,
              decoration: const InputDecoration(
                labelText: 'Ürün Kodu',
                hintText: 'Örn: HN12345',
              ),
              onChanged: formNotifier.updateProductCode,
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: formState.trendyolUrl,
              decoration: const InputDecoration(
                labelText: 'Trendyol Ürün Linki',
                hintText: 'Örn: https://www.trendyol.com/...',
              ),
              onChanged: formNotifier.updateTrendyolUrl,
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: formState.shopierUrl,
              decoration: const InputDecoration(
                labelText: 'Shopier Ürün Linki',
                hintText: 'Örn: https://www.shopier.com/...',
              ),
              onChanged: formNotifier.updateShopierUrl,
            ),
            const SizedBox(height: 16),
            TextFormField(
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Ürün Açıklaması',
                hintText: 'Ürünün özelliklerini ve kumaş bilgisini buraya yazın...',
              ),
              onChanged: formNotifier.updateDescription,
            ),
            const SizedBox(height: 24),

            // ── Kategori & Alt Kategori ──
            _CategoryDropdown(
              categories: categories,
              selectedSlug: formState.category,
              onChanged: (slug) {
                formNotifier.updateCategory(slug);
              },
              onAddNew: () => _showAddCategoryDialog(context, ref, categories),
            ),
            const SizedBox(height: 16),
            _SubCategoryDropdown(
              subCategories: subCategories,
              selectedSlug: formState.subCategory,
              onChanged: formNotifier.updateSubCategory,
              onAddNew: () => _showAddSubCategoryDialog(
                context, ref, categories, formState.category,
              ),
              enabled: categories.isNotEmpty,
            ),

            const SizedBox(height: 32),

            // ── Ürün Detayları ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ÜRÜN DETAYLARI',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.black54,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Bu bilgiler ürün sayfasında ve filtreleme sisteminde gösterilecektir.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),

                  // Column 1: Kumaş & Fit
                  DropdownButtonFormField<String?>(
                    initialValue: formState.fabricType,
                    decoration: const InputDecoration(
                      labelText: 'Kumaş Tipi',
                      hintText: 'Seçiniz',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Seçilmedi')),
                      DropdownMenuItem(value: 'Pamuk', child: Text('Pamuk')),
                      DropdownMenuItem(value: 'Polyester', child: Text('Polyester')),
                      DropdownMenuItem(value: 'Keten', child: Text('Keten')),
                      DropdownMenuItem(value: 'Viskon', child: Text('Viskon')),
                      DropdownMenuItem(value: 'Pamuk-Polyester', child: Text('Pamuk-Polyester')),
                      DropdownMenuItem(value: 'Yün', child: Text('Yün')),
                      DropdownMenuItem(value: 'İpek', child: Text('İpek')),
                      DropdownMenuItem(value: 'Denim', child: Text('Denim')),
                      DropdownMenuItem(value: 'Kadife', child: Text('Kadife')),
                      DropdownMenuItem(value: 'Saten', child: Text('Saten')),
                      DropdownMenuItem(value: 'Triko', child: Text('Triko')),
                      DropdownMenuItem(value: 'Scuba', child: Text('Scuba')),
                    ],
                    onChanged: formNotifier.updateFabricType,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String?>(
                    initialValue: formState.fit,
                    decoration: const InputDecoration(
                      labelText: 'Kalıp (Fit)',
                      hintText: 'Seçiniz',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Seçilmedi')),
                      DropdownMenuItem(value: 'Slim Fit', child: Text('Slim Fit')),
                      DropdownMenuItem(value: 'Regular Fit', child: Text('Regular Fit')),
                      DropdownMenuItem(value: 'Oversize', child: Text('Oversize')),
                      DropdownMenuItem(value: 'Relaxed Fit', child: Text('Relaxed Fit')),
                      DropdownMenuItem(value: 'Skinny Fit', child: Text('Skinny Fit')),
                    ],
                    onChanged: formNotifier.updateFit,
                  ),

                  const SizedBox(height: 16),

                  // Column 2: Tip & Yaka Tipi
                  DropdownButtonFormField<String?>(
                    initialValue: formState.tip,
                    decoration: const InputDecoration(
                      labelText: 'Tip',
                      hintText: 'Seçiniz',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Seçilmedi')),
                      DropdownMenuItem(value: 'Basic', child: Text('Basic')),
                      DropdownMenuItem(value: 'Polo', child: Text('Polo')),
                      DropdownMenuItem(value: 'Kapüşonlu', child: Text('Kapüşonlu')),
                      DropdownMenuItem(value: 'Fermuarlı', child: Text('Fermuarlı')),
                      DropdownMenuItem(value: 'Baskılı', child: Text('Baskılı')),
                      DropdownMenuItem(value: 'Çizgili', child: Text('Çizgili')),
                      DropdownMenuItem(value: 'Düz', child: Text('Düz')),
                      DropdownMenuItem(value: 'Desenli', child: Text('Desenli')),
                    ],
                    onChanged: formNotifier.updateTip,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String?>(
                    initialValue: formState.collarType,
                    decoration: const InputDecoration(
                      labelText: 'Yaka Tipi',
                      hintText: 'Seçiniz',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Seçilmedi')),
                      DropdownMenuItem(value: 'Bisiklet Yaka', child: Text('Bisiklet Yaka')),
                      DropdownMenuItem(value: 'V Yaka', child: Text('V Yaka')),
                      DropdownMenuItem(value: 'Polo Yaka', child: Text('Polo Yaka')),
                      DropdownMenuItem(value: 'Dik Yaka', child: Text('Dik Yaka')),
                      DropdownMenuItem(value: 'Balıkçı Yaka', child: Text('Balıkçı Yaka')),
                      DropdownMenuItem(value: 'Gömlek Yaka', child: Text('Gömlek Yaka')),
                      DropdownMenuItem(value: 'Kapüşon', child: Text('Kapüşon')),
                      DropdownMenuItem(value: 'Yakasız', child: Text('Yakasız')),
                    ],
                    onChanged: formNotifier.updateCollarType,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  // Add New Category Dialog
  // ═══════════════════════════════════════════════════════════

  void _showAddCategoryDialog(
    BuildContext context,
    WidgetRef ref,
    List<Map<String, dynamic>> currentCategories,
  ) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yeni Kategori Ekle'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Kategori Adı',
            hintText: 'Örn: Ayakkabı',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İPTAL'),
          ),
          ElevatedButton(
            onPressed: () async {
              final title = controller.text.trim();
              if (title.isEmpty) return;

              final slug = _makeSlug(title);

              // Check for duplicate
              if (currentCategories.any((c) => c['slug'] == slug)) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('Bu kategori zaten mevcut!'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
                return;
              }

              final newCategories = [
                ...currentCategories,
                {
                  'slug': slug,
                  'title': title,
                  'subCategories': <Map<String, dynamic>>[],
                },
              ];

              await ref.read(firebaseServiceProvider).saveCategories(newCategories);

              // Auto-select the new category
              ref.read(productFormProvider.notifier).updateCategory(slug);

              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
            child: const Text('EKLE'),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // Add New Subcategory Dialog
  // ═══════════════════════════════════════════════════════════

  void _showAddSubCategoryDialog(
    BuildContext context,
    WidgetRef ref,
    List<Map<String, dynamic>> currentCategories,
    String parentCategorySlug,
  ) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yeni Alt Kategori Ekle'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Alt Kategori Adı',
            hintText: 'Örn: Polo Tişört',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İPTAL'),
          ),
          ElevatedButton(
            onPressed: () async {
              final title = controller.text.trim();
              if (title.isEmpty) return;

              final slug = _makeSlug(title);

              // Deep copy & mutate
              final updatedCategories = currentCategories.map((cat) {
                if (cat['slug'] == parentCategorySlug) {
                  final subs = List<Map<String, dynamic>>.from(
                    (cat['subCategories'] as List<dynamic>?)
                            ?.cast<Map<String, dynamic>>() ??
                        [],
                  );

                  // Check for duplicate
                  if (subs.any((s) => s['slug'] == slug)) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(
                        content: Text('Bu alt kategori zaten mevcut!'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return cat;
                  }

                  subs.add({'slug': slug, 'title': title});
                  return {...cat, 'subCategories': subs};
                }
                return cat;
              }).toList();

              await ref.read(firebaseServiceProvider).saveCategories(updatedCategories);

              // Auto-select the new subcategory
              ref.read(productFormProvider.notifier).updateSubCategory(slug);

              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
            child: const Text('EKLE'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Category Dropdown with "Add New" option
// ═══════════════════════════════════════════════════════════

class _CategoryDropdown extends StatelessWidget {
  final List<Map<String, dynamic>> categories;
  final String selectedSlug;
  final ValueChanged<String> onChanged;
  final VoidCallback onAddNew;

  const _CategoryDropdown({
    required this.categories,
    required this.selectedSlug,
    required this.onChanged,
    required this.onAddNew,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: categories.any((c) => c['slug'] == selectedSlug)
              ? selectedSlug
              : (categories.isNotEmpty ? categories.first['slug'] as String : null),
          decoration: const InputDecoration(labelText: 'Kategori'),
          isExpanded: true,
          items: categories.map((cat) {
            return DropdownMenuItem<String>(
              value: cat['slug'] as String,
              child: Text(cat['title'] as String),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) onChanged(val);
          },
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onAddNew,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              children: [
                Icon(LucideIcons.plusCircle, size: 14, color: Colors.blue.shade700),
                Text(
                  'Yeni Kategori Ekle',
                  style: TextStyle(fontSize: 12, color: Colors.blue.shade700, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Subcategory Dropdown with "Add New" option
// ═══════════════════════════════════════════════════════════

class _SubCategoryDropdown extends StatelessWidget {
  final List<Map<String, dynamic>> subCategories;
  final String? selectedSlug;
  final ValueChanged<String?> onChanged;
  final VoidCallback onAddNew;
  final bool enabled;

  const _SubCategoryDropdown({
    required this.subCategories,
    required this.selectedSlug,
    required this.onChanged,
    required this.onAddNew,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String?>(
          initialValue: (selectedSlug != null && subCategories.any((s) => s['slug'] == selectedSlug))
              ? selectedSlug
              : null,
          decoration: const InputDecoration(labelText: 'Alt Kategori'),
          isExpanded: true,
          items: [
            const DropdownMenuItem<String?>(value: null, child: Text('Seçilmedi')),
            ...subCategories.map((sub) {
              return DropdownMenuItem<String?>(
                value: sub['slug'] as String,
                child: Text(sub['title'] as String),
              );
            }),
          ],
          onChanged: enabled ? onChanged : null,
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: enabled ? onAddNew : null,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              children: [
                Icon(LucideIcons.plusCircle, size: 14, color: enabled ? Colors.blue.shade700 : Colors.grey),
                Text(
                  'Yeni Alt Kategori Ekle',
                  style: TextStyle(
                    fontSize: 12,
                    color: enabled ? Colors.blue.shade700 : Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
