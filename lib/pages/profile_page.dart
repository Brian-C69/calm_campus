import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:crop_your_image/crop_your_image.dart';

import '../services/user_profile_service.dart';
import '../l10n/app_localizations.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<_ProfileData> _profileFuture;
  final ImagePicker _picker = ImagePicker();
  final _cropController = CropController();

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfile();
  }

  Future<_ProfileData> _loadProfile() async {
    final isLoggedIn = await UserProfileService.instance.isLoggedIn();
    if (!isLoggedIn) {
      return const _ProfileData(isLoggedIn: false);
    }

    final nickname = await UserProfileService.instance.getNickname();
    final course = await UserProfileService.instance.getCourse();
    final year = await UserProfileService.instance.getYearOfStudy();
    final avatarPath = await UserProfileService.instance.getAvatarPath();
    final avatarUrl = await UserProfileService.instance.getAvatarUrl();
    return _ProfileData(
      isLoggedIn: true,
      nickname: nickname,
      course: course,
      yearOfStudy: year,
      avatarPath: avatarPath,
      avatarUrl: avatarUrl,
    );
  }

  Future<void> _openSettings() async {
    await Navigator.pushNamed(context, '/settings');
    setState(() {
      _profileFuture = _loadProfile();
    });
  }

  Future<void> _openAbout() async {
    await Navigator.pushNamed(context, '/about');
  }

  Future<void> _openLogin() async {
    await Navigator.pushNamed(context, '/auth');
    setState(() {
      _profileFuture = _loadProfile();
    });
  }

  Future<void> _logout() async {
    final strings = AppLocalizations.of(context);
    await UserProfileService.instance.setLoggedIn(false);

    if (!mounted) return;

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(strings.t('profile.logout.title')),
          content: Text(strings.t('profile.logout.body')),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(strings.t('common.ok')),
            ),
          ],
        );
      },
    ).then((_) {
      if (!mounted) return;
      setState(() {
        _profileFuture = _loadProfile();
      });
    });
  }

  Future<void> _changePassword() async {
    final strings = AppLocalizations.of(context);
    final TextEditingController newPass = TextEditingController();
    final TextEditingController confirmPass = TextEditingController();
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.t('auth.password.change')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: newPass,
              obscureText: true,
              decoration: InputDecoration(labelText: strings.t('auth.password.new')),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPass,
              obscureText: true,
              decoration: InputDecoration(labelText: strings.t('auth.password.confirm')),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.t('common.cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(strings.t('common.save')),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (confirmed != true) return;
    if (newPass.text.isEmpty || newPass.text.length < 8 || newPass.text != confirmPass.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.t('auth.password.short'))),
      );
      return;
    }

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPass.text),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.t('auth.password.updated'))),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message.isNotEmpty ? e.message : strings.t('auth.error.generic'))),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.t('auth.error.generic'))),
      );
    }
  }

  Future<void> _showAvatarSheet() async {
    final strings = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: Text(strings.t('profile.avatar.camera')),
                onTap: () {
                  Navigator.pop(context);
                  _pickAvatar(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(strings.t('profile.avatar.gallery')),
                onTap: () {
                  Navigator.pop(context);
                  _pickAvatar(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAvatar(ImageSource source) async {
    final strings = AppLocalizations.of(context);
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 85,
      );
      if (picked == null) return;

      final Uint8List originalBytes = await File(picked.path).readAsBytes();

      final Uint8List? croppedBytes = await showDialog<Uint8List?>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: Text(strings.t('profile.avatar.change')),
            content: SizedBox(
              width: 320,
              height: 320,
              child: Crop(
                controller: _cropController,
                image: originalBytes,
                baseColor: Theme.of(context).colorScheme.surface,
                maskColor: Colors.black45,
                onCropped: (data) {
                  Navigator.of(context).pop(data);
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(null),
                child: Text(strings.t('common.cancel')),
              ),
              FilledButton(
                onPressed: () => _cropController.crop(),
                child: Text(strings.t('common.save')),
              ),
            ],
          );
        },
      );
      if (croppedBytes == null) return;

      final Directory dir = await getApplicationDocumentsDirectory();
      final String ext = '.jpg';
      final String localPath = p.join(dir.path, 'avatar$ext');
      await File(localPath).writeAsBytes(croppedBytes, flush: true);
      await UserProfileService.instance.saveAvatarPath(localPath);

      String? publicUrl;
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final String storagePath = '${user.id}/avatar$ext';
        await Supabase.instance.client.storage.from('avatars').uploadBinary(
              storagePath,
              croppedBytes,
              fileOptions: const FileOptions(
                upsert: true,
                contentType: 'image/jpeg',
              ),
            );
        publicUrl = Supabase.instance.client.storage.from('avatars').getPublicUrl(storagePath);
        await Supabase.instance.client.from('profiles').upsert({
          'id': user.id,
          'avatar_url': publicUrl,
        });
        await UserProfileService.instance.saveAvatarUrl(publicUrl);
      }

      if (!mounted) return;
      setState(() {
        _profileFuture = _loadProfile();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.t('profile.avatar.updated'))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.t('profile.avatar.error'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.t('profile.title')),
      ),
      body: FutureBuilder<_ProfileData>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final profile = snapshot.data!;
          final theme = Theme.of(context);
          ImageProvider? avatarImage;
          if (profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty) {
            avatarImage = NetworkImage(profile.avatarUrl!);
          }
          if (avatarImage == null &&
              profile.avatarPath != null &&
              profile.avatarPath!.isNotEmpty &&
              File(profile.avatarPath!).existsSync()) {
            avatarImage = FileImage(File(profile.avatarPath!));
          }

          if (!profile.isLoggedIn) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline,
                        size: 56, color: theme.colorScheme.primary),
                    const SizedBox(height: 12),
                    Text(
                      strings.t('profile.guest.title'),
                      style: theme.textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      strings.t('profile.guest.body'),
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _openLogin,
                      child: Text(strings.t('profile.login')),
                    ),
                  ],
                ),
              ),
            );
          }

          return SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      elevation: 0,
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                CircleAvatar(
                                  radius: 40,
                                  backgroundColor: theme.colorScheme.primaryContainer,
                                  backgroundImage: avatarImage,
                                  child: avatarImage == null
                                      ? Text(
                                          profile.initials,
                                          style: theme.textTheme.headlineSmall?.copyWith(
                                            color: theme.colorScheme.onPrimaryContainer,
                                          ),
                                        )
                                      : null,
                                ),
                                IconButton.filled(
                                  onPressed: _showAvatarSheet,
                                  icon: const Icon(Icons.camera_alt_outlined),
                                  tooltip: strings.t('profile.avatar.change'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              (profile.nickname?.trim().isNotEmpty ?? false)
                                  ? profile.nickname!
                                  : strings.t('profile.nickname.missing'),
                              style: theme.textTheme.titleLarge,
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              (profile.course?.trim().isNotEmpty ?? false)
                                  ? profile.course!
                                  : strings.t('profile.course.missing'),
                              style: theme.textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              profile.yearOfStudy != null
                                  ? strings
                                      .t('profile.year.label')
                                      .replaceFirst('{year}', profile.yearOfStudy.toString())
                                  : strings.t('profile.year.missing'),
                              style: theme.textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(strings.t('profile.overview'), style: theme.textTheme.titleMedium),
                            const SizedBox(height: 8),
                            ListTile(
                              leading: const Icon(Icons.info_outline),
                              title: Text(strings.t('about.title')),
                              subtitle: Text(strings.t('about.subtitle')),
                              onTap: _openAbout,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _openSettings,
                      icon: const Icon(Icons.settings),
                      label: Text(strings.t('profile.openSettings')),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: _changePassword,
                      icon: const Icon(Icons.lock_reset),
                      label: Text(strings.t('auth.password.change')),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout),
                      label: Text(strings.t('profile.logout')),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProfileData {
  const _ProfileData({
    required this.isLoggedIn,
    this.nickname,
    this.course,
    this.yearOfStudy,
    this.avatarPath,
    this.avatarUrl,
  });

  final bool isLoggedIn;
  final String? nickname;
  final String? course;
  final int? yearOfStudy;
  final String? avatarPath;
  final String? avatarUrl;

  String get initials {
    if (nickname == null || nickname!.trim().isEmpty) {
      return '?';
    }
    final parts = nickname!.trim().split(' ');
    final buffer = StringBuffer();
    for (final part in parts.take(2)) {
      if (part.isNotEmpty) buffer.write(part[0].toUpperCase());
    }
    return buffer.isEmpty ? '?' : buffer.toString();
  }
}
