import 'package:fpdart/fpdart.dart';
import 'package:flutter_messaging_app/core/errors/failures.dart';
import 'package:flutter_messaging_app/core/usecases/usecase.dart';
import 'package:flutter_messaging_app/features/auth/domain/repositories/auth_repository.dart';

class ResetPasswordUseCase implements UseCase<void, String> {
  final AuthRepository repository;

  ResetPasswordUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String email) async {
    return await repository.resetPassword(email);
  }
}
