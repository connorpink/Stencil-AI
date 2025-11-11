class AppUser {
  final int id;
  final String username;
  final String? email;

  AppUser({
    required this.id,
    required this.username,
    this.email,
  });

  // convert app user to json object
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
    };
  }

  // convert json object to app user
  factory AppUser.fromJson(Map<String, dynamic> jsonUser) {
    return AppUser(
      id: jsonUser['id'],
      username: jsonUser['username'],
      email: jsonUser['email'],
    );
  }
}