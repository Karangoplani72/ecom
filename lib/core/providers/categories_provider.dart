import 'package:ecom/core/providers/common_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'categories_provider.g.dart';

@riverpod
Stream<List<String>> activeCategoriesStream(Ref ref) {
  return ref.watch(firebaseFirestoreProvider)
      .collection('categories')
      .snapshots()
      .map((snapshot) {
        final defaultCategories = [
          'Electronics',
          'Fashion',
          'Home',
          'Beauty',
          'Sports',
          'Groceries',
          'Books',
          'Toys',
          'Fitness',
          'Gifts',
        ];
        final customCategories = snapshot.docs.map((doc) => doc.id).toList();
        final merged = <String>[];
        merged.addAll(defaultCategories);
        for (final cat in customCategories) {
          // Normalize matching case/trimming just in case
          final exists = merged.any((element) => element.toLowerCase() == cat.trim().toLowerCase());
          if (!exists) {
            merged.add(cat.trim());
          }
        }
        return merged;
      });
}
