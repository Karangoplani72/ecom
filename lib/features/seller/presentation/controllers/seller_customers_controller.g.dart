// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'seller_customers_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(sellerCustomers)
final sellerCustomersProvider = SellerCustomersProvider._();

final class SellerCustomersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SellerCustomer>>,
          List<SellerCustomer>,
          Stream<List<SellerCustomer>>
        >
    with
        $FutureModifier<List<SellerCustomer>>,
        $StreamProvider<List<SellerCustomer>> {
  SellerCustomersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sellerCustomersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sellerCustomersHash();

  @$internal
  @override
  $StreamProviderElement<List<SellerCustomer>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<SellerCustomer>> create(Ref ref) {
    return sellerCustomers(ref);
  }
}

String _$sellerCustomersHash() => r'c068d394635cca17595b455a4064f4fda321e097';
