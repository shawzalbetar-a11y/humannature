import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:human_nature_admin/models/product.dart';
import 'package:human_nature_admin/providers/product_provider.dart';
import 'package:human_nature_admin/providers/categories_provider.dart';

class EditProductView extends ConsumerStatefulWidget {
  final Product product;
  const EditProductView({super.key, required this.product});

  @override
  ConsumerState<EditProductView> createState() => _EditProductViewState();
}

class _EditProductViewState extends ConsumerState<EditProductView> {
  bool _isSaving = false;

  // ── Controllers ──
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _originalPriceController;
  late TextEditingController _discountPriceController;
  late TextEditingController _cartPriceController;
  late TextEditingController _stockCountController;
  late TextEditingController _productCodeController;

  // ── State values ──
  late String _category;
  late String? _subCategory;
  late bool _isTrending;
  late bool _isNewArrival;
  late String? _fabricType;
  late String? _fit;
  late String? _tip;
  late String? _collarType;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _titleController = TextEditingController(text: p.title);
    _descriptionController = TextEditingController(text: p.description);
    _originalPriceController = TextEditingController(text: p.originalPrice.toStringAsFixed(0));
    _discountPriceController = TextEditingController(text: p.discountPrice.toStringAsFixed(0));
    _cartPriceController = TextEditingController(text: p.cartPrice?.toStringAsFixed(0) ?? '');
    _stockCountController = TextEditingController(text: p.stockCount.toString());
    _productCodeController = TextEditingController(text: p.productCode ?? 'HN');
    _category = p.category;
    _subCategory = p.subCategory;
    _isTrending = p.isTrending;
    _isNewArrival = p.isNewArrival;
    _fabricType = p.fabricType;
    _fit = p.fit;
    _tip = p.tip;
    _collarType = p.collarType;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _originalPriceController.dispose();
    _discountPriceController.dispose();
    _cartPriceController.dispose();
    _stockCountController.dispose();
    _productCodeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);

    try {
      final firebaseService = ref.read(firebaseServiceProvider);

      final updatedData = <String, dynamic>{
        'title': _titleController.text.trim(),
        'productCode': _productCodeController.text.trim(),
        'description': _descriptionController.text.trim(),
        'originalPrice': double.tryParse(_originalPriceController.text) ?? 0,
        'discountPrice': double.tryParse(_discountPriceController.text) ?? 0,
        'cartPrice': _cartPriceController.text.isNotEmpty
            ? double.tryParse(_cartPriceController.text)
            : null,
        'stockCount': int.tryParse(_stockCountController.text) ?? 0,
        'category': _category,
        'subCategory': _subCategory,
        'isTrending': _isTrending,
        'isNewArrival': _isNewArrival,
        'fabricType': _fabricType,
        'fit': _fit,
        'tip': _tip,
        'collarType': _collarType,
      };

      await firebaseService.updateProductFields(widget.product.id, updatedData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ürün başarıyla güncellendi!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'ÜRÜN DÜZENLE',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5),
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(LucideIcons.save, size: 16),
              label: const Text('KAYDET', style: TextStyle(letterSpacing: 1, fontWeight: FontWeight.bold, fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Product Header Preview ──
                _buildProductPreview(),
                const SizedBox(height: 24),

                // ── Basic Info Section ──
                _buildSection(
                  title: 'TEMEL BİLGİLER',
                  icon: LucideIcons.fileText,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Ürün Başlığı',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _productCodeController,
                        decoration: const InputDecoration(
                          labelText: 'Ürün Kodu',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Ürün Açıklaması',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Category Section (Dynamic from Firestore) ──
                _buildCategorySection(ref),
                const SizedBox(height: 16),

                // ── Pricing Section ──
                _buildSection(
                  title: 'FİYATLANDIRMA',
                  icon: LucideIcons.badgeDollarSign,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _originalPriceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Orijinal Fiyat (TL)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _discountPriceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'İndirimli Fiyat (TL)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _cartPriceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Sepet Fiyatı (TL)',
                            hintText: 'Opsiyonel',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Stock & Status Section ──
                _buildSection(
                  title: 'STOK & DURUM',
                  icon: LucideIcons.warehouse,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _stockCountController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Stok Adedi',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Column(
                              children: [
                                SwitchListTile(
                                  title: const Text('Yeni Ürün', style: TextStyle(fontSize: 14)),
                                  subtitle: const Text('Ana sayfada "Yeni Gelenler" de göster', style: TextStyle(fontSize: 11)),
                                  value: _isNewArrival,
                                  onChanged: (val) => setState(() => _isNewArrival = val),
                                  activeThumbColor: Colors.blue,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                SwitchListTile(
                                  title: const Text('Trend Ürün', style: TextStyle(fontSize: 14)),
                                  subtitle: const Text('"Trend" bölümünde göster', style: TextStyle(fontSize: 11)),
                                  value: _isTrending,
                                  onChanged: (val) => setState(() => _isTrending = val),
                                  activeThumbColor: Colors.orange,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Product Details Section ──
                _buildSection(
                  title: 'ÜRÜN DETAYLARI',
                  icon: LucideIcons.shirt,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String?>(
                              initialValue: _fabricType,
                              decoration: const InputDecoration(
                                labelText: 'Kumaş Tipi',
                                border: OutlineInputBorder(),
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
                              onChanged: (val) => setState(() => _fabricType = val),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String?>(
                              initialValue: _fit,
                              decoration: const InputDecoration(
                                labelText: 'Kalıp (Fit)',
                                border: OutlineInputBorder(),
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
                              onChanged: (val) => setState(() => _fit = val),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String?>(
                              initialValue: _tip,
                              decoration: const InputDecoration(
                                labelText: 'Tip',
                                border: OutlineInputBorder(),
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
                              onChanged: (val) => setState(() => _tip = val),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String?>(
                              initialValue: _collarType,
                              decoration: const InputDecoration(
                                labelText: 'Yaka Tipi',
                                border: OutlineInputBorder(),
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
                              onChanged: (val) => setState(() => _collarType = val),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Variants Preview Section ──
                _buildSection(
                  title: 'VARYANTLAR (${widget.product.variants?.length ?? 0} adet)',
                  icon: LucideIcons.layers,
                  child: widget.product.variants != null && widget.product.variants!.isNotEmpty
                      ? Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: widget.product.variants!.map((v) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: v.stock > 0 ? Colors.green.shade50 : Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: v.stock > 0 ? Colors.green.shade200 : Colors.red.shade200,
                                ),
                              ),
                              child: Text(
                                '${v.color} / ${v.size}  —  Stok: ${v.stock}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: v.stock > 0 ? Colors.green.shade800 : Colors.red.shade800,
                                ),
                              ),
                            );
                          }).toList(),
                        )
                      : const Text(
                          'Bu üründe varyant tanımlanmamış.',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                ),

                const SizedBox(height: 32),

                // ── Bottom Save Button ──
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _save,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(LucideIcons.save, size: 18),
                    label: const Text(
                      'DEĞİŞİKLİKLERİ KAYDET',
                      style: TextStyle(letterSpacing: 1.5, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // Dynamic Category Section (from Firestore)
  // ═══════════════════════════════════════════════════════════

  Widget _buildCategorySection(WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return categoriesAsync.when(
      loading: () => _buildSection(
        title: 'KATEGORİ',
        icon: LucideIcons.tag,
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => _buildSection(
        title: 'KATEGORİ',
        icon: LucideIcons.tag,
        child: Text('Kategoriler yüklenemedi: $e'),
      ),
      data: (categories) {
        // Find subcategories for selected category
        final selectedCat = categories.firstWhere(
          (c) => c['slug'] == _category,
          orElse: () => <String, dynamic>{},
        );
        final subCategories = (selectedCat['subCategories'] as List<dynamic>?)
                ?.cast<Map<String, dynamic>>() ??
            [];

        return _buildSection(
          title: 'KATEGORİ',
          icon: LucideIcons.tag,
          child: Column(
            children: [
              Column(
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: categories.any((c) => c['slug'] == _category)
                        ? _category
                        : (categories.isNotEmpty ? categories.first['slug'] as String : null),
                    decoration: const InputDecoration(
                      labelText: 'Kategori',
                      border: OutlineInputBorder(),
                    ),
                    isExpanded: true,
                    items: categories.map((cat) {
                      return DropdownMenuItem<String>(
                        value: cat['slug'] as String,
                        child: Text(cat['title'] as String),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() {
                      _category = val!;
                      _subCategory = null;
                    }),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String?>(
                    initialValue: (subCategories.any((s) => s['slug'] == _subCategory))
                        ? _subCategory
                        : null,
                    decoration: const InputDecoration(
                      labelText: 'Alt Kategori',
                      border: OutlineInputBorder(),
                    ),
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
                    onChanged: (val) => setState(() => _subCategory = val),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  InkWell(
                    onTap: () => _showAddCategoryDialog(context, ref, categories),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.plusCircle, size: 14, color: Colors.blue.shade700),
                          const SizedBox(width: 6),
                          Text(
                            'Yeni Kategori',
                            style: TextStyle(fontSize: 12, color: Colors.blue.shade700, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  InkWell(
                    onTap: () => _showAddSubCategoryDialog(context, ref, categories, _category),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.plusCircle, size: 14, color: Colors.blue.shade700),
                          const SizedBox(width: 6),
                          Text(
                            'Yeni Alt Kategori',
                            style: TextStyle(fontSize: 12, color: Colors.blue.shade700, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

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
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İPTAL')),
          ElevatedButton(
            onPressed: () async {
              final title = controller.text.trim();
              if (title.isEmpty) return;
              final slug = _makeSlug(title);
              if (currentCategories.any((c) => c['slug'] == slug)) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Bu kategori zaten mevcut!'), backgroundColor: Colors.orange),
                  );
                }
                return;
              }
              final newCategories = [
                ...currentCategories,
                {'slug': slug, 'title': title, 'subCategories': <Map<String, dynamic>>[]},
              ];
              await ref.read(firebaseServiceProvider).saveCategories(newCategories);
              setState(() => _category = slug);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
            child: const Text('EKLE'),
          ),
        ],
      ),
    );
  }

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
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İPTAL')),
          ElevatedButton(
            onPressed: () async {
              final title = controller.text.trim();
              if (title.isEmpty) return;
              final slug = _makeSlug(title);
              final updatedCategories = currentCategories.map((cat) {
                if (cat['slug'] == parentCategorySlug) {
                  final subs = List<Map<String, dynamic>>.from(
                    (cat['subCategories'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [],
                  );
                  if (subs.any((s) => s['slug'] == slug)) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Bu alt kategori zaten mevcut!'), backgroundColor: Colors.orange),
                    );
                    return cat;
                  }
                  subs.add({'slug': slug, 'title': title});
                  return {...cat, 'subCategories': subs};
                }
                return cat;
              }).toList();
              await ref.read(firebaseServiceProvider).saveCategories(updatedCategories);
              setState(() => _subCategory = slug);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
            child: const Text('EKLE'),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // Reusable section card
  // ═══════════════════════════════════════════════════════════

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: Colors.black54),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // Product preview header
  // ═══════════════════════════════════════════════════════════

  Widget _buildProductPreview() {
    final p = widget.product;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Product image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 80,
              height: 100,
              child: p.imageUrl.isNotEmpty
                  ? Image.network(
                      p.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image, color: Colors.grey),
                      ),
                    )
                  : Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image, size: 32, color: Colors.grey),
                    ),
            ),
          ),
          const SizedBox(width: 20),
          // Product info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${p.category.toUpperCase()}${p.subCategory != null ? ' / ${p.subCategory!.toUpperCase()}' : ''}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600, letterSpacing: 1),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '${p.discountPrice.toStringAsFixed(0)} TL',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    if (p.originalPrice > p.discountPrice)
                      Text(
                        '${p.originalPrice.toStringAsFixed(0)} TL',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: p.stockCount > 0 ? Colors.green.shade50 : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Stok: ${p.stockCount}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: p.stockCount > 0 ? Colors.green.shade700 : Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Product ID badge
          Column(
            children: [
              const Text('ID', style: TextStyle(fontSize: 9, color: Colors.grey, letterSpacing: 1)),
              const SizedBox(height: 2),
              SelectableText(
                p.id.substring(0, 8),
                style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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
