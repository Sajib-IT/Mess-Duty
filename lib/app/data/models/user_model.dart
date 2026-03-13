class UserModel {
  final String id;
  final String name;
  final String email;
  final bool isAvailable;
  final String? photoUrl;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.isAvailable = true,
    this.photoUrl,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String id) {
    return UserModel(
      id: id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      isAvailable: data['isAvailable'] ?? true,
      photoUrl: data['photoUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'isAvailable': isAvailable,
      'photoUrl': photoUrl,
    };
  }

  UserModel copyWith({
    String? name,
    bool? isAvailable,
    String? photoUrl,
  }) {
    return UserModel(
      id: this.id,
      name: name ?? this.name,
      email: this.email,
      isAvailable: isAvailable ?? this.isAvailable,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}
