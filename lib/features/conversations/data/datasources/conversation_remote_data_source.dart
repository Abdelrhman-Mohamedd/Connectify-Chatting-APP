import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rxdart/rxdart.dart';
import 'dart:async'; // For StreamController
import 'package:flutter_messaging_app/core/config/constants/app_constants.dart';
import 'package:flutter_messaging_app/core/errors/failures.dart';
import 'package:flutter_messaging_app/features/conversations/data/models/conversation_model.dart';
import 'dart:developer';

abstract class ConversationRemoteDataSource {
  Future<List<ConversationModel>> getConversations();
  Stream<List<ConversationModel>> getConversationsStream(); // New Stream Method
  Future<ConversationModel> createConversation(String otherUserId);
  Future<ConversationModel> getConversationById(String conversationId);
  Future<void> deleteConversation(String conversationId); // New
}

class ConversationRemoteDataSourceImpl implements ConversationRemoteDataSource {
  final SupabaseClient supabaseClient;

  final _refreshController = StreamController<void>.broadcast();

  ConversationRemoteDataSourceImpl(this.supabaseClient);

  @override
  Future<List<ConversationModel>> getConversations() async {
    try {
      final userId = supabaseClient.auth.currentUser!.id;
      
      // 1. Get Conversation IDs
      final participationResponse = await supabaseClient
          .from(AppConstants.conversationParticipantsTable)
          .select('conversation_id')
          .eq('user_id', userId);
      
      final conversationIds = (participationResponse as List)
          .map((e) => e['conversation_id'] as String)
          .toList();
      
      if (conversationIds.isEmpty) return [];

      // 2. Fetch Conversations
      final conversationsResponse = await supabaseClient
          .from(AppConstants.conversationsTable)
          .select()
          .inFilter('id', conversationIds)
          .order('last_message_at', ascending: false);

      // 3. Fetch ALL participants for these conversations (to get profiles AND my cleared_at status)
      final allParticipantsResponse = await supabaseClient
          .from(AppConstants.conversationParticipantsTable)
          .select('conversation_id, user_id, cleared_at') // Added cleared_at
          .inFilter('conversation_id', conversationIds);
      
      final allParticipantUserIds = (allParticipantsResponse as List)
          .map((e) => e['user_id'] as String)
          .toSet() // Deduplicate
          .toList();

      // 4. Fetch Profiles for all participants
      final profilesResponse = await supabaseClient
          .from(AppConstants.usersTable) // 'profiles'
          .select('id, name, avatar_url, email')
          .inFilter('id', allParticipantUserIds);
      
      final profilesMap = {
        for (var p in (profilesResponse as List)) 
          p['id'] as String : p
      };

      final clearedAtMap = <String, DateTime>{}; // Store cleared_at for later use

      // 5. Assemble Data
      final conversations = (conversationsResponse as List).map((convJson) {
         final convId = convJson['id'];
         
         // Find participants for this conversation
         final participantsForParams = (allParticipantsResponse as List)
            .where((p) => p['conversation_id'] == convId)
            .toList();
            
         // Find MY entry to check cleared_at
         final myEntry = participantsForParams
             .where((p) => p['user_id'] == userId)
             .firstOrNull;
             
         DateTime? clearedAt;
         if (myEntry != null && myEntry['cleared_at'] != null) {
            clearedAt = DateTime.parse(myEntry['cleared_at']);
            clearedAtMap[convId] = clearedAt;
         }

         // Map to profiles
         final participantsData = participantsForParams.map((p) {
            final pid = p['user_id'];
            final profileData = profilesMap[pid] ?? {'id': pid, 'name': 'Unknown', 'email': '', 'avatar_url': null};
            // Match the structure expected by ConversationModel.fromJson (nested profiles)
            return {'profiles': profileData};
         }).toList();

         final conversationJson = Map<String, dynamic>.from(convJson);
         conversationJson['conversation_participants'] = participantsData;
         
         // ADJUST LAST MESSAGE based on cleared_at
         if (clearedAt != null) {
             final lastMsgAtStr = conversationJson['last_message_at'];
             if (lastMsgAtStr != null) {
                final lastMsgAt = DateTime.parse(lastMsgAtStr);
                if (lastMsgAt.isBefore(clearedAt)) {
                    conversationJson['last_message'] = ''; // Empty
                }
             }
         }
         
         return ConversationModel.fromJson(conversationJson);
      }).toList();

      print('GetConversations: Raw count: ${conversations.length}');
      
      // 6. Fetch Unread Counts
      // Efficiently fetch all unread messages for this user (where sender != me)
      final unreadResponse = await supabaseClient
          .from(AppConstants.messagesTable)
          .select('conversation_id, created_at') // Added created_at to filter
          .eq('is_read', false)
          .neq('sender_id', userId);
          
      final unreadCounts = <String, int>{};
      for (var msg in (unreadResponse as List)) {
        final cid = msg['conversation_id'] as String;
        
        // Filter out cleared messages from count
        final msgTime = DateTime.parse(msg['created_at']);
        final loopClearedAt = clearedAtMap[cid];
        if (loopClearedAt != null && msgTime.isBefore(loopClearedAt)) {
            continue; 
        }

        unreadCounts[cid] = (unreadCounts[cid] ?? 0) + 1;
      }

      // DEDUPLICATION LOGIC (Fix for duplicate chats issue)
      final uniqueConversations = <String, ConversationModel>{};
      
      for (var conversation in conversations) {
        // Update with Unread Count
        final count = unreadCounts[conversation.id] ?? 0;
        final updatedConversation = conversation.copyWith(unreadCount: count);

        // Find the OTHER participant's ID to use as key
        final otherParticipantId = updatedConversation.participants
            .where((p) => p.id != userId)
            .firstOrNull
            ?.id;
        
        if (otherParticipantId != null) {
          // If we already have a conversation with this user, only replace it if this one is NEWER
          if (uniqueConversations.containsKey(otherParticipantId)) {
            final existing = uniqueConversations[otherParticipantId]!;
            final currentMsgAt = updatedConversation.lastMessageAt;
            final existingMsgAt = existing.lastMessageAt;
            
            // Prefer newer
            if (currentMsgAt != null && (existingMsgAt == null || currentMsgAt.isAfter(existingMsgAt))) {
               uniqueConversations[otherParticipantId] = updatedConversation;
            }
          } else {
             uniqueConversations[otherParticipantId] = updatedConversation;
          }
        } else {
          // uniqueConversations['SELF_${conversation.id}'] = conversation; 
        }
      }
      
      return uniqueConversations.values.toList();
      
    } catch (e) {
      log('GetConversations Error: $e');
      throw const ServerFailure('Failed to load conversations');
    }
  }

