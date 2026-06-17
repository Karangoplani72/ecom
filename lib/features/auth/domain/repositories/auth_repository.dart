import 'package:fpdart/fpdart.dart';
import 'package:ecom/features/auth/domain/entities/app_user.dart';

abstract interface class AuthRepository {
  Stream<Option<AppUser>> get authStateChanges;

  Future<Either<String, AppUser>> signInWithEmailAndPassword(
      String email,
      String password,
      );

  Future<Either<String, AppUser>> signUpWithEmailAndPassword(
      String email,
      String password,
      String displayName,
      );

  Future<Either<String, AppUser>> getCurrentUserSession();

  Future<Either<String, Unit>> signOut();
}