import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_signaling_client.dart';
import '../services/supabase_service.dart';

class CallScreen extends StatefulWidget {
  final String selfId;
  final String peerId;
  final bool isVideo;
  final bool isCaller;

  const CallScreen({
    super.key,
    required this.selfId,
    required this.peerId,
    required this.isVideo,
    this.isCaller = true,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> with WidgetsBindingObserver {
  final _localRenderer = RTCVideoRenderer();
  final _remoteRenderer = RTCVideoRenderer();

  MediaStream? _localStream;
  RTCPeerConnection? _pc;
  late final SupabaseSignalingClient _sig;
  final SupabaseService _supabaseService = SupabaseService();

  bool _micOn = true;
  bool _camOn = true;
  bool _speakerOn = true;

  bool _connected = false;
  bool _didLogCall = false; // Prevent double-logging
  DateTime? _callStartTime;
  Timer? _callDurationTimer;
  Duration _callDuration = Duration.zero;

  // ICE candidate buffer for trickle ICE
  final List<RTCIceCandidate> _pendingCandidates = [];
  bool _remoteDescriptionSet = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sig = SupabaseSignalingClient(client: Supabase.instance.client, selfId: widget.selfId);
    _init();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app going to background during call
    if (state == AppLifecycleState.paused && _connected) {
      // Keep call running - WebRTC works in background
    }
  }

  Future<void> _init() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();

    // Ensure audio routing is correct (fix: call connected but no sound).
    // Enable speaker + make sure the local audio track isn't muted.
    try {
      await Helper.setSpeakerphoneOn(true);
    } catch (_) {}

    await _sig.connect(onSignal: (m) async {
      final fromId = (m['from_id'] ?? '').toString();
      if (fromId.isNotEmpty && fromId != widget.peerId) return;

      final type = (m['type'] ?? '').toString();
      final payload = Map<String, dynamic>.from(m['payload'] as Map);

      if (type == 'offer' || type == 'call_offer') {
        // Incoming call offer
        if (type == 'call_offer') {
          // This is just the ring signal, the actual SDP offer follows
          // But in our simplified model, call_offer also triggers CallScreen
          return;
        }
        await _ensurePeerConnection();
        await _pc!.setRemoteDescription(RTCSessionDescription(payload['sdp'] as String?, 'offer'));
        _remoteDescriptionSet = true;

        // Flush buffered ICE candidates
        await _flushPendingCandidates();

        final ans = await _pc!.createAnswer();
        await _pc!.setLocalDescription(ans);
        await _sig.send(
          toId: widget.peerId,
          type: 'answer',
          payload: {'sdp': ans.sdp},
        );
      }

      if (type == 'answer') {
        await _ensurePeerConnection();
        await _pc?.setRemoteDescription(RTCSessionDescription(payload['sdp'] as String?, 'answer'));
        _remoteDescriptionSet = true;

        // Flush buffered ICE candidates
        await _flushPendingCandidates();

        _onCallConnected();
      }

      if (type == 'ice') {
        final c = Map<String, dynamic>.from(payload['candidate'] as Map);
        final candidate = RTCIceCandidate(c['candidate'], c['sdpMid'], c['sdpMLineIndex']);

        if (_remoteDescriptionSet) {
          await _pc?.addCandidate(candidate);
        } else {
          // Buffer until remote description is set
          _pendingCandidates.add(candidate);
        }
      }

      if (type == 'hangup') {
        _onRemoteHangup();
      }
    });

    if (widget.isCaller) {
      await _startAsCaller();
    }
  }

  Future<void> _flushPendingCandidates() async {
    for (final c in _pendingCandidates) {
      await _pc?.addCandidate(c);
    }
    _pendingCandidates.clear();
  }

  void _onCallConnected() {
    if (_connected) return;
    setState(() => _connected = true);
    _callStartTime = DateTime.now();
    _callDurationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_callStartTime != null && mounted) {
        setState(() {
          _callDuration = DateTime.now().difference(_callStartTime!);
        });
      }
    });
  }

  void _onRemoteHangup() {
    if (!mounted) return;
    _logAndPop();
  }

  Future<void> _ensurePeerConnection() async {
    if (_pc != null) return;

    final config = {
      // Fix audio on more devices by forcing unified-plan.
      'sdpSemantics': 'unified-plan',
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {'urls': 'stun:stun1.l.google.com:19302'},
        {'urls': 'stun:stun2.l.google.com:19302'},
        {'urls': 'stun:stun3.l.google.com:19302'},
        {'urls': 'stun:stun4.l.google.com:19302'},
      ]
    };

    _pc = await createPeerConnection(config);

    _pc!.onIceCandidate = (c) {
      if (c.candidate == null) return;
      _sig.send(
        toId: widget.peerId,
        type: 'ice',
        payload: {
          'candidate': {
            'candidate': c.candidate,
            'sdpMid': c.sdpMid,
            'sdpMLineIndex': c.sdpMLineIndex,
          }
        },
      );
    };

    // Unified-plan
    _pc!.onTrack = (e) {
      if (e.streams.isNotEmpty) {
        _remoteRenderer.srcObject = e.streams.first;
        _onCallConnected();
        setState(() {});
      }
    };

    // Plan-B fallback (some devices/older builds)
    _pc!.onAddStream = (stream) {
      _remoteRenderer.srcObject = stream;
      _onCallConnected();
      if (mounted) setState(() {});
    };

    _pc!.onConnectionState = (state) {
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        _onCallConnected();
      }
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        if (mounted) _logAndPop();
      }
    };

    _localStream ??= await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': widget.isVideo
          ? {
              'mandatory': {
                'minWidth': '640',
                'minHeight': '480',
                'minFrameRate': '30',
              },
              'optional': [],
            }
          : false,
    });

    // Ensure audio track is not muted on some devices.
    try {
      for (final at in _localStream!.getAudioTracks()) {
        await Helper.setMicrophoneMute(false, at);
      }
    } catch (_) {}

    for (final t in _localStream!.getTracks()) {
      await _pc!.addTrack(t, _localStream!);
    }

    if (widget.isVideo) {
      _localRenderer.srcObject = _localStream;
    }

    setState(() {});
  }

  Future<void> _startAsCaller() async {
    await _ensurePeerConnection();
    final offer = await _pc!.createOffer({
      'offerToReceiveAudio': true,
      'offerToReceiveVideo': widget.isVideo,
    });
    await _pc!.setLocalDescription(offer);
    await _sig.send(
      toId: widget.peerId,
      type: 'offer',
      payload: {'sdp': offer.sdp},
    );
  }

  Future<void> _hangUp() async {
    // Send hangup signal
    try {
      await _sig.send(
        toId: widget.peerId,
        type: 'hangup',
        payload: {'reason': 'user_hangup'},
      );
    } catch (_) {}

    _logAndPop();
  }

  void _logAndPop() async {
    if (_didLogCall) {
      // Already logging, just clean up
      _callDurationTimer?.cancel();
      await _sig.close();
      await _pc?.close();
      _pc = null;
      await _localStream?.dispose();
      _localStream = null;
      await _localRenderer.dispose();
      await _remoteRenderer.dispose();
      if (mounted) Navigator.pop(context);
      return;
    }
    _didLogCall = true;

    _callDurationTimer?.cancel();

    final durationSeconds = _callDuration.inSeconds;

    if (durationSeconds > 0) {
      // Completed call
      await _supabaseService.logCompletedCall(
        callerId: widget.selfId,
        receiverId: widget.peerId,
        isVideo: widget.isVideo,
        durationSeconds: durationSeconds,
      );
    } else if (widget.isCaller) {
      // Missed call (caller hung up before anyone answered)
      await _supabaseService.logMissedCall(
        callerId: widget.selfId,
        receiverId: widget.peerId,
        isVideo: widget.isVideo,
      );
    }

    // Clean up old call signals
    await _supabaseService.cleanupOldCallSignals();

    await _sig.close();
    await _pc?.close();
    _pc = null;

    await _localStream?.dispose();
    _localStream = null;

    await _localRenderer.dispose();
    await _remoteRenderer.dispose();

    if (mounted) Navigator.pop(context);
  }

  void _toggleMic() {
    _micOn = !_micOn;
    for (final t in _localStream?.getAudioTracks() ?? const []) {
      t.enabled = _micOn;
    }
    setState(() {});
  }

  void _toggleCam() {
    _camOn = !_camOn;
    for (final t in _localStream?.getVideoTracks() ?? const []) {
      t.enabled = _camOn;
    }
    setState(() {});
  }

  Future<void> _toggleSpeaker() async {
    _speakerOn = !_speakerOn;
    await Helper.setSpeakerphoneOn(_speakerOn);
    setState(() {});
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${d.inHours > 0 ? '${d.inHours}:' : ''}$m:$s';
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _callDurationTimer?.cancel();
    unawaited(_sig.close());
    unawaited(_pc?.close());
    unawaited(_localStream?.dispose());
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.isVideo ? 'Video call' : 'Voice call'),
            Text(
              _connected ? _formatDuration(_callDuration) : 'Calling...',
              style: const TextStyle(fontSize: 12, color: Colors.white54),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: widget.isVideo
                ? Stack(
                    children: [
                      Positioned.fill(
                        child: RTCVideoView(_remoteRenderer, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
                      ),
                      Positioned(
                        right: 16,
                        top: 16,
                        width: 120,
                        height: 160,
                        child: DecoratedBox(
                          decoration: BoxDecoration(border: Border.all(color: Colors.white24), borderRadius: BorderRadius.circular(12)),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: RTCVideoView(_localRenderer, mirror: true),
                          ),
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.call_rounded, color: Colors.white70, size: 86),
                        const SizedBox(height: 20),
                        Text(
                          _connected ? _formatDuration(_callDuration) : 'Calling...',
                          style: const TextStyle(color: Colors.white54, fontSize: 24),
                        ),
                      ],
                    ),
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    onPressed: _toggleMic,
                    icon: Icon(_micOn ? Icons.mic_rounded : Icons.mic_off_rounded, color: Colors.white),
                  ),
                  if (widget.isVideo)
                    IconButton(
                      onPressed: _toggleCam,
                      icon: Icon(_camOn ? Icons.videocam_rounded : Icons.videocam_off_rounded, color: Colors.white),
                    ),
                  IconButton(
                    onPressed: _toggleSpeaker,
                    icon: Icon(_speakerOn ? Icons.volume_up_rounded : Icons.hearing_disabled_rounded, color: Colors.white),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
                    onPressed: _hangUp,
                    child: const Icon(Icons.call_end_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