  @override
  Stream<List<ConversationModel>> getConversationsStream() {
    // 1. Stream from 'conversations' table
    final conversationStream = supabaseClient
        .from(AppConstants.conversationsTable)
        .stream(primaryKey: ['id']);

    // 2. Stream from 'messages' table 
    final messageStream = supabaseClient
        .from(AppConstants.messagesTable)
        .stream(primaryKey: ['id']);

    // 3. Listen to 'conversation_participants' changes 
    final participantEvents = supabaseClient.channel('public:conversation_participants');
    
    participantEvents.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: AppConstants.conversationParticipantsTable,
      callback: (payload) {
        // Trigger generic refresh
        _refreshController.add(null); 
      },
    ).subscribe();

    return Rx.merge([
      conversationStream, 
      messageStream, 
      _refreshController.stream, // Listen to manual/other triggers
    ]).asyncMap((event) async {
          print('Realtime/Manual Update Triggered. Refreshing Conversations...');
          return await getConversations();
    });
  }

  @override
  Future<ConversationModel> createConversation(String otherUserId) async {
    try {
      final currentUserId = supabaseClient.auth.currentUser!.id;
      
      // 1. Check for EXISTING conversation between these two users (Prevent Duplicates)
      // Get all conversation IDs for current user
      final myConvosResponse = await supabaseClient
          .from(AppConstants.conversationParticipantsTable)
          .select('conversation_id')
          .eq('user_id', currentUserId);
      
      final myConvoIds = (myConvosResponse as List).map((e) => e['conversation_id']).toList();

      if (myConvoIds.isNotEmpty) {
        // Check if other user is in any of these
        final existingConvoResponse = await supabaseClient
            .from(AppConstants.conversationParticipantsTable)
            .select('conversation_id')
            .eq('user_id', otherUserId)
            .inFilter('conversation_id', myConvoIds)
            .maybeSingle(); // Returns null if not found
        
        if (existingConvoResponse != null) {
           final existingId = existingConvoResponse['conversation_id'];
           print('Found existing conversation: $existingId');
           return ConversationModel(id: existingId, participants: []); // Minimal return, or fetch full
        }
      }

      // 2. Create Conversation (If none exists)
      final conversation = await supabaseClient
          .from(AppConstants.conversationsTable)
          .insert({})
          .select()
          .single();
      
      final conversationId = conversation['id'];

      // 3. Add Participants
      await supabaseClient.from(AppConstants.conversationParticipantsTable).insert([
        {'conversation_id': conversationId, 'user_id': currentUserId},
        {'conversation_id': conversationId, 'user_id': otherUserId},
      ]);

      // 4. Return the new conversation
      // For now, construct a minimal model or re-fetch.
      // Re-fetching is safer to reuse logic.
      
      // Quick hack: return empty for now, or basic.
      // Ideally we call getConversations but filtering by ID.
      return ConversationModel(id: conversationId, participants: []); 
    } catch (e) {
      throw const ServerFailure('Failed to create conversation');
    }
  }

  @override
  Future<ConversationModel> getConversationById(String conversationId) async {
    try {
      final userId = supabaseClient.auth.currentUser!.id;

      // 1. Fetch Conversation Details
      final conversationResponse = await supabaseClient
          .from(AppConstants.conversationsTable)
          .select()
          .eq('id', conversationId)
          .single();

      // 2. Fetch Participants
      final participantsResponse = await supabaseClient
          .from(AppConstants.conversationParticipantsTable)
          .select('user_id')
          .eq('conversation_id', conversationId);

      final participantIds = (participantsResponse as List)
          .map((e) => e['user_id'] as String)
          .toList();

      // 3. Fetch Profiles
      final profilesResponse = await supabaseClient
          .from(AppConstants.usersTable)
          .select('id, name, avatar_url, email')
          .inFilter('id', participantIds);

      final profilesMap = {
        for (var p in (profilesResponse as List))
          p['id'] as String : p
      };

      // 4. Assemble Participants Data
      final participantsData = participantIds.map((pid) {
        final profileData = profilesMap[pid] ?? {'id': pid, 'name': 'Unknown', 'email': '', 'avatar_url': null};
        return {'profiles': profileData}; // Structure for Model
      }).toList();

      final conversationJson = Map<String, dynamic>.from(conversationResponse);
      conversationJson['conversation_participants'] = participantsData;

      // Unread count (optional for this view, but good for consistency)
      // For now, defaulting to 0 as we usually open the chat to read messages.
      
      return ConversationModel.fromJson(conversationJson);
    } catch (e) {
      log('GetConversationById Error: $e');
      throw const ServerFailure('Failed to load conversation details');
    }
  }

  @override
  Future<void> deleteConversation(String conversationId) async {
    try {
      final userId = supabaseClient.auth.currentUser!.id;
      await supabaseClient
          .from(AppConstants.conversationParticipantsTable)
          .update({
            'cleared_at': DateTime.now().toIso8601String(),
          })
          .match({
            'conversation_id': conversationId,
            'user_id': userId,
          });
          
      // Force local refresh immediately
      _refreshController.add(null);
      
    } catch (e) {
      log('DeleteConversation (Soft) Error: $e');
      throw const ServerFailure('Failed to clear conversation history');
    }
  }
}
