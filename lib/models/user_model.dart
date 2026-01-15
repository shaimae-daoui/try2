class UserModel {
  String uid;
  String email;
  String phoneNumber;
  String role;
  bool isVerified;
  String? team;
  String? fullName;
  DateTime createdAt;
  int reputationPoints;

  UserModel({
    required this.uid,
    required this.email,
    required this.phoneNumber,
    this.role = 'user',
    this.isVerified = false,
    this.team,
    this.fullName,
    DateTime? createdAt,
    this.reputationPoints = 0,
  }) : this.createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'phoneNumber': phoneNumber,
      'role': role,
      'isVerified': isVerified,
      'team': team,
      'fullName': fullName,
      'createdAt': createdAt.toIso8601String(),
      'reputationPoints': reputationPoints,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      role: data['role'] ?? 'user',
      isVerified: data['isVerified'] ?? false,
      team: data['team'],
      fullName: data['fullName'],
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'])
          : DateTime.now(),
      reputationPoints: data['reputationPoints'] ?? 0,
    );
  }

  bool isMaestro() => role == 'maestro' || role == 'admin';
  bool canSponsor() => isVerified && reputationPoints >= 50;
  bool isAdmin() => role == 'admin';
}
