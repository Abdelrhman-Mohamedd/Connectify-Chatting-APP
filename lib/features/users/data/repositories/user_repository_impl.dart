import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_messaging_app/core/errors/failures.dart';
import 'package:flutter_messaging_app/features/auth/data/models/user_model.dart';
import 'package:flutter_messaging_app/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_messaging_app/features/users/domain/usecases/search_users_usecase.dart';

class UserRepositoryImpl implements UserRepository {
  final SupabaseClient supabaseClient;

  UserRepositoryImpl(this.supabaseClient);

  @override
  Future<Either<Failure, List<UserEntity>>> searchUsers(String query) async {
    try {
      // DEBUG LOG
      print('Searching users with query: $query');
      
      final response = await supabaseClient
          .from('profiles')
          .select()
          .ilike('email', '%$query%') // Searching by email for now
          .neq('id', supabaseClient.auth.currentUser!.id); // Don't show myself
      
      // DEBUG LOG
      print('Search response: $response');

      final users = (response as List).map((e) => UserModel(
        id: e['id'],
        email: e['email'] ?? '',
        name: e['name'] ?? 'Unknown',
        avatarUrl: e['avatar_url'],
      )).toList();

      return Right(users);
    } catch (e) {
      print('Search error: $e');
      return Left(ServerFailure(e.toString()));
    }
  }
}
