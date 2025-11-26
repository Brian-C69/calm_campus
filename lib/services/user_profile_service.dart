import 'package:shared_preferences/shared_preferences.dart';

class UserProfileService {
  UserProfileService._();

  static final UserProfileService instance = UserProfileService._();

  final String _nicknameKey = 'nickname';

  Future<String?> getNickname() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nicknameKey);
  }

  Future<void> saveNickname(String nickname) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nicknameKey, nickname.trim());
  }
}
