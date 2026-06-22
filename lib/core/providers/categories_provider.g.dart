// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'categories_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(activeCategoriesStream)
final activeCategoriesStreamProvider = ActiveCategoriesStreamProvider._();

final class ActiveCategoriesStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<String>>,
          List<String>,
          Stream<List<String>>
        >
    with $FutureModifier<List<String>>, $StreamProvider<List<String>> {
  ActiveCategoriesStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeCategoriesStreamProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeCategoriesStreamHash();

  @$internal
  @override
  $StreamProviderElement<List<String>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<String>> create(Ref ref) {
    return activeCategoriesStream(ref);
  }
}

String _$activeCategoriesStreamHash() =>
    r'3f2c229e8aec51dd85cda2d33477d95e941af51b';
