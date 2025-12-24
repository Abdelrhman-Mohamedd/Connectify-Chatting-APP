import 'package:fpdart/fpdart.dart';
import 'package:flutter_messaging_app/core/errors/failures.dart';
import 'package:flutter_messaging_app/core/usecases/usecase.dart';
import 'package:flutter_messaging_app/features/auth/domain/repositories/auth_repository.dart';

class VerifyEmailParams {
  final String email;
  final String token;

  VerifyEmailParams({required this.email, required this.token});
}

class VerifyEmailUseCase implements UseCase<void, VerifyEmailParams> {
  final AuthRepository repository;

  VerifyEmailUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(VerifyEmailParams params) async {
    return await repository.verifyEmail(params.email, params.token);
  }
}
