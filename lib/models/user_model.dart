class UserModel {
  final String uid;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String role; // 'client' | 'admin'

  const UserModel({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    this.role = 'client',
  });

  String get fullName => '$firstName $lastName';

  factory UserModel.fromMap(String uid, Map<String, dynamic> m) => UserModel(
        uid: uid,
        firstName: m['firstName'] ?? '',
        lastName: m['lastName'] ?? '',
        email: m['email'] ?? '',
        phone: m['phone'] ?? '',
        role: m['role'] ?? 'client',
      );

  Map<String, dynamic> toMap() => {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phone': phone,
        'role': role,
      };

  UserModel copyWith({
    String? uid,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? role,
  }) =>
      UserModel(
        uid: uid ?? this.uid,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        role: role ?? this.role,
      );
}
