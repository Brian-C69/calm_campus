import 'package:flutter/material.dart';

import '../models/user_role.dart';
import '../services/role_service.dart';
import '../services/user_profile_service.dart';
import 'admin_dashboard_page.dart';
import 'student_shell.dart';

class RoleGatePage extends StatefulWidget {
  const RoleGatePage({super.key});

  @override
  State<RoleGatePage> createState() => _RoleGatePageState();
}

class _RoleGatePageState extends State<RoleGatePage> {
  late Future<UserRole> _roleFuture;

  @override
  void initState() {
    super.initState();
    _maybeShowOnboarding();
    _roleFuture = _loadRole();
  }

  Future<void> _maybeShowOnboarding() async {
    final bool firstRun = await UserProfileService.instance.isFirstRun();
    if (!mounted) return;
    if (firstRun) {
      Navigator.of(context).pushReplacementNamed('/onboarding');
    }
  }

  Future<UserRole> _loadRole() async {
    final bool loggedIn = await UserProfileService.instance.isLoggedIn();
    if (!loggedIn) return UserRole.student;
    return RoleService.instance.refreshRoleFromSupabase();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserRole>(
      future: _roleFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final UserRole role = snapshot.data ?? UserRole.student;
        if (role == UserRole.admin) {
          return const AdminDashboardPage();
        }
        return const MainNavigation();
      },
    );
  }
}
