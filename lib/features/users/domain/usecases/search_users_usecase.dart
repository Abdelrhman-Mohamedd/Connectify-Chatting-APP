import 'package:fpdart/fpdart.dart';
import 'package:flutter_messaging_app/core/errors/failures.dart';
import 'package:flutter_messaging_app/core/usecases/usecase.dart';
import 'package:flutter_messaging_app/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_messaging_app/features/auth/domain/repositories/auth_repository.dart';

// Since we don't have a dedicated UserRepository yet, using AuthRepository or creating one.
// Let's create a quick abstraction for searching users.
// Actually, let's just add searching to AuthRepository for simplicity or create UserRepo.
// Creating a separate UserRepo is cleaner.

abstract class UserRepository {
  Future<Either<Failure, List<UserEntity>>> searchUsers(String query);
}

class SearchUsersUseCase implements UseCase<List<UserEntity>, String> {
  final UserRepository repository;

  SearchUsersUseCase(this.repository);

  @override
  Future<Either<Failure, List<UserEntity>>> call(String query) async {
    return await repository.searchUsers(query);
  }
}
