class UserEntity {
  final int id;
  final String username;
  final String? email;

  UserEntity({
    required this.id,
    required this.username,
    this.email,
  });
}