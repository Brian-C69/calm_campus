import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/app_localizations.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController _newPass = TextEditingController();
  final TextEditingController _confirmPass = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _newPass.dispose();
    _confirmPass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final strings = AppLocalizations.of(context);
    final newPassword = _newPass.text.trim();
    final confirm = _confirmPass.text.trim();

    if (newPassword.isEmpty || newPassword.length < 8 || newPassword != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.t('auth.password.short'))),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.t('auth.password.updated'))),
      );
      Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
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
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.t('auth.reset.title')),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(strings.t('auth.reset.desc')),
                const SizedBox(height: 16),
                TextField(
                  controller: _newPass,
                  obscureText: true,
                  decoration: InputDecoration(labelText: strings.t('auth.password.new')),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _confirmPass,
                  obscureText: true,
                  decoration: InputDecoration(labelText: strings.t('auth.password.confirm')),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _loading ? null : _submit,
                    icon: _loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.lock_reset),
                    label: Text(strings.t('auth.reset.submit')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
