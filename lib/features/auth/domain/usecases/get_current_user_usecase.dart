import 'package:fpdart/fpdart.dart';
import 'package:flutter_messaging_app/core/errors/failures.dart';
import 'package:flutter_messaging_app/core/usecases/usecase.dart';
import 'package:flutter_messaging_app/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_messaging_app/features/auth/domain/repositories/auth_repository.dart';

class GetCurrentUserUseCase implements UseCase<UserEntity, NoParams> {
  final AuthRepository repository;

  GetCurrentUserUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(NoParams params) async {
    return await repository.getCurrentUser();
  }
}
