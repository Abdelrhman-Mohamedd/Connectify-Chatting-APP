import 'package:flutter_messaging_app/features/auth/domain/entities/user_entity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    super.name,
    super.avatarUrl,
  });

  factory UserModel.fromSupabase(User user) {
    return UserModel(
      id: user.id,
      email: user.email ?? '',
      name: user.userMetadata?['name'] as String?,
      avatarUrl: user.userMetadata?['avatar_url'] as String?,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      avatarUrl: json['avatar_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'avatar_url': avatarUrl,
    };
  }
}
