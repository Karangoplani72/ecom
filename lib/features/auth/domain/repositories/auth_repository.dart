import 'package:fpdart/fpdart.dart';
import 'package:ecom/features/auth/domain/entities/app_user.dart';

abstract class AuthRepository {
  Stream<Option<AppUser>> get authStateChanges;
  Future<Either<String, AppUser>> signInWithEmailAndPassword(String email, String password);
  Future<Either<String, Unit>> signOut();
  Future<Either<String, AppUser>> getCurrentUserSession();
}