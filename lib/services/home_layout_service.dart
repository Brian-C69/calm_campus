import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeTileConfig {
  const HomeTileConfig({
    required this.id,
    required this.labelKey,
    required this.route,
    required this.icon,
  });

  final String id;
  final String labelKey;
  final String route;
  final IconData icon;
}

class HomeLayoutState {
  const HomeLayoutState({required this.order, required this.hidden});

  final List<String> order;
  final Set<String> hidden;
}

class HomeLayoutService {
  HomeLayoutService._();

  static final HomeLayoutService instance = HomeLayoutService._();

  final String _orderKey = 'home_tile_order';
  final String _hiddenKey = 'home_tile_hidden';

  List<HomeTileConfig> get defaults => const [
        HomeTileConfig(id: 'mood', labelKey: 'home.card.mood', route: '/mood', icon: Icons.favorite),
        HomeTileConfig(id: 'snapshot', labelKey: 'home.card.snapshot', route: '/snapshot', icon: Icons.today),
        HomeTileConfig(id: 'news', labelKey: 'home.card.news', route: '/announcements', icon: Icons.campaign),
        HomeTileConfig(id: 'journal', labelKey: 'home.card.journal', route: '/journal', icon: Icons.menu_book),
        HomeTileConfig(id: 'profile', labelKey: 'home.card.profile', route: '/profile', icon: Icons.person),
        HomeTileConfig(id: 'timetable', labelKey: 'home.card.timetable', route: '/timetable', icon: Icons.schedule),
        HomeTileConfig(id: 'tasks', labelKey: 'home.card.tasks', route: '/tasks', icon: Icons.checklist),
        HomeTileConfig(id: 'chat', labelKey: 'home.card.chat', route: '/chat', icon: Icons.chat),
        HomeTileConfig(id: 'relax', labelKey: 'home.card.relax', route: '/relax', icon: Icons.spa),
        HomeTileConfig(id: 'sleep', labelKey: 'home.card.sleep', route: '/sleep', icon: Icons.nights_stay),
        HomeTileConfig(id: 'movement', labelKey: 'home.card.movement', route: '/movement', icon: Icons.directions_walk),
        HomeTileConfig(id: 'period', labelKey: 'home.card.period', route: '/period-tracker', icon: Icons.calendar_today),
        HomeTileConfig(id: 'support', labelKey: 'home.card.support', route: '/support-plan', icon: Icons.emoji_people),
        HomeTileConfig(id: 'consultation', labelKey: 'home.card.consultation', route: '/consultation', icon: Icons.support_agent),
        HomeTileConfig(id: 'help', labelKey: 'home.card.help', route: '/help-now', icon: Icons.volunteer_activism),
        HomeTileConfig(id: 'dsa', labelKey: 'home.card.dsa', route: '/dsa-summary', icon: Icons.analytics),
        HomeTileConfig(id: 'challenges', labelKey: 'home.card.challenges', route: '/challenges', icon: Icons.menu_book),
      ];

  Future<HomeLayoutState> loadLayout() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? orderJson = prefs.getString(_orderKey);
    String? hiddenJson = prefs.getString(_hiddenKey);

    final supaUser = Supabase.instance.client.auth.currentUser;
    final meta = supaUser?.userMetadata ?? {};
    if (meta['homeLayoutOrder'] != null) {
      orderJson = jsonEncode(meta['homeLayoutOrder']);
    }
    if (meta['homeLayoutHidden'] != null) {
      hiddenJson = jsonEncode(meta['homeLayoutHidden']);
    }

    List<String> order = defaults.map((d) => d.id).toList();
    if (orderJson != null) {
      final List<dynamic> decoded = jsonDecode(orderJson) as List<dynamic>;
      order = decoded.map((e) => e.toString()).toList();
    }

    Set<String> hidden = {};
    if (hiddenJson != null) {
      final List<dynamic> decoded = jsonDecode(hiddenJson) as List<dynamic>;
      hidden = decoded.map((e) => e.toString()).toSet();
    }

    // Ensure only known ids
    final knownIds = defaults.map((d) => d.id).toSet();
    order = order.where((id) => knownIds.contains(id)).toList();
    hidden = hidden.where((id) => knownIds.contains(id)).toSet();

    // Append any missing defaults to order
    for (final id in knownIds) {
      if (!order.contains(id)) {
        order.add(id);
      }
    }

    return HomeLayoutState(order: order, hidden: hidden);
  }

  Future<void> saveLayout(HomeLayoutState state) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_orderKey, jsonEncode(state.order));
    await prefs.setString(_hiddenKey, jsonEncode(state.hidden.toList()));

    final supaUser = Supabase.instance.client.auth.currentUser;
    if (supaUser != null) {
      try {
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(
            data: {
              'homeLayoutOrder': state.order,
              'homeLayoutHidden': state.hidden.toList(),
            },
          ),
        );
      } catch (_) {
        // Silently ignore; local prefs remain
      }
    }
  }
}
