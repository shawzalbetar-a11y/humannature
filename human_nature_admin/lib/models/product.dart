import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String slug;
  final String title;
  final String description;
  final String imageUrl;
  final List<String> images;
  final double originalPrice;
  final double discountPrice;
  final double? cartPrice;
  final String category;
  final String? subCategory;
  final bool isTrending;
  final bool isNewArrival;
  final int salesCount;
  final DateTime createdAt;
  final List<ProductVariant>? variants;
  final Map<String, dynamic>? filters;
  /// Groups products that are the same item but different colors
  final String? groupId;
  /// The color name of this specific product variant
  final String? colorName;
  /// Number of colors in this product group
  final int colorCount;
  /// Number of remaining items in stock
  final int stockCount;
  /// Fabric type (e.g., Pamuk, Polyester, Keten)
  final String? fabricType;
  /// Fit type (e.g., Slim Fit, Regular Fit, Oversize)
  final String? fit;
  /// Product type/style (e.g., Basic, Polo, Kapüşonlu)
  final String? tip;
  /// Collar type (e.g., Bisiklet Yaka, V Yaka, Polo Yaka)
  final String? collarType;
  /// Product code starting with HN
  final String? productCode;
  /// Trendyol product URL
  final String? trendyolUrl;
  /// Shopier product URL
  final String? shopierUrl;

  Product({
    required this.id,
    required this.slug,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.images,
    required this.originalPrice,
    required this.discountPrice,
    this.cartPrice,
    required this.category,
    this.subCategory,
    required this.isTrending,
    required this.isNewArrival,
    required this.salesCount,
    required this.createdAt,
    this.variants,
    this.filters,
    this.groupId,
    this.colorName,
    this.colorCount = 0,
    this.stockCount = 0,
    this.fabricType,
    this.fit,
    this.tip,
    this.collarType,
    this.productCode,
    this.trendyolUrl,
    this.shopierUrl,
  });

  static DateTime _parseDate(dynamic dateData) {
    if (dateData == null) return DateTime.now();
    if (dateData is Timestamp) return dateData.toDate();
    if (dateData is int) return DateTime.fromMillisecondsSinceEpoch(dateData);
    if (dateData is String) return DateTime.tryParse(dateData) ?? DateTime.now();
    return DateTime.now();
  }

  factory Product.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      slug: data['slug'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      images: List<String>.from(data['images'] ?? []),
      originalPrice: (data['originalPrice'] ?? 0).toDouble(),
      discountPrice: (data['discountPrice'] ?? 0).toDouble(),
      cartPrice: data['cartPrice']?.toDouble(),
      category: data['category'] ?? '',
      subCategory: data['subCategory'],
      isTrending: data['isTrending'] ?? false,
      isNewArrival: data['isNewArrival'] ?? false,
      salesCount: data['salesCount'] ?? 0,
      createdAt: _parseDate(data['createdAt']),
      variants: (data['variants'] as List?)
          ?.map((v) => ProductVariant.fromMap(v))
          .toList(),
      filters: data['filters'],
      groupId: data['groupId'],
      colorName: data['colorName'],
      colorCount: data['colorCount'] ?? 0,
      stockCount: data['stockCount'] ?? 0,
      fabricType: data['fabricType'],
      fit: data['fit'],
      tip: data['tip'],
      collarType: data['collarType'],
      productCode: data['productCode'],
      trendyolUrl: data['trendyolUrl'],
      shopierUrl: data['shopierUrl'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'slug': slug,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'images': images,
      'originalPrice': originalPrice,
      'discountPrice': discountPrice,
      'cartPrice': cartPrice,
      'category': category,
      'subCategory': subCategory,
      'isTrending': isTrending,
      'isNewArrival': isNewArrival,
      'salesCount': salesCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'variants': variants?.map((v) => v.toMap()).toList(),
      'filters': filters,
      'groupId': groupId,
      'colorName': colorName,
      'colorCount': colorCount,
      'stockCount': stockCount,
      if (fabricType != null) 'fabricType': fabricType,
      if (fit != null) 'fit': fit,
      if (tip != null) 'tip': tip,
      if (collarType != null) 'collarType': collarType,
      if (productCode != null) 'productCode': productCode,
      if (trendyolUrl != null) 'trendyolUrl': trendyolUrl,
      if (shopierUrl != null) 'shopierUrl': shopierUrl,
    };
  }
}

class ProductVariant {
  final String size;
  final String color;
  final int stock;

  ProductVariant({
    required this.size,
    required this.color,
    required this.stock,
  });

  factory ProductVariant.fromMap(Map<String, dynamic> map) {
    return ProductVariant(
      size: map['size'] ?? '',
      color: map['color'] ?? '',
      stock: map['stock'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'size': size,
      'color': color,
      'stock': stock,
    };
  }
}
