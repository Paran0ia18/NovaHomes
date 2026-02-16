import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'auth_service.dart';

class ProfileMediaService {
  ProfileMediaService({
    FirebaseStorage? storage,
    FirebaseAuth? auth,
    AuthService? authService,
  }) : _storageOverride = storage,
       _authOverride = auth,
       _authService = authService ?? AuthService();

  final FirebaseStorage? _storageOverride;
  final FirebaseAuth? _authOverride;
  final AuthService _authService;

  FirebaseStorage get _storage {
    if (_storageOverride != null) return _storageOverride;
    if (Firebase.apps.isEmpty) {
      throw Exception(
        'Firebase is not configured. Run flutterfire configure first.',
      );
    }
    return FirebaseStorage.instance;
  }

  FirebaseAuth get _auth {
    if (_authOverride != null) return _authOverride;
    if (Firebase.apps.isEmpty) {
      throw Exception(
        'Firebase is not configured. Run flutterfire configure first.',
      );
    }
    return FirebaseAuth.instance;
  }

  Future<String> uploadProfilePhoto(Uint8List bytes) async {
    if (bytes.isEmpty) {
      throw Exception('Selected image is empty.');
    }
    final User? user = _auth.currentUser;
    if (user == null) {
      throw Exception('User is not authenticated.');
    }

    final String fileName =
        'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final Reference ref = _storage.ref('users/${user.uid}/profile/$fileName');
    final SettableMetadata metadata = SettableMetadata(
      contentType: 'image/jpeg',
    );

    await ref.putData(bytes, metadata);
    final String url = await ref.getDownloadURL();
    await _authService.updateProfilePhotoUrl(url);
    return url;
  }

  Future<void> clearProfilePhoto() async {
    await _authService.updateProfilePhotoUrl(null);
  }
}
