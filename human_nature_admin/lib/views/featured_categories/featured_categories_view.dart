import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:human_nature_admin/providers/product_provider.dart';

class FeaturedCategoriesView extends ConsumerStatefulWidget {
  const FeaturedCategoriesView({super.key});

  @override
  ConsumerState<FeaturedCategoriesView> createState() =>
      _FeaturedCategoriesViewState();
}

class _FeaturedCategoriesViewState
    extends ConsumerState<FeaturedCategoriesView> {
  bool _isLoading = true;
  bool _isSaving = false;

  // Giyim config
  String _giyimMode = 'auto';
  int _giyimAutoLimit = 5;
  List<String> _giyimManualIds = [];

  // Aksesuar config
  String _aksesuarMode = 'auto';
  int _aksesuarAutoLimit = 5;
  List<String> _aksesuarManualIds = [];

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final firebaseService = ref.read(firebaseServiceProvider);
    final data = await firebaseService.getFeaturedCategoriesConfig();

    if (data != null && mounted) {
      setState(() {
        // Giyim
        final giyim = data['giyim'] as Map<String, dynamic>?;
        if (giyim != null) {
          _giyimMode = giyim['mode'] ?? 'auto';
          _giyimAutoLimit = giyim['autoLimit'] ?? 5;
          _giyimManualIds =
              List<String>.from(giyim['manualProductIds'] ?? []);
        }

        // Aksesuar
        final aksesuar = data['aksesuar'] as Map<String, dynamic>?;
        if (aksesuar != null) {
          _aksesuarMode = aksesuar['mode'] ?? 'auto';
          _aksesuarAutoLimit = aksesuar['autoLimit'] ?? 5;
          _aksesuarManualIds =
              List<String>.from(aksesuar['manualProductIds'] ?? []);
        }
      });
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _saveConfig() async {
    setState(() => _isSaving = true);

    final firebaseService = ref.read(firebaseServiceProvider);
    await firebaseService.updateFeaturedCategoriesConfig({
      'giyim': {
        'mode': _giyimMode,
        'autoLimit': _giyimAutoLimit,
        'manualProductIds': _giyimManualIds,
      },
      'aksesuar': {
        'mode': _aksesuarMode,
        'autoLimit': _aksesuarAutoLimit,
        'manualProductIds': _aksesuarManualIds,
      },
    });

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Öne çıkan kategoriler ayarları başarıyla kaydedildi!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ÖNE ÇIKAN KATEGORİLER',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ana sayfada gösterilen "Öne Çıkan Kategoriler" bölümünü buradan yönetebilirsiniz. '
            'Her kategori için otomatik (en çok satan ürünler) veya manuel (seçtiğiniz ürünler) modunu seçebilirsiniz.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),

          // Desktop: side by side, Mobile: stacked
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 900) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildCategoryCard(
                        title: 'GİYİM',
                        icon: LucideIcons.shirt,
                        categoryKey: 'giyim',
                        mode: _giyimMode,
                        autoLimit: _giyimAutoLimit,
                        manualIds: _giyimManualIds,
                        onModeChanged: (m) => setState(() => _giyimMode = m),
                        onAutoLimitChanged: (v) =>
                            setState(() => _giyimAutoLimit = v),
                        onManualIdsChanged: (ids) =>
                            setState(() => _giyimManualIds = ids),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _buildCategoryCard(
                        title: 'AKSESUAR',
                        icon: LucideIcons.gem,
                        categoryKey: 'aksesuar',
                        mode: _aksesuarMode,
                        autoLimit: _aksesuarAutoLimit,
                        manualIds: _aksesuarManualIds,
                        onModeChanged: (m) =>
                            setState(() => _aksesuarMode = m),
                        onAutoLimitChanged: (v) =>
                            setState(() => _aksesuarAutoLimit = v),
                        onManualIdsChanged: (ids) =>
                            setState(() => _aksesuarManualIds = ids),
                      ),
                    ),
                  ],
                );
              }
              return Column(
                children: [
                  _buildCategoryCard(
                    title: 'GİYİM',
                    icon: LucideIcons.shirt,
                    categoryKey: 'giyim',
                    mode: _giyimMode,
                    autoLimit: _giyimAutoLimit,
                    manualIds: _giyimManualIds,
                    onModeChanged: (m) => setState(() => _giyimMode = m),
                    onAutoLimitChanged: (v) =>
                        setState(() => _giyimAutoLimit = v),
                    onManualIdsChanged: (ids) =>
                        setState(() => _giyimManualIds = ids),
                  ),
                  const SizedBox(height: 24),
                  _buildCategoryCard(
                    title: 'AKSESUAR',
                    icon: LucideIcons.gem,
                    categoryKey: 'aksesuar',
                    mode: _aksesuarMode,
                    autoLimit: _aksesuarAutoLimit,
                    manualIds: _aksesuarManualIds,
                    onModeChanged: (m) => setState(() => _aksesuarMode = m),
                    onAutoLimitChanged: (v) =>
                        setState(() => _aksesuarAutoLimit = v),
                    onManualIdsChanged: (ids) =>
                        setState(() => _aksesuarManualIds = ids),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 32),

          // Save button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveConfig,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(LucideIcons.save, size: 18),
              label: const Text(
                'AYARLARI KAYDET',
                style: TextStyle(
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildCategoryCard({
    required String title,
    required IconData icon,
    required String categoryKey,
    required String mode,
    required int autoLimit,
    required List<String> manualIds,
    required ValueChanged<String> onModeChanged,
    required ValueChanged<int> onAutoLimitChanged,
    required ValueChanged<List<String>> onManualIdsChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(icon, size: 22, color: Colors.black87),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Mode toggle
          const Text(
            'GÖRÜNTÜLEME MODU',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 10),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'auto',
                label: Text('Otomatik'),
                icon: Icon(LucideIcons.sparkles, size: 16),
              ),
              ButtonSegment(
                value: 'manual',
                label: Text('Manuel'),
                icon: Icon(LucideIcons.hand, size: 16),
              ),
            ],
            selected: {mode},
            onSelectionChanged: (set) => onModeChanged(set.first),
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: Colors.black,
              selectedForegroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 20),

          // Mode-specific content
          if (mode == 'auto') ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.info, size: 16, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'En çok satan $autoLimit ürün otomatik olarak gösterilecek.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'ÜRÜN SAYISI',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (int n in [3, 5, 8, 10])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('$n'),
                      selected: autoLimit == n,
                      onSelected: (_) => onAutoLimitChanged(n),
                      selectedColor: Colors.black,
                      labelStyle: TextStyle(
                        color: autoLimit == n ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ] else ...[
            // Manual mode — product picker
            _ManualProductPicker(
              categoryKey: categoryKey,
              selectedIds: manualIds,
              onChanged: onManualIdsChanged,
            ),
          ],
        ],
      ),
    );
  }
}

