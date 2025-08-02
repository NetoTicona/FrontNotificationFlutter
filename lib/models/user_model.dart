class User {
  final String id;
  final String username;
  final String deviceId;

  User({
    required this.id,
    required this.username,
    required this.deviceId,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'].toString(),
      username: json['user'],
      deviceId: json['iddevice'].toString(),
    );
  }
}

class UserSequence {
  final String userId;
  final String username;
  final List<String> colors;

  UserSequence({
    required this.userId,
    required this.username,
    required this.colors,
  });

  factory UserSequence.fromJson(Map<String, dynamic> json) {
    return UserSequence(
      userId: json['iduser'],
      username: json['username'],
      colors: List<String>.from(json['sequence'].map((x) => x['color'])),
    );
  }
}