// lib/features/seller/domain/repositories/seller_application_repository.dart

import 'package:fpdart/fpdart.dart';

import '../entities/seller_application.dart';

abstract interface class SellerApplicationRepository {
  Future<Either<String, Unit>> submitApplication(SellerApplication application);
}
