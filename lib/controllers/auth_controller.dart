import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../services/local_storage_service.dart';

class AuthController extends ChangeNotifier {
  final LocalStorageService _storage;
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  AuthController(this._storage) {
    _currentUser = _storage.getCurrentUser();
  }

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ─────────────── Register ───────────────

  Future<bool> register({
    required String name,
    required String username,
    required String password,
    DateTime? birthday,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    if (name.trim().isEmpty || username.trim().isEmpty || password.length < 6) {
      _errorMessage = 'Please fill all fields. Password min 6 chars.';
      _setLoading(false);
      return false;
    }

    final user = UserModel(
      id: const Uuid().v4(),
      name: name.trim(),
      username: username.trim().toLowerCase(),
      passwordHash: _hashPassword(password),
      birthday: birthday,
    );

    final saved = await _storage.saveUser(user);
    if (!saved) {
      _errorMessage = 'Username already exists.';
      _setLoading(false);
      return false;
    }

    _setLoading(false);
    return true;
  }

  // ─────────────── Login ───────────────

  Future<bool> login({
    required String username,
    required String password,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    final user = _storage.findByUsername(username.trim().toLowerCase());

    if (user == null || user.passwordHash != _hashPassword(password)) {
      _errorMessage = 'Invalid username or password.';
      _setLoading(false);
      return false;
    }

    _currentUser = user;
    await _storage.saveCurrentUser(user);
    _setLoading(false);
    notifyListeners();
    return true;
  }

  // ─────────────── Logout ───────────────

  Future<void> logout() async {
    _currentUser = null;
    await _storage.clearCurrentUser();
    notifyListeners();
  }

  void refreshCurrentUser() {
    _currentUser = _storage.getCurrentUser();
    notifyListeners();
  }

  // ─────────────── Helpers ───────────────

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
