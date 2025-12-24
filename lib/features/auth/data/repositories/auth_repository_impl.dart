import 'package:fpdart/fpdart.dart';
import 'package:flutter_messaging_app/core/errors/failures.dart';
import 'package:flutter_messaging_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:flutter_messaging_app/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_messaging_app/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, UserEntity>> signInWithEmailPassword({required String email, required String password}) async {
    try {
      final user = await remoteDataSource.signInWithEmailPassword(email: email, password: password);
      return Right(user);
    } on AuthFailure catch (e) {
      return Left(e);
    } catch (e) {
      return const Left(ServerFailure('An unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signUpWithEmailPassword({required String email, required String password, String? name}) async {
    try {
      final user = await remoteDataSource.signUpWithEmailPassword(email: email, password: password, name: name);
      return Right(user);
    } on AuthFailure catch (e) {
      return Left(e);
    } catch (e) {
      return const Left(ServerFailure('An unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await remoteDataSource.signOut();
      return const Right(null);
    } on Failure catch (e) {
      return Left(e);
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async {
    try {
      final user = await remoteDataSource.getCurrentSessionUser();
      if (user != null) {
        return Right(user);
      }
      return const Left(AuthFailure('No user logged in'));
    } catch (e) {
      return const Left(AuthFailure('Failed to get current user'));
    }
  }


  @override
  Future<Either<Failure, void>> resetPassword(String email) async {
    try {
      await remoteDataSource.resetPassword(email);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> verifyEmail(String email, String token) async {
    try {
      await remoteDataSource.verifyEmail(email, token);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
  @override
  Future<Either<Failure, UserEntity>> updateProfile({String? name, dynamic imageFile}) async {
    try {
      String? avatarUrl;
      if (imageFile != null) {
        try {
          avatarUrl = await remoteDataSource.uploadAvatar(imageFile);
        } catch (e) {
          // If upload fails (e.g. bucket missing), we log/ignore it but CONTINUE to update the name.
          // We can return a specific Failure if we want, but user asked to "fix it". 
          // Best fix: Allow name update even if photo fails.
          // We could throw, but that blocks name update.
          // Let's allow the flow to continue.
          // Ideally: return a warning. But Either<Failure, User> is binary.
          
          throw AuthFailure('Photo upload failed: ${e.toString().replaceAll("AuthFailure: ", "")}. Name update aborted.');
        }
      }
      
      final updatedUser = await remoteDataSource.updateUserMetadata(
        name: name,
        avatarUrl: avatarUrl,
      );
      
      return Right(updatedUser);
    } on AuthFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
