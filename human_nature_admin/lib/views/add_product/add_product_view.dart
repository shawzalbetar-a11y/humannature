
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:human_nature_admin/providers/product_provider.dart';
import 'package:human_nature_admin/services/cloudinary_service.dart';
import 'package:human_nature_admin/models/product.dart';
import 'package:human_nature_admin/views/add_product/widgets/basic_info_step.dart';
import 'package:human_nature_admin/views/add_product/widgets/pricing_step.dart';
import 'package:human_nature_admin/views/add_product/widgets/variants_step.dart';
import 'package:human_nature_admin/views/add_product/widgets/images_step.dart';
import 'package:uuid/uuid.dart';

class AddProductView extends ConsumerStatefulWidget {
  const AddProductView({super.key});

  @override
  ConsumerState<AddProductView> createState() => _AddProductViewState();
}

class _AddProductViewState extends ConsumerState<AddProductView> {
  int _currentStep = 0;
  bool _isSubmitting = false;

  Future<void> _submitProduct() async {
    final formState = ref.read(productFormProvider);
    final formNotifier = ref.read(productFormProvider.notifier);
    final firebaseService = ref.read(firebaseServiceProvider);

    if (formState.title.isEmpty || formState.category.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen zorunlu alanları doldurun.')));
      return;
    }

    if (formState.variants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen en az bir varyant (renk + beden) ekleyin.')));
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // 1. Get Cloudinary Accounts
      final accounts = await firebaseService.getCloudinaryAccounts();
      if (accounts.isEmpty) {
        throw Exception('Cloudinary hesapları bulunamadı. Lütfen ayarlardan hesap ekleyin.');
      }
      // Find the active account (or default to the first one if none is active)
      final account = accounts.firstWhere(
        (acc) => acc['isActive'] == true,
        orElse: () => accounts.first,
      );
      // Helper: upload a list of images and return URLs
      Future<List<String>> uploadImages(List<dynamic> images) async {
        List<String> urls = [];
        for (var image in images) {
          if (image is XFile) {
            final bytes = await image.readAsBytes();
            
            final url = await CloudinaryService.uploadImage(
              imageBytes: bytes,
              cloudName: account['cloudName']!,
              uploadPreset: account['uploadPreset']!,
              fileName: image.name,
            );

            if (url != null) {
              urls.add(url);
            } else {
              throw Exception('Görsel yüklenirken bir hata oluştu: ${image.name}');
            }
          } else if (image is String) {
            urls.add(image);
          }
        }
        return urls;
      }

      // 2. Group variants by color
      final Map<String, List<ProductVariant>> variantsByColor = {};
      for (final v in formState.variants) {
        variantsByColor.putIfAbsent(v.color, () => []).add(v);
      }

      // 3. Generate a shared groupId for all color variants
      final groupId = const Uuid().v4();
      final now = DateTime.now();

      // Simple slug generation helper
      String makeSlug(String text) {
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

      // 4. Create one document per color with its own images
      int publishedCount = 0;
      final totalColors = variantsByColor.length;

      for (final entry in variantsByColor.entries) {
        final colorName = entry.key;
        final colorVariants = entry.value;
        final productId = const Uuid().v4();

        // Upload images specific to this color
        final colorImageFiles = formState.colorImages[colorName] ?? [];
        final imageUrls = await uploadImages(colorImageFiles);

        // Slug: product-name-color
        String slug = makeSlug('${formState.title} $colorName');
        if (slug.isEmpty) slug = productId.substring(0, 8);

        final product = Product(
          id: productId,
          slug: slug,
          title: formState.title,
          description: formState.description,
          imageUrl: imageUrls.isNotEmpty ? imageUrls.first : '',
          category: formState.category,
          subCategory: formState.subCategory,
          originalPrice: formState.originalPrice,
          discountPrice: formState.discountPrice,
          cartPrice: formState.cartPrice,
          images: imageUrls,
          variants: colorVariants,
          createdAt: now,
          isTrending: formState.isTrending,
          isNewArrival: formState.isNewArrival,
          salesCount: 0,
          groupId: totalColors > 1 ? groupId : null,
          colorName: colorName,
          colorCount: totalColors,
          stockCount: formState.stockCount,
          fabricType: formState.fabricType,
          fit: formState.fit,
          tip: formState.tip,
          collarType: formState.collarType,
          productCode: formState.productCode,
          trendyolUrl: formState.trendyolUrl,
          shopierUrl: formState.shopierUrl,
        );

        await firebaseService.addProduct(product);
        publishedCount++;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$publishedCount renk varyantı başarıyla yayınlandı!'),
          backgroundColor: Colors.green,
        ));
        formNotifier.reset();
        setState(() {
          _currentStep = 0;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isSubmitting) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.black),
            SizedBox(height: 16),
            Text('Ürün yayınlanıyor, lütfen bekleyin...', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Stepper(
      type: isDesktop ? StepperType.horizontal : StepperType.vertical,
      currentStep: _currentStep,
      onStepContinue: () {
        if (_currentStep < 3) {
          setState(() {
            _currentStep += 1;
          });
        } else {
          _submitProduct();
        }
      },
      onStepCancel: () {
        if (_currentStep > 0) {
          setState(() {
            _currentStep -= 1;
          });
        }
      },
      controlsBuilder: (context, details) {
        return Padding(
          padding: const EdgeInsets.only(top: 32.0),
          child: Row(
            children: [
              if (_currentStep < 3)
                Expanded(
                  child: ElevatedButton(
                    onPressed: details.onStepContinue,
                    child: const Text('SONRAKİ ADIM'),
                  ),
                )
              else
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submitProduct,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
                    child: const Text('ÜRÜNÜ YAYINLA', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              const SizedBox(width: 12),
              if (_currentStep > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: details.onStepCancel,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('GERİ'),
                  ),
                ),
            ],
          ),
        );
      },
      steps: [
        Step(
          title: const Text('Bilgiler'),
          isActive: _currentStep >= 0,
          state: _currentStep > 0 ? StepState.complete : StepState.indexed,
          content: const BasicInfoStep(),
        ),
        Step(
          title: const Text('Fiyat'),
          isActive: _currentStep >= 1,
          state: _currentStep > 1 ? StepState.complete : StepState.indexed,
          content: const PricingStep(),
        ),
        Step(
          title: const Text('Varyantlar'),
          isActive: _currentStep >= 2,
          state: _currentStep > 2 ? StepState.complete : StepState.indexed,
          content: const VariantsStep(),
        ),
        Step(
          title: const Text('Görseller'),
          isActive: _currentStep >= 3,
          state: _currentStep > 3 ? StepState.complete : StepState.indexed,
          content: const ImagesStep(),
        ),
      ],
    );
  }
}
