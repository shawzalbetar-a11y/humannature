import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:human_nature_admin/models/product.dart';
import 'package:human_nature_admin/services/firebase_service.dart';

final firebaseServiceProvider = Provider((ref) => FirebaseService());

final productsStreamProvider = StreamProvider<List<Product>>((ref) {
  return ref.watch(firebaseServiceProvider).streamProducts();
});

// State for the Add Product Form
class ProductFormModel {
  final String title;
  final String description;
  final String category;
  final String? subCategory;
  final double originalPrice;
  final double discountPrice;
  final double? cartPrice;
  final bool isTrending;
  final bool isNewArrival;
  final List<ProductVariant> variants;
  final int stockCount;
  /// Images per color: { "Siyah": [XFile, ...], "Beyaz": [XFile, ...] }
  final Map<String, List<dynamic>> colorImages;
  /// Fabric type (e.g., Pamuk, Polyester)
  final String? fabricType;
  /// Fit type (e.g., Slim Fit, Regular Fit, Oversize)
  final String? fit;
  /// Product type/style (e.g., Basic, Polo)
  final String? tip;
  /// Collar type (e.g., Bisiklet Yaka, V Yaka)
  final String? collarType;
  /// Product Code
  final String? productCode;
  /// Trendyol URL
  final String? trendyolUrl;
  /// Shopier URL
  final String? shopierUrl;

  ProductFormModel({
    this.title = '',
    this.description = '',
    this.category = 'giyim',
    this.subCategory,
    this.originalPrice = 0,
    this.discountPrice = 0,
    this.cartPrice,
    this.isTrending = false,
    this.isNewArrival = true,
    this.variants = const [],
    this.colorImages = const {},
    this.stockCount = 0,
    this.fabricType,
    this.fit,
    this.tip,
    this.collarType,
    this.productCode = 'HN',
    this.trendyolUrl,
    this.shopierUrl,
  });

  /// Get distinct colors from variants
  List<String> get distinctColors {
    final colors = <String>{};
    for (final v in variants) {
      if (v.color.isNotEmpty) colors.add(v.color);
    }
    return colors.toList();
  }

  ProductFormModel copyWith({
    String? title,
    String? description,
    String? category,
    String? subCategory,
    double? originalPrice,
    double? discountPrice,
    double? cartPrice,
    bool? isTrending,
    bool? isNewArrival,
    List<ProductVariant>? variants,
    Map<String, List<dynamic>>? colorImages,
    int? stockCount,
    String? fabricType,
    String? fit,
    String? tip,
    String? collarType,
    String? productCode,
    String? trendyolUrl,
    String? shopierUrl,
  }) {
    return ProductFormModel(
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      subCategory: subCategory ?? this.subCategory,
      originalPrice: originalPrice ?? this.originalPrice,
      discountPrice: discountPrice ?? this.discountPrice,
      cartPrice: cartPrice ?? this.cartPrice,
      isTrending: isTrending ?? this.isTrending,
      isNewArrival: isNewArrival ?? this.isNewArrival,
      variants: variants ?? this.variants,
      colorImages: colorImages ?? this.colorImages,
      stockCount: stockCount ?? this.stockCount,
      fabricType: fabricType ?? this.fabricType,
      fit: fit ?? this.fit,
      tip: tip ?? this.tip,
      collarType: collarType ?? this.collarType,
      productCode: productCode ?? this.productCode,
      trendyolUrl: trendyolUrl ?? this.trendyolUrl,
      shopierUrl: shopierUrl ?? this.shopierUrl,
    );
  }
}

class ProductFormNotifier extends Notifier<ProductFormModel> {
  @override
  ProductFormModel build() => ProductFormModel();

  void updateTitle(String value) => state = state.copyWith(title: value);
  void updateDescription(String value) => state = state.copyWith(description: value);
  void updateCategory(String value) => state = state.copyWith(category: value, subCategory: null);
  void updateSubCategory(String? value) => state = state.copyWith(subCategory: value);
  void updateOriginalPrice(double value) => state = state.copyWith(originalPrice: value);
  void updateDiscountPrice(double value) => state = state.copyWith(discountPrice: value);
  void updateCartPrice(double? value) => state = state.copyWith(cartPrice: value);
  void toggleTrending(bool value) => state = state.copyWith(isTrending: value);
  void toggleNewArrival(bool value) => state = state.copyWith(isNewArrival: value);
  void updateStockCount(int value) => state = state.copyWith(stockCount: value);
  void updateFabricType(String? value) => state = state.copyWith(fabricType: value);
  void updateFit(String? value) => state = state.copyWith(fit: value);
  void updateTip(String? value) => state = state.copyWith(tip: value);
  void updateCollarType(String? value) => state = state.copyWith(collarType: value);
  void updateProductCode(String? value) => state = state.copyWith(productCode: value);
  void updateTrendyolUrl(String? value) => state = state.copyWith(trendyolUrl: value);
  void updateShopierUrl(String? value) => state = state.copyWith(shopierUrl: value);
  
  void addVariant(ProductVariant variant) {
    state = state.copyWith(variants: [...state.variants, variant]);
  }

  void removeVariant(int index) {
    final newVariants = [...state.variants];
    newVariants.removeAt(index);
    state = state.copyWith(variants: newVariants);
  }

  void replaceVariants(List<ProductVariant> newVariants) {
    state = state.copyWith(variants: newVariants);
  }

  /// Add an image for a specific color
  void addColorImage(String colorName, dynamic image) {
    final newColorImages = Map<String, List<dynamic>>.from(state.colorImages);
    newColorImages.putIfAbsent(colorName, () => []);
    newColorImages[colorName] = [...newColorImages[colorName]!, image];
    state = state.copyWith(colorImages: newColorImages);
  }

  /// Remove an image for a specific color
  void removeColorImage(String colorName, int index) {
    final newColorImages = Map<String, List<dynamic>>.from(state.colorImages);
    if (newColorImages.containsKey(colorName)) {
      final images = [...newColorImages[colorName]!];
      images.removeAt(index);
      newColorImages[colorName] = images;
      state = state.copyWith(colorImages: newColorImages);
    }
  }

  void reset() => state = ProductFormModel();
}

final productFormProvider = NotifierProvider<ProductFormNotifier, ProductFormModel>(() {
  return ProductFormNotifier();
});
