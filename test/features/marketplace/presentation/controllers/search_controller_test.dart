import 'package:ecom/features/marketplace/domain/entities/catalog_item.dart';
import 'package:ecom/features/marketplace/domain/repositories/search_repository.dart';
import 'package:ecom/features/marketplace/presentation/controllers/search_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockSearchRepository extends Mock implements SearchRepository {}

void main() {
  late MockSearchRepository mockSearchRepository;
  late ProviderContainer container;

  setUp(() {
    mockSearchRepository = MockSearchRepository();
    container = ProviderContainer(
      overrides: [
        searchRepositoryProvider.overrideWithValue(mockSearchRepository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('SearchController', () {
    test('initial state is empty list', () async {
      final state = await container.read(searchControllerProvider.future);
      expect(state, isEmpty);
    });

    test('search returns items successfully', () async {
      final mockItem = CatalogItem(
        id: '1',
        storeId: 's1',
        title: 'Test Product',
        description: 'Test',
        basePrice: 100,
        currency: 'INR',
        type: 'product',
        status: 'active',
        isActive: true,
        category: 'general',
        imageUrls: [],
        metadata: {},
      );

      when(() => mockSearchRepository.searchCatalog(
            query: 'test',
            categories: any(named: 'categories'),
            sortMode: any(named: 'sortMode'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => Right([mockItem]));

      final controller = container.read(searchControllerProvider.notifier);
      
      await controller.search(query: 'test');

      final state = await container.read(searchControllerProvider.future);
      expect(state, isNotEmpty);
      expect(state.first.title, 'Test Product');
      
      verify(() => mockSearchRepository.searchCatalog(
            query: 'test',
            categories: any(named: 'categories'),
            sortMode: any(named: 'sortMode'),
            limit: any(named: 'limit'),
          )).called(1);
    });
  });
}
