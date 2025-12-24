import 'package:fpdart/fpdart.dart';
import 'package:flutter_messaging_app/core/errors/failures.dart';

abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

class NoParams {
  const NoParams();
}
