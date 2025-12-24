import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

class PresenceService {
  final SupabaseClient supabaseClient;
  RealtimeChannel? _systemChannel;
  final _onlineUsersController = StreamController<Set<String>>.broadcast();

  PresenceService(this.supabaseClient);

  Stream<Set<String>> get onlineUsersStream => _onlineUsersController.stream;
  Set<String> _currentOnlineUsers = {};

  Future<void> initialize() async {
    final userId = supabaseClient.auth.currentUser?.id;
    if (userId == null) return;

    // Join a global channel for presence
    // Join a global channel for presence
    _systemChannel = supabaseClient.channel('system:online_users');

    _systemChannel?.onPresenceSync((payload) {
      final state = (_systemChannel?.presenceState() ?? {}) as Map;
      
      // Extract user IDs from presence state
      final onlineUserIds = <String>{};
      state.forEach((key, presences) {
        for (var presence in presences) {
          if (presence.payload['user_id'] != null) { // Note: 'payload' property on Presence
             onlineUserIds.add(presence.payload['user_id'] as String);
          } else if (presence.payload is Map && presence.payload['user_id'] != null) {
              onlineUserIds.add(presence.payload['user_id'] as String);
          }
        }
      });
      
      _currentOnlineUsers = onlineUserIds;
      _onlineUsersController.add(_currentOnlineUsers);
      print('Presence Sync: Online users: $_currentOnlineUsers');
    });

    _systemChannel?.onPresenceJoin((payload) {
       print('Presence Join: ${payload.newPresences}');
    });
    
    _systemChannel?.onPresenceLeave((payload) {
       print('Presence Leave: ${payload.leftPresences}');
    });

    await _systemChannel?.subscribe((status, [error]) async {
      if (status == RealtimeSubscribeStatus.subscribed) {
        await _systemChannel?.track({'user_id': userId, 'online_at': DateTime.now().toIso8601String()});
      }
    });
  }

  void dispose() {
    _systemChannel?.unsubscribe();
    _onlineUsersController.close();
  }
}
