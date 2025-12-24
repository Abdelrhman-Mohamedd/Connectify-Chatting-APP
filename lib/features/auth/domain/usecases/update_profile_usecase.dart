import 'package:fpdart/fpdart.dart';
import 'package:flutter_messaging_app/core/errors/failures.dart';
import 'package:flutter_messaging_app/core/usecases/usecase.dart';
import 'package:flutter_messaging_app/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_messaging_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:equatable/equatable.dart';

class UpdateProfileUseCase implements UseCase<UserEntity, UpdateProfileParams> {
  final AuthRepository repository;

  UpdateProfileUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(UpdateProfileParams params) async {
    return await repository.updateProfile(name: params.name, imageFile: params.imageFile);
  }
}

class UpdateProfileParams extends Equatable {
  final String? name;
  final dynamic imageFile;

  const UpdateProfileParams({this.name, this.imageFile});

  @override
  List<Object?> get props => [name, imageFile];
}
