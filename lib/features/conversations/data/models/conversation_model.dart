import 'package:flutter_messaging_app/features/conversations/domain/entities/conversation.dart';
import 'package:flutter_messaging_app/features/auth/data/models/user_model.dart';
import 'package:flutter_messaging_app/features/auth/domain/entities/user_entity.dart';

class ConversationModel extends Conversation {
  const ConversationModel({
    required super.id,
    super.lastMessage,
    super.lastMessageAt,
    super.lastMessageSenderId,
    super.lastMessageIsRead = false,
    super.participants = const [],
    super.unreadCount = 0,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    // Handling nested participants from Supabase query
    // Structure: conversations -> conversation_participants -> profiles
    
    // Note: This parsing logic depends heavily on the Supabase query structure.
    // We assume a query that joins 'conversation_participants' and 'profiles'.
    
    final participantsData = json['conversation_participants'] as List<dynamic>? ?? [];
    final participantsList = participantsData.map((e) {
      final profile = e['profiles'] as Map<String, dynamic>;
      // Map profile fields to UserModel structure if needed or directly create UserModel
      // Assuming 'profiles' table matches UserModel.fromJson expectations (id, email, name, avatar_url)
      // Usually profile might not have email public, so check your RLS/Schema.
      // For now we assume we get minimal profile info.
      return UserModel(
        id: profile['id'],
        email: profile['email'] ?? '', 
        name: profile['name'],
        avatarUrl: profile['avatar_url'],
      );
    }).toList();

    return ConversationModel(
      id: json['id'],
      lastMessage: json['last_message'],
      lastMessageAt: json['last_message_at'] != null 
          ? DateTime.tryParse(json['last_message_at']) 
          : null,
      lastMessageSenderId: json['last_message_sender_id'],
      lastMessageIsRead: json['last_message_is_read'] ?? false,
      participants: participantsList,
      unreadCount: json['unread_count'] ?? 0, 
    );
  }

  ConversationModel copyWith({
    String? id,
    String? lastMessage,
    DateTime? lastMessageAt,
    String? lastMessageSenderId,
    bool? lastMessageIsRead,
    List<UserEntity>? participants,
    int? unreadCount,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      lastMessageIsRead: lastMessageIsRead ?? this.lastMessageIsRead,
      participants: participants ?? this.participants,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}
