import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fpdart/fpdart.dart';

import '../../data/dtos/merchant_wallet_dto.dart';
import '../../data/dtos/seller_transaction_dto.dart';
import '../../domain/entities/merchant_wallet.dart';
import '../../domain/entities/seller_transaction.dart';
import '../../domain/repositories/seller_finance_repository.dart';

class SellerFinanceRepositoryImpl implements SellerFinanceRepository {
  final FirebaseFirestore _firestore;
  static const String _walletsCollection = 'wallets';
  static const String _transactionsCollection = 'transactions';
  static const String _payoutsCollection = 'payouts';
  static const String _bankAccountsCollection = 'bankAccounts';

  SellerFinanceRepositoryImpl({required this._firestore});

  @override
  Future<Either<Exception, MerchantWallet>> getMerchantWallet({
    required String sellerId,
  }) async {
    try {
      if (sellerId.isEmpty) {
        return Left(Exception('Invalid seller ID: seller ID cannot be empty'));
      }

      final doc = await _firestore
          .collection(_walletsCollection)
          .doc(sellerId)
          .get();

      if (!doc.exists) {
        return Right(MerchantWallet.empty(storeId: sellerId));
      }

      final wallet = MerchantWalletDto.fromFirestore(doc).toDomain();
      return Right(wallet);
    } on FirebaseException catch (e) {
      return Left(Exception('Firestore error: ${e.message}'));
    } catch (e) {
      return Left(Exception('Failed to get merchant wallet: $e'));
    }
  }

