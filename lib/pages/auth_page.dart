import 'package:flutter/material.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/user_profile_service.dart';
import '../services/supabase_sync_service.dart';

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
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    final friendlyAction = _isLogin ? 'signed in' : 'signed up';
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final client = Supabase.instance.client;

    try {
      if (_isLogin) {
        await client.auth.signInWithPassword(
          email: email,
          password: password,
        );
      } else {
        await client.auth.signUp(
          email: email,
          password: password,
          data: {
            'preferred_name': _nameController.text.trim(),
          },
        );
      }

      if (!_isLogin) {
        await UserProfileService.instance.saveNickname(_nameController.text);
      }
      await UserProfileService.instance.setLoggedIn(true);

      await SupabaseSyncService.instance.uploadAllData();
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.message.isNotEmpty
                ? e.message
                : 'We could not ${_isLogin ? 'log you in' : 'create your account'} right now. Please try again.',
          ),
        ),
      );
      return;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Something went wrong while contacting the server. Your local data is still safe on this device.\nDetails: $e',
          ),
        ),
      );
      return;
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'You\'re $friendlyAction. Your data will stay on this device and is now also backed up to your account.',
        ),
      ),
    );

    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
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
                  Text(
                    'Welcome to CalmCampus',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'A gentle place to check in with yourself. Create an account or log in to keep your mood, tasks, and calming tracks in one spot.',
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
                            segments: const [
                              ButtonSegment(value: true, label: Text('Log in')),
                              ButtonSegment(value: false, label: Text('Sign up')),
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
                                    decoration: const InputDecoration(
                                      labelText: 'Preferred name',
                                      helperText:
                                          'We\'ll greet you with this name inside the app.',
                                      prefixIcon: Icon(Icons.person_outline),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Please share a name we can use.';
                                      }
                                      return null;
                                    },
                                  ),
                                if (!_isLogin) const SizedBox(height: 12),
                                TextFormField(
                                  controller: _emailController,
                                  textInputAction: TextInputAction.next,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: const InputDecoration(
                                    labelText: 'University email',
                                    prefixIcon: Icon(Icons.email_outlined),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Email helps us keep your space personal.';
                                    }
                                    if (!value.contains('@')) {
                                      return 'Please enter a valid email address.';
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
                                    labelText: 'Password',
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
                                          ? 'Show password'
                                          : 'Hide password',
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'A password keeps your check-ins private.';
                                    }
                                    if (value.length < 8) {
                                      return 'Use at least 8 characters for extra safety.';
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
                                    decoration: const InputDecoration(
                                      labelText: 'Confirm password',
                                      prefixIcon: Icon(Icons.verified_user_outlined),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please confirm your password.';
                                      }
                                      if (value != _passwordController.text) {
                                        return 'The passwords don\'t match yet.';
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
                                  label: Text(_isLogin ? 'Log in' : 'Create account'),
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size.fromHeight(48),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextButton(
                                  onPressed: () => _toggleMode(!_isLogin),
                                  child: Text(
                                    _isLogin
                                        ? 'New here? Create a gentle space.'
                                        : 'Already have an account? Log in.',
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
                          'Your reflections stay private. If you ever feel unsafe, please reach out to campus support or a trusted person.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: const [
                      Chip(
                        label: Text('Gentle check-ins'),
                        avatar: Icon(Icons.self_improvement_outlined),
                      ),
                      Chip(
                        label: Text('Track study tasks'),
                        avatar: Icon(Icons.task_alt_outlined),
                      ),
                      Chip(
                        label: Text('Relaxing audio'),
                        avatar: Icon(Icons.headphones_outlined),
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
