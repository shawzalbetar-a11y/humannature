import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:human_nature_admin/providers/product_provider.dart';
import 'package:human_nature_admin/views/add_product/widgets/variants_step.dart';

class ImagesStep extends ConsumerWidget {
  const ImagesStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(productFormProvider);
    final formNotifier = ref.read(productFormProvider.notifier);
    final picker = ImagePicker();

    // Get distinct colors from variants
    final colors = formState.distinctColors;

    Future<void> pickImageForColor(String colorName) async {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        formNotifier.addColorImage(colorName, image);
      }
    }

    Future<void> pickMultipleImagesForColor(String colorName) async {
      final List<XFile> images = await picker.pickMultiImage();
      for (final image in images) {
        formNotifier.addColorImage(colorName, image);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'GÖRSELLER',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        Text(
          colors.length > 1
              ? 'Her renk için ayrı görseller ekleyin. Her renk mağazada ayrı bir ürün sayfası olarak yayınlanacaktır.'
              : 'Ürün görsellerini ekleyin.',
          style: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
        const SizedBox(height: 24),

        if (colors.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Henüz varyant eklenmedi. Lütfen önce "Varyantlar" adımından renk ve beden ekleyin.',
                    style: TextStyle(color: Colors.orange, fontSize: 13),
                  ),
                ),
              ],
            ),
          )
        else
          ...colors.map((colorName) {
            final colorHex = availableColors[colorName] ?? Colors.grey;
            final isLight = colorHex.computeLuminance() > 0.5;
            final images = formState.colorImages[colorName] ?? [];

            return Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Color Header
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: colorHex,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: isLight
                            ? null
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        colorName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: images.isNotEmpty ? Colors.green.shade50 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: images.isNotEmpty ? Colors.green.shade200 : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          '${images.length} görsel',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: images.isNotEmpty ? Colors.green.shade700 : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Images Grid
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      // Existing images
                      ...images.asMap().entries.map((entry) {
                        final index = entry.key;
                        final image = entry.value;
                        String? imageName;
                        if (image is XFile) {
                          imageName = image.name;
                        }

                        return Stack(
                          children: [
                            Container(
                              width: 90,
                              height: 110,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade200),
                                color: Colors.grey.shade50,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.image, color: Colors.grey, size: 28),
                                    const SizedBox(height: 4),
                                    if (imageName != null)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                        child: Text(
                                          imageName,
                                          style: const TextStyle(fontSize: 8, color: Colors.grey),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            // Delete Button
                            Positioned(
                              right: 0,
                              top: 0,
                              child: GestureDetector(
                                onTap: () => formNotifier.removeColorImage(colorName, index),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, size: 12, color: Colors.white),
                                ),
                              ),
                            ),
                            // Order Badge
                            Positioned(
                              left: 4,
                              top: 4,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        );
                      }),

                      // Add Button
                      GestureDetector(
                        onTap: () => pickImageForColor(colorName),
                        child: Container(
                          width: 90,
                          height: 110,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_outlined, color: Colors.grey, size: 22),
                              SizedBox(height: 6),
                              Text('EKLE', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),

                      // Multi-select Button
                      GestureDetector(
                        onTap: () => pickMultipleImagesForColor(colorName),
                        child: Container(
                          width: 90,
                          height: 110,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200, style: BorderStyle.solid),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.photo_library_outlined, color: Colors.blue.shade400, size: 22),
                              const SizedBox(height: 6),
                              Text('TOPLU', style: TextStyle(fontSize: 10, color: Colors.blue.shade400, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),

        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 24),
        const Text(
          'ÖNE ÇIKARMA SEÇENEKLERİ',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Yeni Gelenler Listesine Ekle'),
          subtitle: const Text('Ürün "Yeni Gelenler" sekmesinde görünecektir.'),
          value: formState.isNewArrival,
          onChanged: formNotifier.toggleNewArrival,
          activeThumbColor: Colors.black,
        ),
        SwitchListTile(
          title: const Text('Trend Ürün Olarak İşaretle'),
          subtitle: const Text('Ürün ana sayfada ve trend listesinde öne çıkarılır.'),
          value: formState.isTrending,
          onChanged: formNotifier.toggleTrending,
          activeThumbColor: Colors.black,
        ),
      ],
    );
  }
}
