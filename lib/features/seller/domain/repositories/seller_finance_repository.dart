import 'package:fpdart/fpdart.dart';

import '../entities/merchant_wallet.dart';
import '../entities/seller_transaction.dart';

abstract class SellerFinanceRepository {
  Future<Either<Exception, MerchantWallet>> getMerchantWallet({
    required String sellerId,
  });

  Future<Either<Exception, List<SellerTransaction>>> getTransactions({
    required String sellerId,
    int limit = 50,
  });

  Future<Either<Exception, List<SellerTransaction>>> getTransactionsByType({
    required String sellerId,
    required String type,
  });

  Future<Either<Exception, List<SellerTransaction>>>
  getTransactionsByDateRange({
    required String sellerId,
    required DateTime startDate,
    required DateTime endDate,
  });

  Future<Either<Exception, Unit>> requestPayout({
    required String sellerId,
    required double amount,
    required String bankAccountId,
  });

  Future<Either<Exception, Unit>> updateBankAccount({
    required String sellerId,
    required String accountId,
    required String accountNumber,
    required String ifscCode,
    required String accountHolderName,
  });

  Future<Either<Exception, Map<String, dynamic>>> getPayoutStatus({
    required String sellerId,
    required String payoutId,
  });
}
