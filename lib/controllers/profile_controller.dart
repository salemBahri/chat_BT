import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import '../services/local_storage_service.dart';
import 'auth_controller.dart';

class ProfileController extends ChangeNotifier {
  final LocalStorageService _storage;
  final AuthController _authController;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  ProfileController(this._storage, this._authController);

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  Future<bool> updateProfile({
    required String name,
    DateTime? birthday,
  }) async {
    _setLoading(true);
    _clearMessages();

    if (name.trim().isEmpty) {
      _errorMessage = 'Name cannot be empty.';
      _setLoading(false);
      return false;
    }

    final current = _authController.currentUser;
    if (current == null) return false;

    final updated = current.copyWith(
      name: name.trim(),
      birthday: birthday,
    );

    await _storage.updateUser(updated);
    _authController.refreshCurrentUser();

    _successMessage = 'Profile updated successfully!';
    _setLoading(false);
    return true;
  }

  Future<String?> pickAndSaveProfileImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 512,
      maxHeight: 512,
    );

    if (picked == null) return null;

    final current = _authController.currentUser;
    if (current == null) return null;

    final updated = current.copyWith(
      profileImagePath: picked.path,
    );

    await _storage.updateUser(updated);
    _authController.refreshCurrentUser();
    notifyListeners();

    return picked.path;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearMessages() {
    _errorMessage = null;
    _successMessage = null;
  }

  void clearMessages() {
    _clearMessages();
    notifyListeners();
  }
}
