import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'supabase_service.dart';
import '../local_db/local_chat_store.dart';

/// Google Drive backup/restore (WhatsApp-like).
///
/// Design:
/// - Messages live in Supabase.
/// - Media lives on the device; Supabase Storage is used as a transfer layer.
/// - Backups store:
///   - A JSON snapshot of all messages visible to the user (for portability)
///   - The local media cache directory (so deleted transfer media can be restored)
///
/// Backups are uploaded into Drive `appDataFolder` so they don't clutter the user's Drive.
class DriveBackupService {
  DriveBackupService({SupabaseService? supabaseService}) : _supabase = supabaseService ?? SupabaseService();

  final SupabaseService _supabase;

  static const _scopes = [drive.DriveApi.driveAppdataScope];

  Future<drive.DriveApi> _driveApi() async {
    final g = GoogleSignIn(scopes: _scopes);

    // Try silent first (avoids repeated prompts)
    GoogleSignInAccount? acct = await g.signInSilently();
    acct ??= await g.signIn();

    if (acct == null) throw Exception('Google sign-in cancelled');

    final headers = await acct.authHeaders;
    return drive.DriveApi(_GoogleAuthClient(headers));
  }

  Future<File> _buildBackupZip({required String userId}) async {
    final tmp = await getTemporaryDirectory();
    final out = File(p.join(tmp.path, 'cdn-netchat-backup-$userId.zip'));

    // 1) Collect all messages for the current user
    final threads = await _supabase.getChatThreads();
    final all = <Map<String, dynamic>>[];
    for (final t in threads) {
      final otherId = (t['other_user_id'] ?? t['other_id'] ?? '').toString();
      if (otherId.isEmpty) continue;
      final convo = await _supabase.fetchConversationOnce(userId, otherId);
      all.addAll(convo);
    }

    // 2) Collect cached media directory
    final docs = await getApplicationDocumentsDirectory();
    final cacheDir = Directory(p.join(docs.path, 'chat_media_cache'));

    final archive = Archive();
    final jsonBytes = utf8.encode(jsonEncode({
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'user_id': userId,
      'messages': all,
    }));
    archive.addFile(ArchiveFile('messages.json', jsonBytes.length, jsonBytes));

    if (await cacheDir.exists()) {
      await for (final ent in cacheDir.list(recursive: true, followLinks: false)) {
        if (ent is! File) continue;
        final rel = p.relative(ent.path, from: cacheDir.path);
        final bytes = await ent.readAsBytes();
        archive.addFile(ArchiveFile(p.join('media', rel), bytes.length, bytes));
      }
    }

    final zipData = ZipEncoder().encode(archive);
    if (zipData == null) throw Exception('Failed to build zip');
    await out.writeAsBytes(zipData, flush: true);
    return out;
  }

  Future<void> uploadLatestBackup({required String userId}) async {
    final api = await _driveApi();
    final zip = await _buildBackupZip(userId: userId);

    final media = drive.Media(zip.openRead(), await zip.length());
    final file = drive.File()
      ..name = 'cdn-netchat-backup-$userId.zip'
      ..parents = ['appDataFolder'];

    // Upsert by name
    final existing = await api.files.list(
      spaces: 'appDataFolder',
      q: "name='${file.name}' and trashed=false",
      $fields: 'files(id,name)',
    );

    if ((existing.files ?? []).isNotEmpty) {
      final id = existing.files!.first.id!;
      await api.files.update(file, id, uploadMedia: media);
    } else {
      await api.files.create(file, uploadMedia: media);
    }
  }

  Future<void> restoreLatestBackup({required String userId}) async {
    final api = await _driveApi();
    final name = 'cdn-netchat-backup-$userId.zip';

    final res = await api.files.list(
      spaces: 'appDataFolder',
      q: "name='$name' and trashed=false",
      $fields: 'files(id,name,modifiedTime,size)',
      orderBy: 'modifiedTime desc',
    );

    final f = (res.files ?? []).isEmpty ? null : res.files!.first;
    if (f?.id == null) throw Exception('No backup found');

    final tmp = await getTemporaryDirectory();
    final zipPath = p.join(tmp.path, name);
    final out = File(zipPath);

    final media = await api.files.get(f!.id!, downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;
    final sink = out.openWrite();
    await media.stream.pipe(sink);
    await sink.flush();
    await sink.close();

    // Unzip into app documents
    final docs = await getApplicationDocumentsDirectory();
    final cacheDir = Directory(p.join(docs.path, 'chat_media_cache'));
    if (!await cacheDir.exists()) await cacheDir.create(recursive: true);

    final bytes = await out.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    for (final file in archive) {
      if (!file.isFile) continue;
      final fn = file.name;
      if (!fn.startsWith('media/')) continue;
      final rel = fn.substring('media/'.length);
      final target = File(p.join(cacheDir.path, rel));
      await target.parent.create(recursive: true);
      await target.writeAsBytes(file.content as List<int>, flush: true);
    }
  

    // Restore messages into local Isar store
    try {
      final msgFile = archive.files.firstWhere((f) => f.isFile && f.name == 'messages.json');
      final raw = utf8.decode(msgFile.content as List<int>);
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final msgs = (decoded['messages'] as List?) ?? const [];
      final store = LocalChatStore(supabaseService: _supabase);
      await store.restoreFromBackup(ownerUserId: userId, messages: msgs);
    } catch (_) {
      // ignore
    }
  }
}

/// Minimal HTTP client wrapper using GoogleSignIn auth headers.
class _GoogleAuthClient extends http.BaseClient {
  _GoogleAuthClient(this._headers);
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }

  @override
  void close() {
    _client.close();
  }
}
