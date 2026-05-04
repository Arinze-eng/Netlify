import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase-based WebRTC signaling.
///
/// IMPORTANT: Supabase `.stream()` emits the *full* row set on each change,
/// so we must deduplicate events locally.
class SupabaseSignalingClient {
  final SupabaseClient client;
  final String selfId;

  StreamSubscription<List<Map<String, dynamic>>>? _sub;
  final Set<String> _seenSignalIds = {};

  SupabaseSignalingClient({required this.client, required this.selfId});

  Future<void> connect({required void Function(Map<String, dynamic>) onSignal}) async {
    _sub?.cancel();
    _seenSignalIds.clear();

    _sub = client
        .from('call_signals')
        .stream(primaryKey: ['id'])
        .eq('to_id', selfId)
        .order('created_at', ascending: true)
        .listen((rows) {
      for (final r in rows) {
        final m = Map<String, dynamic>.from(r);
        final id = (m['id'] ?? '').toString();
        if (id.isEmpty) continue;
        if (_seenSignalIds.contains(id)) continue;
        _seenSignalIds.add(id);
        onSignal(m);
      }
    });
  }

  Future<void> send({
    required String toId,
    required String type,
    required Map<String, dynamic> payload,
  }) async {
    await client.from('call_signals').insert({
      'from_id': selfId,
      'to_id': toId,
      'type': type,
      'payload': payload,
    });
  }

  Future<void> close() async {
    await _sub?.cancel();
    _sub = null;
    _seenSignalIds.clear();
  }
}
