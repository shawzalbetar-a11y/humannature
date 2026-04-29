import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:human_nature_admin/models/product.dart';
import 'package:human_nature_admin/providers/product_provider.dart';

/// Predefined colors for the admin to pick from
const Map<String, Color> availableColors = {
  'Siyah': Color(0xFF000000),
  'Beyaz': Color(0xFFFFFFFF),
  'Lacivert': Color(0xFF0A192F),
  'Gri': Color(0xFF808080),
  'Kırmızı': Color(0xFFC0392B),
  'Mavi': Color(0xFF2980B9),
  'Yeşil': Color(0xFF27AE60),
  'Kahverengi': Color(0xFF6D4C41),
  'Bej': Color(0xFFD4C5A9),
  'Bordo': Color(0xFF800020),
  'Haki': Color(0xFF5D6B3E),
  'Turuncu': Color(0xFFE67E22),
  'Pembe': Color(0xFFE91E8C),
  'Sarı': Color(0xFFF1C40F),
  'Mor': Color(0xFF8E44AD),
  'Antrasit': Color(0xFF383838),
  'Krem': Color(0xFFFFFDD0),
  'Ekru': Color(0xFFF0EAD6),
  'Camel': Color(0xFFC19A6B),
  'Indigo': Color(0xFF3F51B5),
  'Petrol': Color(0xFF005F6B),
  'Hardal': Color(0xFFCFAD00),
  'Vizon': Color(0xFF8B7D6B),
};

/// All standard sizes
const List<String> allSizes = [
  'XS', 'S', 'M', 'L', 'XL', 'XXL', '3XL',
  '36', '38', '40', '42', '44', '46', '48',
];

class VariantsStep extends ConsumerStatefulWidget {
  const VariantsStep({super.key});

  @override
  ConsumerState<VariantsStep> createState() => _VariantsStepState();
}

class _VariantsStepState extends ConsumerState<VariantsStep> {
  String? _selectedColor;
  final Set<String> _selectedSizes = {};
  bool _inStock = true;

  void _addVariants() {
    if (_selectedColor == null || _selectedSizes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen renk ve en az bir beden seçin.')),
      );
      return;
    }

    final notifier = ref.read(productFormProvider.notifier);

    for (final size in _selectedSizes) {
      final variant = ProductVariant(
        size: size,
        color: _selectedColor!,
        stock: _inStock ? 1 : 0,
      );
      notifier.addVariant(variant);
    }

    setState(() {
      _selectedColor = null;
      _selectedSizes.clear();
      _inStock = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Varyantlar eklendi!'), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(productFormProvider);
    final formNotifier = ref.read(productFormProvider.notifier);

    // Group existing variants by color
    final Map<String, List<ProductVariant>> groupedVariants = {};
    for (final v in formState.variants) {
      groupedVariants.putIfAbsent(v.color, () => []).add(v);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'VARYANTLAR VE STOK YÖNETİMİ',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        const Text(
          'Her renk için hangi bedenlerin mevcut olduğunu belirleyin. Her renk, mağazada ayrı bir ürün sayfası olarak yayınlanacaktır.',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Color Picker
              const Text('1. RENK SEÇİN', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black54)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: availableColors.entries.map((entry) {
                  final isSelected = _selectedColor == entry.key;
                  final color = entry.value;
                  final isLight = color.computeLuminance() > 0.5;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = entry.key),
                    child: Tooltip(
                      message: entry.key,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.black : Colors.grey.shade300,
                            width: isSelected ? 3 : 1,
                          ),
                          boxShadow: isSelected
                              ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8, spreadRadius: 1)]
                              : null,
                        ),
                        child: isSelected
                            ? Icon(Icons.check, size: 18, color: isLight ? Colors.black : Colors.white)
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (_selectedColor != null) ...[
                const SizedBox(height: 8),
                Text('Seçilen: $_selectedColor', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ],
              const SizedBox(height: 24),

              // 2. Size Picker
              const Text('2. BEDENLERİ SEÇİN', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black54)),
              const SizedBox(height: 4),
              const Text('Birden fazla beden seçebilirsiniz.', style: TextStyle(fontSize: 11, color: Colors.grey)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: allSizes.map((size) {
                  final isSelected = _selectedSizes.contains(size);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedSizes.remove(size);
                        } else {
                          _selectedSizes.add(size);
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 52,
                      height: 42,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.black : Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSelected ? Colors.black : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        size,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // 3. Stock Toggle
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: SwitchListTile(
                  title: Text(
                    _inStock ? 'Stokta Var' : 'Tükendi',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _inStock ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                  ),
                  subtitle: Text(
                    _inStock ? 'Seçilen bedenler satışa açık.' : 'Seçilen bedenler tükendi olarak işaretlenecek.',
                    style: const TextStyle(fontSize: 12),
                  ),
                  value: _inStock,
                  onChanged: (val) => setState(() => _inStock = val),
                  activeThumbColor: Colors.green.shade700,
                  contentPadding: EdgeInsets.zero,
                ),
              ),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _addVariants,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('VARYANTLARI EKLE'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Added Variants List — Grouped by Color
        if (groupedVariants.isNotEmpty) ...[
          const Text(
            'EKLENMİŞ VARYANTLAR',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 16),
          ...groupedVariants.entries.map((entry) {
            final colorName = entry.key;
            final variants = entry.value;
            final color = availableColors[colorName] ?? Colors.grey;

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Color header
                  Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        colorName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const Spacer(),
                      // Delete all variants of this color
                      TextButton.icon(
                        onPressed: () {
                          final currentVariants = [...formState.variants];
                          currentVariants.removeWhere((v) => v.color == colorName);
                          formNotifier.replaceVariants(currentVariants);
                        },
                        icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                        label: const Text('Tümünü Sil', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Size chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: variants.map((v) {
                      final stockOk = v.stock > 0;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: stockOk ? Colors.green.shade50 : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: stockOk ? Colors.green.shade200 : Colors.red.shade200,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              v.size,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: stockOk ? Colors.green.shade800 : Colors.red.shade800,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              stockOk ? Icons.check_circle : Icons.cancel,
                              size: 14,
                              color: stockOk ? Colors.green.shade700 : Colors.red.shade700,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          }),
        ] else
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text('Henüz varyant eklenmedi.', style: TextStyle(color: Colors.grey)),
            ),
          ),
      ],
    );
  }
}
