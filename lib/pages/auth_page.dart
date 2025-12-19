import 'package:flutter/material.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/user_profile_service.dart';
import '../services/supabase_sync_service.dart';
import '../services/role_service.dart';
import '../services/firebase_messaging_service.dart';
import '../l10n/app_localizations.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLogin = true;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _toggleMode(bool isLogin) {
    if (_isLogin == isLogin) return;
    setState(() {
      _isLogin = isLogin;
    });
  }

  Future<void> _submit() async {
    final strings = AppLocalizations.of(context);
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    final friendlyAction =
        _isLogin ? strings.t('auth.state.signedIn') : strings.t('auth.state.signedUp');
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final client = Supabase.instance.client;

    try {
      AuthResponse response;
      if (_isLogin) {
        response = await client.auth.signInWithPassword(
          email: email,
          password: password,
        );
      } else {
        response = await client.auth.signUp(
          email: email,
          password: password,
          emailRedirectTo: 'https://luba-irrecusable-clayton.ngrok-free.dev/confirm/',
          data: {
            'preferred_name': _nameController.text.trim(),
            'role': 'student',
          },
        );
        await UserProfileService.instance.saveNickname(_nameController.text);
        await RoleService.instance.upsertStudentProfileOnSignup(_nameController.text.trim());
      }

      final session = response.session ?? client.auth.currentSession;
      final user = response.user ?? client.auth.currentUser;
      final bool isConfirmed = user?.emailConfirmedAt != null;

      if (!_isLogin && !isConfirmed) {
        await client.auth.signOut();
        await UserProfileService.instance.setLoggedIn(false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(strings.t('auth.signup.verifyEmail')),
          ),
        );
        return;
      }

      if (session == null) {
        await UserProfileService.instance.setLoggedIn(false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isLogin ? strings.t('auth.error.login') : strings.t('auth.signup.verifyEmail'),
            ),
          ),
        );
        return;
      }

      await UserProfileService.instance.setLoggedIn(true);
      final role = await RoleService.instance.refreshRoleFromSupabase();
      await FirebaseMessagingService.instance.syncForRole(role);

      await SupabaseSyncService.instance.uploadAllData();
      try {
        await SupabaseSyncService.instance.downloadAllData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${strings.t('auth.sync.pullFailed')}\nDetails: $e',
              ),
            ),
          );
        }
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.message.isNotEmpty
                ? e.message
                : (_isLogin ? strings.t('auth.error.login') : strings.t('auth.error.signup')),
          ),
        ),
      );
      return;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${strings.t('auth.error.generic')}\nDetails: $e',
          ),
        ),
      );
      return;
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          strings.t('auth.success').replaceFirst('{state}', friendlyAction),
        ),
      ),
    );

    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final brightness = Theme.of(context).brightness;
    final logoAsset = brightness == Brightness.dark
        ? 'assets/photo/calm_campus_logo_white.png'
        : 'assets/photo/calm_campus_logo.png';

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Semantics(
                      label: strings.t('app.title'),
                      child: Image.asset(
                        logoAsset,
                        width: 160,
                        height: 80,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    strings.t('auth.welcome.title'),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    strings.t('auth.welcome.subtitle'),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: Theme.of(context)
                            .colorScheme
                            .outlineVariant,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SegmentedButton<bool>(
                            segments: [
                              ButtonSegment(value: true, label: Text(strings.t('auth.login'))),
                              ButtonSegment(value: false, label: Text(strings.t('auth.signup'))),
                            ],
                            selected: {_isLogin},
                            onSelectionChanged: (selection) {
                              _toggleMode(selection.first);
                            },
                          ),
                          const SizedBox(height: 20),
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                if (!_isLogin)
                                  TextFormField(
                                    controller: _nameController,
                                    textInputAction: TextInputAction.next,
                                    decoration: InputDecoration(
                                      labelText: strings.t('auth.name'),
                                      helperText: strings.t('auth.name.helper'),
                                      prefixIcon: const Icon(Icons.person_outline),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return strings.t('auth.name.error');
                                      }
                                      return null;
                                    },
                                  ),
                                if (!_isLogin) const SizedBox(height: 12),
                                TextFormField(
                                  controller: _emailController,
                                  textInputAction: TextInputAction.next,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: InputDecoration(
                                    labelText: strings.t('auth.email'),
                                    prefixIcon: const Icon(Icons.email_outlined),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return strings.t('auth.email.error');
                                    }
                                    if (!value.contains('@')) {
                                      return strings.t('auth.email.invalid');
                                    }
                                    final email = value.trim().toLowerCase();
                                    if (!_isLogin && !email.endsWith('@student.tarc.edu.my')) {
                                      return strings.t('auth.email.studentOnly');
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _passwordController,
                                  textInputAction:
                                      _isLogin ? TextInputAction.done : TextInputAction.next,
                                  obscureText: _obscurePassword,
                                  decoration: InputDecoration(
                                    labelText: _isLogin
                                        ? strings.t('auth.password')
                                        : strings.t('auth.password.create'),
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    suffixIcon: IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                      ),
                                      tooltip: _obscurePassword
                                          ? strings.t('common.show')
                                          : strings.t('common.hide'),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return strings.t('auth.password.error');
                                    }
                                    if (value.length < 8) {
                                      return strings.t('auth.password.short');
                                    }
                                    return null;
                                  },
                                ),
                                if (!_isLogin) const SizedBox(height: 12),
                                if (!_isLogin)
                                  TextFormField(
                                    controller: _confirmPasswordController,
                                    textInputAction: TextInputAction.done,
                                    obscureText: _obscurePassword,
                                    decoration: InputDecoration(
                                      labelText: strings.t('auth.password.confirm'),
                                      prefixIcon: const Icon(Icons.verified_user_outlined),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return strings.t('auth.password.error');
                                      }
                                      if (value != _passwordController.text) {
                                        return strings.t('auth.password.mismatch');
                                      }
                                      return null;
                                    },
                                  ),
                                const SizedBox(height: 20),
                                FilledButton.icon(
                                  onPressed: _submit,
                                  icon: Icon(_isLogin
                                      ? Icons.login_rounded
                                      : Icons.person_add_alt_1_outlined),
                                  label: Text(
                                    _isLogin ? strings.t('auth.login') : strings.t('auth.signup'),
                                  ),
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size.fromHeight(48),
                                  ),
                                ),
                                if (_isLogin) ...[
                                  const SizedBox(height: 8),
                                  TextButton(
                                    onPressed: () => Navigator.pushNamed(context, '/reset-request'),
                                    child: Text(strings.t('auth.reset.cta')),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                TextButton(
                                  onPressed: () => _toggleMode(!_isLogin),
                                  child: Text(
                                    _isLogin
                                        ? strings.t('auth.cta.toSignup')
                                        : strings.t('auth.cta.toLogin'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.shield_moon_outlined),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          strings.t('auth.privacy'),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        label: Text(strings.t('auth.chip.checkins')),
                        avatar: const Icon(Icons.self_improvement_outlined),
                      ),
                      Chip(
                        label: Text(strings.t('auth.chip.tasks')),
                        avatar: const Icon(Icons.task_alt_outlined),
                      ),
                      Chip(
                        label: Text(strings.t('auth.chip.audio')),
                        avatar: const Icon(Icons.headphones_outlined),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
