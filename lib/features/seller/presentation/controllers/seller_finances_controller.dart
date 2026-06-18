import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/seller_finance_repository_impl.dart';
import '../../domain/entities/merchant_wallet.dart';
import '../../domain/repositories/seller_finance_repository.dart';

part 'seller_finances_controller.g.dart';

@riverpod
SellerFinanceRepository sellerFinanceRepository(Ref ref) {
  return SellerFinanceRepositoryImpl(firestore: FirebaseFirestore.instance);
}

@riverpod
String? currentSellerId(Ref ref) {
  return FirebaseAuth.instance.currentUser?.uid;
}

@riverpod
Future<MerchantWallet> merchantWallet(Ref ref) async {
  final sellerId = ref.watch(currentSellerIdProvider);

  if (sellerId == null || sellerId.isEmpty) {
    throw Exception('Seller not authenticated');
  }

  final result = await ref
      .read(sellerFinanceRepositoryProvider)
      .getMerchantWallet(sellerId: sellerId);

  return result.fold((error) => throw error, (wallet) => wallet);
}

@riverpod
class SellerFinancesController extends _$SellerFinancesController {
  @override
  Future<MerchantWallet> build() async {
    final sellerId = ref.watch(currentSellerIdProvider);

    if (sellerId == null || sellerId.isEmpty) {
      throw Exception('Seller not authenticated');
    }

    final result = await ref
        .read(sellerFinanceRepositoryProvider)
        .getMerchantWallet(sellerId: sellerId);

    return result.fold((error) => throw error, (wallet) => wallet);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();

    final sellerId = ref.read(currentSellerIdProvider);

    if (sellerId == null || sellerId.isEmpty) {
      state = AsyncError(
        Exception('Seller not authenticated'),
        StackTrace.current,
      );
      return;
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

    final sellerId = ref.read(currentSellerIdProvider);

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
    required String accountId,
    required String accountNumber,
    required String ifscCode,
    required String accountHolderName,
  }) async {
    if (accountNumber.isEmpty) {
      state = AsyncError(
        Exception('Account number cannot be empty'),
        StackTrace.current,
      );
      return;
    }

    if (ifscCode.isEmpty) {
      state = AsyncError(
        Exception('IFSC code cannot be empty'),
        StackTrace.current,
      );
      return;
    }

    if (accountHolderName.isEmpty) {
      state = AsyncError(
        Exception('Account holder name cannot be empty'),
        StackTrace.current,
      );
      return;
    }

    final sellerId = ref.read(currentSellerIdProvider);

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
          accountId: accountId,
          accountNumber: accountNumber,
          ifscCode: ifscCode,
          accountHolderName: accountHolderName,
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
}