/* ═══════════════════════════════════════════════════════════
   Manual Product Picker Widget
   ═══════════════════════════════════════════════════════════ */

class _ManualProductPicker extends ConsumerWidget {
  final String categoryKey;
  final List<String> selectedIds;
  final ValueChanged<List<String>> onChanged;

  const _ManualProductPicker({
    required this.categoryKey,
    required this.selectedIds,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsStreamProvider);

    return productsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Text('Hata: $e'),
      data: (allProducts) {
        // Filter by category
        final categoryProducts = allProducts
            .where((p) => p.category == categoryKey)
            .toList();

        if (categoryProducts.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.alertCircle,
                    size: 16, color: Colors.orange.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Bu kategoride henüz ürün bulunmuyor.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selected products preview
            if (selectedIds.isNotEmpty) ...[
              const Text(
                'SEÇİLEN ÜRÜNLER',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: selectedIds.map((id) {
                  final product = categoryProducts
                      .where((p) => p.id == id)
                      .firstOrNull;
                  return Chip(
                    avatar: product != null && product.imageUrl.isNotEmpty
                        ? CircleAvatar(
                            backgroundImage:
                                CachedNetworkImageProvider(product.imageUrl),
                            backgroundColor: Colors.grey.shade200,
                          )
                        : null,
                    label: Text(
                      product?.title ?? id.substring(0, 8),
                      style: const TextStyle(fontSize: 12),
                    ),
                    deleteIcon:
                        const Icon(LucideIcons.x, size: 14),
                    onDeleted: () {
                      final updated = [...selectedIds]..remove(id);
                      onChanged(updated);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Info box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.mousePointerClick,
                      size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    'Aşağıdan en fazla 5 ürün seçebilirsiniz.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Product list
            ...categoryProducts.map((product) {
              final isSelected = selectedIds.contains(product.id);
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: InkWell(
                  onTap: () {
                    if (isSelected) {
                      final updated = [...selectedIds]..remove(product.id);
                      onChanged(updated);
                    } else if (selectedIds.length < 5) {
                      onChanged([...selectedIds, product.id]);
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.black.withValues(alpha: 0.05)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? Colors.black
                            : Colors.grey.shade200,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Checkbox
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.black : Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.black
                                  : Colors.grey.shade400,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(Icons.check,
                                  size: 14, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        // Product image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: SizedBox(
                            width: 36,
                            height: 36,
                            child: product.imageUrl.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: product.imageUrl,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      color: Colors.grey.shade200,
                                    ),
                                    errorWidget: (context, url, error) => Container(
                                      color: Colors.grey.shade200,
                                      child: const Icon(Icons.image,
                                          size: 16, color: Colors.grey),
                                    ),
                                  )
                                : Container(
                                    color: Colors.grey.shade200,
                                    child: const Icon(Icons.image,
                                        size: 16, color: Colors.grey),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Product info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.title,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${product.discountPrice.toStringAsFixed(0)} TL  •  Satış: ${product.salesCount}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
