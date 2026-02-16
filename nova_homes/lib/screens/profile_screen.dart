import 'dart:async';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../models/app_user_profile.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/profile_media_service.dart';
import '../state/nova_homes_state.dart';
import '../theme/theme.dart';
import '../widgets/adaptive_page.dart';
import 'auth_gate_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const bool _enableStorageUploads = bool.fromEnvironment(
    'ENABLE_STORAGE_UPLOADS',
    defaultValue: false,
  );
  static const bool _enableRemoteProfileSync = bool.fromEnvironment(
    'ENABLE_PROFILE_REMOTE_SYNC',
    defaultValue: false,
  );

  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final ProfileMediaService _profileMediaService = ProfileMediaService();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isUploadingPhoto = false;
  bool _isUpdatingName = false;

  @override
  Widget build(BuildContext context) {
    final NovaHomesState state = NovaHomesScope.of(context);
    final User? user = Firebase.apps.isNotEmpty
        ? FirebaseAuth.instance.currentUser
        : null;

    return SafeArea(
      child: AdaptivePage(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 30),
          child: StreamBuilder<AppUserProfile?>(
            stream: user == null
                ? const Stream<AppUserProfile?>.empty()
                : _firestoreService.streamUserProfile(user.uid),
            builder:
                (
                  BuildContext context,
                  AsyncSnapshot<AppUserProfile?> snapshot,
                ) {
                  final AppUserProfile? profile = snapshot.data;
                  final String localNameOverride =
                      state.profileDisplayNameOverride;
                  final String localPhotoOverride =
                      state.profilePhotoUrlOverride;
                  final String displayName = localNameOverride.isNotEmpty
                      ? localNameOverride
                      : profile?.displayName.isNotEmpty == true
                      ? profile!.displayName
                      : (user?.displayName?.isNotEmpty ?? false)
                      ? user!.displayName!
                      : (user?.email ?? 'Guest');

                  final String email = profile?.email.isNotEmpty == true
                      ? profile!.email
                      : (user?.email ?? '');
                  final String photoUrl = localPhotoOverride.isNotEmpty
                      ? localPhotoOverride
                      : profile?.photoUrl.isNotEmpty == true
                      ? profile!.photoUrl
                      : (user?.photoURL ?? '');
                  final String safePhotoUrl = _safeNetworkUrl(photoUrl);

                  return Column(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Color(0xFF98A2B3),
                          ),
                          const Spacer(),
                          Text(
                            'PROFILE',
                            style: GoogleFonts.lato(
                              fontSize: 15,
                              color: const Color(0xFF667085),
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.8,
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.notifications,
                            color: Color(0xFF98A2B3),
                          ),
                        ],
                      ),
                      const SizedBox(height: 26),
                      Stack(
                        clipBehavior: Clip.none,
                        children: <Widget>[
                          Container(
                            width: 164,
                            height: 164,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFEAEAEA),
                                width: 2,
                              ),
                            ),
                            child: ClipOval(
                              child: Stack(
                                fit: StackFit.expand,
                                children: <Widget>[
                                  safePhotoUrl.isNotEmpty
                                      ? Image.network(
                                          safePhotoUrl,
                                          fit: BoxFit.cover,
                                          filterQuality: FilterQuality.low,
                                          cacheWidth: 380,
                                          errorBuilder:
                                              (_, error, stackTrace) =>
                                                  _fallbackAvatar(),
                                        )
                                      : _fallbackAvatar(),
                                  if (_isUploadingPhoto)
                                    Container(
                                      color: Colors.black.withValues(
                                        alpha: 0.35,
                                      ),
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.4,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            right: 10,
                            bottom: 6,
                            child: InkWell(
                              onTap: (_isUploadingPhoto || user == null)
                                  ? null
                                  : () => _openAvatarActions(
                                      currentPhotoUrl: safePhotoUrl,
                                      displayName: displayName,
                                    ),
                              borderRadius: BorderRadius.circular(999),
                              child: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: AppColors.accent,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                  size: 19,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Flexible(
                            child: Text(
                              displayName,
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 44,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF101828),
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: (_isUpdatingName || user == null)
                                ? null
                                : () => _editDisplayName(displayName),
                            borderRadius: BorderRadius.circular(999),
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: _isUpdatingName
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.edit_outlined,
                                      size: 18,
                                      color: Color(0xFF98A2B3),
                                    ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: GoogleFonts.lato(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF667085),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: <Widget>[
                          _statPill(
                            value: '${state.savedProperties.length}',
                            label: 'Saved',
                          ),
                          const SizedBox(width: 8),
                          _statPill(
                            value: '${state.bookings.length}',
                            label: 'Trips',
                          ),
                          const SizedBox(width: 8),
                          _statPill(
                            value: '${state.unreadInboxCount}',
                            label: 'Unread',
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      _profileOption(
                        icon: Icons.person,
                        title: 'Personal Information',
                      ),
                      _profileOption(
                        icon: Icons.lock,
                        title: 'Login & Security',
                      ),
                      _profileOption(
                        icon: Icons.credit_card,
                        title: 'Payments',
                      ),
                      _profileOption(icon: Icons.favorite, title: 'Favorites'),
                      const SizedBox(height: 40),
                      TextButton(
                        onPressed: () async {
                          await _authService.signOut();
                          if (!context.mounted) return;
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute<AuthGateScreen>(
                              builder: (_) => const AuthGateScreen(),
                            ),
                            (Route<dynamic> route) => false,
                          );
                        },
                        child: Text(
                          'Log Out',
                          style: GoogleFonts.lato(
                            fontSize: 18,
                            color: const Color(0xFF98A2B3),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'v2.4.0 - Build 892',
                        style: GoogleFonts.lato(
                          fontSize: 15,
                          color: const Color(0xFFD0D5DD),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  );
                },
          ),
        ),
      ),
    );
  }

  String _safeNetworkUrl(String raw) {
    final String value = raw.trim();
    if (value.isEmpty) return '';
    final Uri? uri = Uri.tryParse(value);
    final bool valid =
        uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
    return valid ? value : '';
  }

  Future<void> _openAvatarActions({
    required String currentPhotoUrl,
    required String displayName,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(
                  _enableStorageUploads
                      ? 'Choose from gallery'
                      : 'Choose from gallery (requires Blaze)',
                ),
                enabled: _enableStorageUploads,
                onTap: _enableStorageUploads
                    ? () async {
                        Navigator.of(sheetContext).pop();
                        await _pickAndUploadFromGallery();
                      }
                    : null,
              ),
              ListTile(
                leading: const Icon(Icons.link_outlined),
                title: const Text('Use image URL'),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  await _setPhotoFromUrl(currentPhotoUrl);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Change display name'),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  await _editDisplayName(displayName);
                },
              ),
              if (currentPhotoUrl.trim().isNotEmpty)
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: Color(0xFFB42318),
                  ),
                  title: const Text(
                    'Remove photo',
                    style: TextStyle(color: Color(0xFFB42318)),
                  ),
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    await _removePhoto();
                  },
                ),
              const SizedBox(height: 6),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAndUploadFromGallery() async {
    if (!_enableStorageUploads) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Gallery upload is disabled in demo mode. Use image URL instead.',
          ),
        ),
      );
      return;
    }
    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 86,
        maxWidth: 1400,
      );
      if (picked == null) return;

      setState(() => _isUploadingPhoto = true);
      final Uint8List bytes = await picked.readAsBytes();
      await _profileMediaService.uploadProfilePhoto(bytes);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile photo updated.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
      }
    }
  }

  Future<void> _setPhotoFromUrl(String currentPhotoUrl) async {
    String draftValue = currentPhotoUrl;
    final String? value = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Profile photo URL'),
          content: TextFormField(
            initialValue: currentPhotoUrl,
            keyboardType: TextInputType.url,
            autofocus: true,
            onChanged: (String text) => draftValue = text,
            decoration: const InputDecoration(
              hintText: 'https://example.com/avatar.jpg',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(draftValue.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (value == null) return;

    final Uri? uri = value.isEmpty ? null : Uri.tryParse(value);
    final bool validHttpUrl =
        uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
    if (value.isNotEmpty && !validHttpUrl) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid URL.')),
      );
      return;
    }

    if (!mounted) return;
    final NovaHomesState state = NovaHomesScope.of(context);
    state.setProfilePhotoUrlOverride(value);

    setState(() => _isUploadingPhoto = true);
    try {
      if (_enableRemoteProfileSync) {
        await _authService
            .updateProfilePhotoUrl(value)
            .timeout(const Duration(seconds: 12));
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile photo updated.')));
    } on TimeoutException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request timed out. Please try another image URL.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
      }
    }
  }

  Future<void> _removePhoto() async {
    final NovaHomesState state = NovaHomesScope.of(context);
    state.setProfilePhotoUrlOverride('');
    setState(() => _isUploadingPhoto = true);
    try {
      if (_enableRemoteProfileSync) {
        await _profileMediaService.clearProfilePhoto();
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile photo removed.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
      }
    }
  }

  Future<void> _editDisplayName(String currentName) async {
    String draftValue = currentName;
    final String? value = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Display name'),
          content: TextFormField(
            initialValue: currentName,
            textCapitalization: TextCapitalization.words,
            autofocus: true,
            onChanged: (String text) => draftValue = text,
            decoration: const InputDecoration(hintText: 'Your name'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(draftValue.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (value == null || value.trim().isEmpty) return;

    if (!mounted) return;
    final NovaHomesState state = NovaHomesScope.of(context);
    state.setProfileDisplayNameOverride(value.trim());
    setState(() => _isUpdatingName = true);
    try {
      if (_enableRemoteProfileSync) {
        await _authService.updateDisplayName(value.trim());
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Display name updated.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdatingName = false);
      }
    }
  }

  Widget _fallbackAvatar() {
    return Container(
      color: const Color(0xFFDAC5A5),
      alignment: Alignment.center,
      child: const Icon(Icons.person, size: 62, color: Colors.white),
    );
  }

  Widget _statPill({required String value, required String label}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: <Widget>[
            Text(
              value,
              style: GoogleFonts.lato(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.lato(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF667085),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileOption({required IconData icon, required String title}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: <Widget>[
          Container(
            width: 54,
            height: 54,
            decoration: const BoxDecoration(
              color: AppColors.cream,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFFC39D20)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.lato(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF233047),
              ),
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFFD0D5DD),
            size: 30,
          ),
        ],
      ),
    );
  }
}
