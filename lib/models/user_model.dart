import 'dart:convert';

class UserModel {
  final String id;
  String name;
  String username;
  String passwordHash;
  DateTime? birthday;
  String? profileImagePath;

  UserModel({
    required this.id,
    required this.name,
    required this.username,
    required this.passwordHash,
    this.birthday,
    this.profileImagePath,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'username': username,
    'passwordHash': passwordHash,
    'birthday': birthday?.toIso8601String(),
    'profileImagePath': profileImagePath,
  };

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
    id: map['id'] as String,
    name: map['name'] as String,
    username: map['username'] as String,
    passwordHash: map['passwordHash'] as String,
    birthday: map['birthday'] != null
        ? DateTime.parse(map['birthday'] as String)
        : null,
    profileImagePath: map['profileImagePath'] as String?,
  );

  String toJson() => jsonEncode(toMap());

  factory UserModel.fromJson(String source) =>
      UserModel.fromMap(jsonDecode(source) as Map<String, dynamic>);

  /// Only public info sent over Bluetooth (never share password)
  Map<String, dynamic> toPublicMap() => {
    'id': id,
    'name': name,
  };

  UserModel copyWith({
    String? name,
    DateTime? birthday,
    String? profileImagePath,
  }) =>
      UserModel(
        id: id,
        name: name ?? this.name,
        username: username,
        passwordHash: passwordHash,
        birthday: birthday ?? this.birthday,
        profileImagePath: profileImagePath ?? this.profileImagePath,
      );
}
