import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_messaging_app/core/config/constants/app_constants.dart';
import 'package:flutter_messaging_app/core/errors/failures.dart';
import 'package:flutter_messaging_app/features/messaging/data/models/message_model.dart';
import 'dart:developer';

abstract class MessagingRemoteDataSource {
  Stream<List<MessageModel>> getMessagesStream(String conversationId);
  Future<List<MessageModel>> getMessages(String conversationId);
  Future<MessageModel> sendMessage({required String conversationId, required String content});
  Future<void> markMessagesAsRead(String conversationId);
  Future<void> deleteMessage(String messageId);
}

class MessagingRemoteDataSourceImpl implements MessagingRemoteDataSource {
  final SupabaseClient supabaseClient;

  MessagingRemoteDataSourceImpl(this.supabaseClient);

  @override
  Stream<List<MessageModel>> getMessagesStream(String conversationId) {
    return supabaseClient
        .from(AppConstants.messagesTable)
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: false) // Newest first for reverse: true
        .map((List<Map<String, dynamic>> data) {
          return data.map((json) => MessageModel.fromJson(json)).toList();
        });
  }

  @override
  Future<List<MessageModel>> getMessages(String conversationId) async {
    try {
      final response = await supabaseClient
          .from(AppConstants.messagesTable)
          .select()
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: false); // Newest first
      
      return (response as List).map((json) => MessageModel.fromJson(json)).toList();
    } catch (e) {
      throw const ServerFailure('Failed to fetch messages');
    }
  }

  @override
  Future<MessageModel> sendMessage({required String conversationId, required String content}) async {
    try {
      final user = supabaseClient.auth.currentUser;
      if (user == null) throw const AuthFailure('User not authenticated');

      // 1. Insert Message
      final message = await supabaseClient
          .from(AppConstants.messagesTable)
          .insert({
            'conversation_id': conversationId,
            'sender_id': user.id,
            'content': content,
          })
          .select()
          .single();

      // 2. Update Conversation (last_message, last_message_at) - REMOVED (Handled by DB Trigger [FIX 6])
      /*
      await supabaseClient
          .from(AppConstants.conversationsTable)
          .update({
            'last_message': content,
            'last_message_at': DateTime.now().toIso8601String(),
          })
          .eq('id', conversationId);
      */
      
      return MessageModel.fromJson(message);
    } catch (e) {
      throw ServerFailure('Failed to send message: $e');
    }
  }
  @override
  Future<void> markMessagesAsRead(String conversationId) async {
    try {
      final userId = supabaseClient.auth.currentUser!.id;
      
      // Update messages where conversation_id matches AND sender is NOT me (others messages)
      // AND is_read is false
      await supabaseClient
          .from(AppConstants.messagesTable)
          .update({'is_read': true})
          .eq('conversation_id', conversationId)
          .neq('sender_id', userId)
          .eq('is_read', false);
          
    } catch (e) {
      // Log error but don't crash app flow usually
      log('MarkAsRead Error: $e');
    }
  }

  @override
  Future<void> deleteMessage(String messageId) async {
    try {
      final List response = await supabaseClient
          .from(AppConstants.messagesTable)
          .delete()
          .eq('id', messageId)
          .select();
      
      if (response.isEmpty) {
        throw const ServerFailure('Message deletion failed. Check network or permissions.'); 
      }
    } catch (e) {
      if (e is ServerFailure) rethrow; // Pass specific errors
      throw const ServerFailure('Failed to delete message');
    }
  }
}
