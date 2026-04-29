import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:human_nature_admin/providers/product_provider.dart';

/// Streams the dynamic categories list from Firestore settings/categories
final categoriesStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(firebaseServiceProvider).streamCategories();
});
