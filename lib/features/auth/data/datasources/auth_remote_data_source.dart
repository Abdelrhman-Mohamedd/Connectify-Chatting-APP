import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_messaging_app/core/errors/failures.dart';
import 'package:flutter_messaging_app/features/auth/data/models/user_model.dart';
import 'package:flutter_messaging_app/core/config/constants/app_constants.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:developer';

abstract class AuthRemoteDataSource {
  Future<UserModel> signInWithEmailPassword({
    required String email,
    required String password,
  });
  Future<UserModel> signUpWithEmailPassword({
    required String email,
    required String password,
    String? name,
  });
  Future<void> signOut();
  Future<UserModel?> getCurrentSessionUser();
  Future<void> resetPassword(String email);
  Future<void> verifyEmail(String email, String token);
  Future<String> uploadAvatar(dynamic imageFile);
  Future<UserModel> updateUserMetadata({String? name, String? avatarUrl});
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient supabaseClient;

  AuthRemoteDataSourceImpl(this.supabaseClient);

  @override
  Future<UserModel> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user == null) {
        throw const AuthFailure('Sign in failed: User is null');
      }
      return UserModel.fromSupabase(response.user!);
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    } catch (e) {
      throw const AuthFailure('An unexpected error occurred during sign in');
    }
  }

  @override
  Future<UserModel> signUpWithEmailPassword({
    required String email,
    required String password,
    String? name,
  }) async {
    try {
      final response = await supabaseClient.auth.signUp(
        email: email,
        password: password,
        data: name != null ? {'name': name} : null,
        emailRedirectTo: 'io.supabase.flutter://login-callback',
      );

      if (response.user == null) {
        throw const AuthFailure('Sign up failed: User is null');
      }

      return UserModel.fromSupabase(response.user!);
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    } catch (e) {
      throw const AuthFailure('An unexpected error occurred during sign up');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await supabaseClient.auth.signOut();
    } catch (e) {
      throw const AuthFailure('Failed to sign out');
    }
  }

  @override
  Future<UserModel?> getCurrentSessionUser() async {
    try {
      final user = supabaseClient.auth.currentUser;
      if (user != null) {
        return UserModel.fromSupabase(user);
      }
      return null;
    } catch (e) {
      log(e.toString());
      return null;
    }
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      await supabaseClient.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.supabase.flutter://reset-callback',
      );
    } catch (e) {
      throw AuthFailure('Failed to send reset password email: ${e.toString()}');
    }
  }

  @override
  Future<void> verifyEmail(String email, String token) async {
    try {
      final response = await supabaseClient.auth.verifyOTP(
        type: OtpType.signup,
        token: token,
        email: email,
      );
      if (response.user == null) {
        throw const AuthFailure('Verification failed');
      }
    } catch (e) {
      throw AuthFailure('Failed to verify email: ${e.toString()}');
    }
  }

  @override
  Future<String> uploadAvatar(dynamic imageFile) async {
    try {
      final user = supabaseClient.auth.currentUser;
      if (user == null) throw const AuthFailure('User not logged in');

      // Ensure bucket exists (best effort)
      try {
        await supabaseClient.storage.getBucket('avatars');
      } catch (_) {
        try {
          await supabaseClient.storage.createBucket(
            'avatars',
            const BucketOptions(public: true),
          );
        } catch (e) {
          // If creation fails, we proceed and hopefully the bucket was created by someone else or the error is handled downstream
          // But likely it will fail at upload if we couldn't create it.
          // We log it but don't rethrow yet, let the upload fail with the specific error if needed.
        }
      }

      // Handle both XFile (from image_picker) and File (legacy)
      String fileExt = 'jpg'; // default
      Uint8List fileBytes;

      if (imageFile is XFile) {
        // Web and modern mobile - XFile
        fileExt = imageFile.name.split('.').last;
        fileBytes = Uint8List.fromList(await imageFile.readAsBytes());
      } else {
        // Legacy File support (though we're moving away from this)
        fileExt = imageFile.path.split('.').last;
        fileBytes = Uint8List.fromList(await imageFile.readAsBytes());
      }

      final fileName =
          '${user.id}/${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = fileName;

      await supabaseClient.storage
          .from('avatars')
          .uploadBinary(
            filePath,
            fileBytes,
            fileOptions: FileOptions(
              cacheControl: '3600',
              upsert: false,
              contentType: 'image/$fileExt',
            ),
          );

      final imageUrl = supabaseClient.storage
          .from('avatars')
          .getPublicUrl(filePath);
      return imageUrl;
    } catch (e) {
      if (e.toString().contains('Bucket not found')) {
        throw const AuthFailure(
          'Server Error: "avatars" bucket missing. Please create it in Supabase Dashboard.',
        );
      }
      throw AuthFailure('Failed to upload avatar: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> updateUserMetadata({
    String? name,
    String? avatarUrl,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (avatarUrl != null)
        updates['avatar_url'] = avatarUrl; // Standard Supabase metadata key

      final response = await supabaseClient.auth.updateUser(
        UserAttributes(data: updates),
      );

      // Explicitly update public profiles table to ensure sync
      try {
        final userId = supabaseClient.auth.currentUser!.id;
        final profileUpdates = {
          'id': userId,
          'updated_at': DateTime.now().toIso8601String(),
          ...updates,
        };
        // Remove keys that might not exist in profiles or are different if needed
        // But name and avatar_url are standard.

        await supabaseClient
            .from(AppConstants.usersTable)
            .upsert(profileUpdates);
      } catch (e) {
        log('Failed to sync public profile: $e');
        // Don't fail the whole operation if just the sync fails, but it's important.
      }

      if (response.user == null)
        throw const AuthFailure('Failed to update profile');
      return UserModel.fromSupabase(response.user!);
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    } catch (e) {
      throw const AuthFailure(
        'An unexpected error occurred during profile update',
      );
    }
  }
}