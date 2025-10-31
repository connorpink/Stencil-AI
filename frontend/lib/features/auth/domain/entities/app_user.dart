class AppUser {
  final String id;
  final String username;

  AppUser({
    required this.id,
    required this.username,
  });

  // convert app user to json object
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
    };
  }

  // convert json object to app user
  factory AppUser.fromJson(Map<String, dynamic> jsonUser) {
    return AppUser(
      id: jsonUser['id'],
      username: jsonUser['username'],
    );
  }
}