import 'package:ecom/core/providers/common_providers.dart';
import 'package:ecom/features/seller/data/repositories/seller_finance_repository_impl.dart';
import 'package:ecom/features/seller/domain/entities/merchant_wallet.dart';
import 'package:ecom/features/seller/domain/entities/seller_transaction.dart';
import 'package:ecom/features/seller/domain/repositories/seller_finance_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'seller_finances_controller.g.dart';

@riverpod
SellerFinanceRepository sellerFinanceRepository(Ref ref) {
  return SellerFinanceRepositoryImpl(
    firestore: ref.watch(firebaseFirestoreProvider),
  );
}

@riverpod
Future<MerchantWallet> merchantWallet(Ref ref) async {
  final sellerId = ref.watch(currentUserIdProvider);

  if (sellerId == null || sellerId.isEmpty) {
    throw Exception('Seller not authenticated');
  }

  final result = await ref
      .read(sellerFinanceRepositoryProvider)
      .getMerchantWallet(sellerId: sellerId);

  return result.fold((error) => throw error, (wallet) => wallet);
}

@riverpod
Future<Map<String, dynamic>?> sellerBankAccount(Ref ref) async {
  final sellerId = ref.watch(currentUserIdProvider);
  if (sellerId == null || sellerId.isEmpty) return null;
  final doc = await ref
      .read(firebaseFirestoreProvider)
      .collection('sellers')
      .doc(sellerId)
      .collection('bankDetails')
      .doc('primary')
      .get();
  return doc.data();
}

@riverpod
Future<List<SellerTransaction>> sellerTransactions(Ref ref) async {
  final sellerId = ref.watch(currentUserIdProvider);
  if (sellerId == null || sellerId.isEmpty) return [];
  final result = await ref
      .read(sellerFinanceRepositoryProvider)
      .getTransactions(sellerId: sellerId);
  return result.fold((error) => throw error, (list) => list);
}

@riverpod
class SellerFinancesController extends _$SellerFinancesController {
  @override
  Future<MerchantWallet> build() async {
    final sellerId = ref.watch(currentUserIdProvider);

    if (sellerId == null || sellerId.isEmpty) {
      throw Exception('Seller not authenticated');
    }

    try {
      final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (idToken != null) {
        await http
            .post(
              Uri.parse(
                'https://releasematuredescrows-oshbhnscba-uc.a.run.app',
              ),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $idToken',
              },
            )
            .timeout(const Duration(seconds: 10));
      }
    } catch (e) {
      debugPrint('Failed to release matured escrows: $e');
    }

    final result = await ref
        .read(sellerFinanceRepositoryProvider)
        .getMerchantWallet(sellerId: sellerId);

    return result.fold((error) => throw error, (wallet) => wallet);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();

    final sellerId = ref.read(currentUserIdProvider);

    if (sellerId == null || sellerId.isEmpty) {
      state = AsyncError(
        Exception('Seller not authenticated'),
        StackTrace.current,
      );
      return;
    }

    try {
      final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (idToken != null) {
        await http
            .post(
              Uri.parse(
                'https://releasematuredescrows-oshbhnscba-uc.a.run.app',
              ),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $idToken',
              },
            )
            .timeout(const Duration(seconds: 10));
      }
    } catch (e) {
      debugPrint('Failed to release matured escrows in refresh: $e');
    }

    final result = await ref
        .read(sellerFinanceRepositoryProvider)
        .getMerchantWallet(sellerId: sellerId);

    result.fold(
      (error) {
        state = AsyncError(error, StackTrace.current);
      },
      (wallet) {
        state = AsyncData(wallet);
      },
    );
  }

  Future<void> requestPayout({
    required double amount,
    required String bankAccountId,
  }) async {
    if (amount <= 0) {
      state = AsyncError(
        Exception('Amount must be greater than zero'),
        StackTrace.current,
      );
      return;
    }

    final sellerId = ref.read(currentUserIdProvider);

    if (sellerId == null || sellerId.isEmpty) {
      state = AsyncError(
        Exception('Seller not authenticated'),
        StackTrace.current,
      );
      return;
    }

    if (bankAccountId.isEmpty) {
      state = AsyncError(
        Exception('Bank account ID cannot be empty'),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading();

    final result = await ref
        .read(sellerFinanceRepositoryProvider)
        .requestPayout(
          sellerId: sellerId,
          amount: amount,
          bankAccountId: bankAccountId,
        );

    result.fold(
      (error) {
        state = AsyncError(error, StackTrace.current);
      },
      (_) async {
        await refresh();
      },
    );
  }

  Future<void> updateBankAccount({
    required String ifsc,
    required String accountNumber,
    required String holderName,
    required String bankName,
    required String branch,
    required String city,
    required String bankState,
    required String address,
  }) async {
    if (ifsc.isEmpty) {
      state = AsyncError(
        Exception('IFSC code cannot be empty'),
        StackTrace.current,
      );
      return;
    }

    if (accountNumber.isEmpty) {
      state = AsyncError(
        Exception('Account number cannot be empty'),
        StackTrace.current,
      );
      return;
    }

    if (holderName.isEmpty) {
      state = AsyncError(
        Exception('Account holder name cannot be empty'),
        StackTrace.current,
      );
      return;
    }

    if (bankName.isEmpty) {
      state = AsyncError(
        Exception('Bank name cannot be empty'),
        StackTrace.current,
      );
      return;
    }

    final sellerId = ref.read(currentUserIdProvider);

    if (sellerId == null || sellerId.isEmpty) {
      state = AsyncError(
        Exception('Seller not authenticated'),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading();

    final result = await ref
        .read(sellerFinanceRepositoryProvider)
        .updateBankAccount(
          sellerId: sellerId,
          ifsc: ifsc,
          accountNumber: accountNumber,
          holderName: holderName,
          bankName: bankName,
          branch: branch,
          city: city,
          state: bankState,
          address: address,
        );

    result.fold(
      (error) {
        state = AsyncError(error, StackTrace.current);
      },
      (_) async {
        ref.invalidate(sellerBankAccountProvider);
        await refresh();
      },
    );
  }
}