  @override
  Future<Either<Exception, List<SellerTransaction>>> getTransactions({
    required String sellerId,
    int limit = 50,
  }) async {
    try {
      if (sellerId.isEmpty) {
        return Left(Exception('Invalid seller ID: seller ID cannot be empty'));
      }

      if (limit <= 0) {
        return Left(Exception('Invalid limit: limit must be greater than 0'));
      }

      final snapshot = await _firestore
          .collection(_transactionsCollection)
          .where('storeId', isEqualTo: sellerId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      final transactions = snapshot.docs
          .map((doc) => SellerTransactionDto.fromFirestore(doc).toDomain())
          .toList();

      return Right(transactions);
    } on FirebaseException catch (e) {
      return Left(Exception('Firestore error: ${e.message}'));
    } catch (e) {
      return Left(Exception('Failed to get transactions: $e'));
    }
  }

  @override
  Future<Either<Exception, List<SellerTransaction>>> getTransactionsByType({
    required String sellerId,
    required String type,
  }) async {
    try {
      if (sellerId.isEmpty) {
        return Left(Exception('Invalid seller ID: seller ID cannot be empty'));
      }

      if (type.isEmpty) {
        return Left(Exception('Invalid type: type cannot be empty'));
      }

      final snapshot = await _firestore
          .collection(_transactionsCollection)
          .where('storeId', isEqualTo: sellerId)
          .where('type', isEqualTo: type)
          .orderBy('createdAt', descending: true)
          .get();

      final transactions = snapshot.docs
          .map((doc) => SellerTransactionDto.fromFirestore(doc).toDomain())
          .toList();

      return Right(transactions);
    } on FirebaseException catch (e) {
      return Left(Exception('Firestore error: ${e.message}'));
    } catch (e) {
      return Left(Exception('Failed to get transactions by type: $e'));
    }
  }

  @override
  Future<Either<Exception, List<SellerTransaction>>>
  getTransactionsByDateRange({
    required String sellerId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      if (sellerId.isEmpty) {
        return Left(Exception('Invalid seller ID: seller ID cannot be empty'));
      }

      if (startDate.isAfter(endDate)) {
        return Left(
          Exception('Invalid date range: start date must be before end date'),
        );
      }

      final snapshot = await _firestore
          .collection(_transactionsCollection)
          .where('storeId', isEqualTo: sellerId)
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('createdAt', descending: true)
          .get();

      final transactions = snapshot.docs
          .map((doc) => SellerTransactionDto.fromFirestore(doc).toDomain())
          .toList();

      return Right(transactions);
    } on FirebaseException catch (e) {
      return Left(Exception('Firestore error: ${e.message}'));
    } catch (e) {
      return Left(Exception('Failed to get transactions by date range: $e'));
    }
  }

  @override
  Future<Either<Exception, Unit>> requestPayout({
    required String sellerId,
    required double amount,
    required String bankAccountId,
  }) async {
    try {
      if (sellerId.isEmpty) {
        return Left(Exception('Invalid seller ID: seller ID cannot be empty'));
      }

      if (amount <= 0) {
        return Left(Exception('Invalid amount: amount must be greater than 0'));
      }

      if (bankAccountId.isEmpty) {
        return Left(
          Exception('Invalid bank account ID: bank account ID cannot be empty'),
        );
      }

      final walletResult = await getMerchantWallet(sellerId: sellerId);

      final wallet = walletResult.fold((error) => throw error, (w) => w);

      if (wallet.availableBalance < amount) {
        return Left(
          Exception(
            'Insufficient balance: available balance is less than requested amount',
          ),
        );
      }

      final payoutId = _firestore.collection(_payoutsCollection).doc().id;

      await _firestore.collection(_payoutsCollection).doc(payoutId).set({
        'id': payoutId,
        'storeId': sellerId,
        'bankAccountId': bankAccountId,
        'amount': amount,
        'currency': wallet.currency,
        'status': 'pending',
        'requestedAt': FieldValue.serverTimestamp(),
        'processedAt': null,
      });

      return const Right(unit);
    } on FirebaseException catch (e) {
      return Left(Exception('Firestore error: ${e.message}'));
    } catch (e) {
      return Left(Exception('Failed to request payout: $e'));
    }
  }

  @override
  Future<Either<Exception, Unit>> updateBankAccount({
    required String sellerId,
    required String accountId,
    required String bankName,
    required String accountNumber,
    required String ifscCode,
    required String accountHolderName,
  }) async {
    try {
      if (sellerId.isEmpty) {
        return Left(Exception('Invalid seller ID: seller ID cannot be empty'));
      }

      if (bankName.isEmpty) {
        return Left(
          Exception('Invalid bank name: bank name cannot be empty'),
        );
      }

      if (accountNumber.isEmpty) {
        return Left(
          Exception('Invalid account number: account number cannot be empty'),
        );
      }

      if (ifscCode.isEmpty) {
        return Left(Exception('Invalid IFSC code: IFSC code cannot be empty'));
      }

      if (accountHolderName.isEmpty) {
        return Left(
          Exception(
            'Invalid account holder name: account holder name cannot be empty',
          ),
        );
      }

      // Write to bankAccounts collection
      await _firestore.collection(_bankAccountsCollection).doc(accountId).set({
        'id': accountId,
        'storeId': sellerId,
        'bankName': bankName,
        'accountNumber': accountNumber,
        'ifscCode': ifscCode,
        'accountHolderName': accountHolderName,
        'isVerified': false,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Also update the store profile document
      await _firestore.collection('stores').doc(sellerId).set({
        'bankName': bankName,
        'accountNumber': accountNumber,
        'ifscCode': ifscCode,
        'accountHolderName': accountHolderName,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return const Right(unit);
    } on FirebaseException catch (e) {
      return Left(Exception('Firestore error: ${e.message}'));
    } catch (e) {
      return Left(Exception('Failed to update bank account: $e'));
    }
  }

  @override
  Future<Either<Exception, Map<String, dynamic>>> getPayoutStatus({
    required String sellerId,
    required String payoutId,
  }) async {
    try {
      if (sellerId.isEmpty) {
        return Left(Exception('Invalid seller ID: seller ID cannot be empty'));
      }

      if (payoutId.isEmpty) {
        return Left(Exception('Invalid payout ID: payout ID cannot be empty'));
      }

      final doc = await _firestore
          .collection(_payoutsCollection)
          .doc(payoutId)
          .get();

      if (!doc.exists) {
        return Left(Exception('Payout not found: $payoutId'));
      }

      final data = doc.data() ?? {};

      if (data['storeId'] != sellerId) {
        return Left(
          Exception('Unauthorized: payout does not belong to this seller'),
        );
      }

      return Right({
        'id': payoutId,
        'status': data['status'] ?? 'pending',
        'amount': data['amount'] ?? 0,
        'currency': data['currency'] ?? 'INR',
        'requestedAt': data['requestedAt'],
        'processedAt': data['processedAt'],
        'failureReason': data['failureReason'],
      });
    } on FirebaseException catch (e) {
      return Left(Exception('Firestore error: ${e.message}'));
    } catch (e) {
      return Left(Exception('Failed to get payout status: $e'));
    }
  }
}
