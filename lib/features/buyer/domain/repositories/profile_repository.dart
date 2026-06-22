import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';

abstract class ProfileRepository {
  Future<Either<Failure, String>> uploadProfileImage({
    required Uint8List bytes,
    required String fileName,
  });
}
