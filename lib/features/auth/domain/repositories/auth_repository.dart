import 'package:fpdart/fpdart.dart';
import 'package:flutter_messaging_app/core/errors/failures.dart';
import 'package:flutter_messaging_app/features/auth/domain/entities/user_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> signInWithEmailPassword({
    required String email,
    required String password,
  });

  Future<Either<Failure, UserEntity>> signUpWithEmailPassword({
    required String email,
    required String password,
    String? name,
  });

  Future<Either<Failure, void>> signOut();

  Future<Either<Failure, UserEntity>> getCurrentUser();
  
  Future<Either<Failure, void>> resetPassword(String email);
  Future<Either<Failure, void>> verifyEmail(String email, String token);
  Future<Either<Failure, UserEntity>> updateProfile({String? name, dynamic imageFile});
}
