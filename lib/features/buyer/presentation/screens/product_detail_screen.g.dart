// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_detail_screen.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(catalogItemStream)
final catalogItemStreamProvider = CatalogItemStreamFamily._();

final class CatalogItemStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<CatalogItem?>,
          CatalogItem?,
          Stream<CatalogItem?>
        >
    with $FutureModifier<CatalogItem?>, $StreamProvider<CatalogItem?> {
  CatalogItemStreamProvider._({
    required CatalogItemStreamFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'catalogItemStreamProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$catalogItemStreamHash();

  @override
  String toString() {
    return r'catalogItemStreamProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<CatalogItem?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<CatalogItem?> create(Ref ref) {
    final argument = this.argument as String;
    return catalogItemStream(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CatalogItemStreamProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$catalogItemStreamHash() => r'f215c50a2bde6db5e2aae55c70d7638f5f0e201b';

final class CatalogItemStreamFamily extends $Family
    with $FunctionalFamilyOverride<Stream<CatalogItem?>, String> {
  CatalogItemStreamFamily._()
    : super(
        retry: null,
        name: r'catalogItemStreamProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CatalogItemStreamProvider call(String productId) =>
      CatalogItemStreamProvider._(argument: productId, from: this);

  @override
  String toString() => r'catalogItemStreamProvider';
}

@ProviderFor(wishlistStatus)
final wishlistStatusProvider = WishlistStatusFamily._();

final class WishlistStatusProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  WishlistStatusProvider._({
    required WishlistStatusFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'wishlistStatusProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$wishlistStatusHash();

  @override
  String toString() {
    return r'wishlistStatusProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    final argument = this.argument as String;
    return wishlistStatus(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WishlistStatusProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$wishlistStatusHash() => r'11e9eb7577c85da34fe663238d957c79779f6e09';

final class WishlistStatusFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<bool>, String> {
  WishlistStatusFamily._()
    : super(
        retry: null,
        name: r'wishlistStatusProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WishlistStatusProvider call(String productId) =>
      WishlistStatusProvider._(argument: productId, from: this);

  @override
  String toString() => r'wishlistStatusProvider';
}

@ProviderFor(productReviews)
final productReviewsProvider = ProductReviewsFamily._();

final class ProductReviewsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Map<String, dynamic>>>,
          List<Map<String, dynamic>>,
          Stream<List<Map<String, dynamic>>>
        >
    with
        $FutureModifier<List<Map<String, dynamic>>>,
        $StreamProvider<List<Map<String, dynamic>>> {
  ProductReviewsProvider._({
    required ProductReviewsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'productReviewsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$productReviewsHash();

  @override
  String toString() {
    return r'productReviewsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<Map<String, dynamic>>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Map<String, dynamic>>> create(Ref ref) {
    final argument = this.argument as String;
    return productReviews(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ProductReviewsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$productReviewsHash() => r'dc347132658bddb6378cc8359ec514759734448e';

final class ProductReviewsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<Map<String, dynamic>>>, String> {
  ProductReviewsFamily._()
    : super(
        retry: null,
        name: r'productReviewsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ProductReviewsProvider call(String productId) =>
      ProductReviewsProvider._(argument: productId, from: this);

  @override
  String toString() => r'productReviewsProvider';
}
