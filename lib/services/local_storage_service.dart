import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class LocalStorageService {
  static const String _usersKey = 'registered_users';
  static const String _currentUserKey = 'current_user';

  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  static Future<LocalStorageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalStorageService(prefs);
  }

  // ─────────────── User Registration ───────────────

  Future<bool> saveUser(UserModel user) async {
    final users = getAllUsers();
    final exists = users.any((u) => u.username == user.username);
    if (exists) return false;

    users.add(user);
    final encoded = users.map((u) => u.toJson()).toList();
    await _prefs.setStringList(_usersKey, encoded);
    return true;
  }

  Future<void> updateUser(UserModel updatedUser) async {
    final users = getAllUsers();
    final index = users.indexWhere((u) => u.id == updatedUser.id);
    if (index != -1) {
      users[index] = updatedUser;
      final encoded = users.map((u) => u.toJson()).toList();
      await _prefs.setStringList(_usersKey, encoded);

      // Update current user if it's the same
      final current = getCurrentUser();
      if (current?.id == updatedUser.id) {
        await saveCurrentUser(updatedUser);
      }
    }
  }

  List<UserModel> getAllUsers() {
    final raw = _prefs.getStringList(_usersKey) ?? [];
    return raw.map(UserModel.fromJson).toList();
  }

  UserModel? findByUsername(String username) {
    final users = getAllUsers();
    try {
      return users.firstWhere((u) => u.username == username);
    } catch (_) {
      return null;
    }
  }

  // ─────────────── Session ───────────────

  Future<void> saveCurrentUser(UserModel user) async {
    await _prefs.setString(_currentUserKey, user.toJson());
  }

  UserModel? getCurrentUser() {
    final raw = _prefs.getString(_currentUserKey);
    if (raw == null) return null;
    return UserModel.fromJson(raw);
  }

  Future<void> clearCurrentUser() async {
    await _prefs.remove(_currentUserKey);
  }

  bool get isLoggedIn => _prefs.containsKey(_currentUserKey);
}
