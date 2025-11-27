class UserEntity {
  final int id;
  final String username;
  final String? email;

  UserEntity({
    required this.id,
    required this.username,
    this.email,
  });

  // convert a user entity to a json object
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
    };
  }

  // convert a json object to a user entity
  factory UserEntity.fromJson(Map<String, dynamic> jsonUser) {
    return UserEntity(
      id: jsonUser['id'],
      username: jsonUser['username'],
      email: jsonUser['email'],
    );
  }
}