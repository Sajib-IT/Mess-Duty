import 'package:cloud_firestore/cloud_firestore.dart';

class MessModel {
  final String messId;
  final String name;
  final String address;
  final String description;
  final String createdBy;
  final List<String> memberIds;
  final DateTime createdAt;

  MessModel({
    required this.messId,
    required this.name,
    required this.address,
    required this.description,
    required this.createdBy,
    required this.memberIds,
    required this.createdAt,
  });

  factory MessModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessModel(
      messId: doc.id,
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      description: data['description'] ?? '',
      createdBy: data['createdBy'] ?? '',
      memberIds: List<String>.from(data['memberIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'address': address,
        'description': description,
        'createdBy': createdBy,
        'memberIds': memberIds,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  MessModel copyWith({
    String? name,
    String? address,
    String? description,
    List<String>? memberIds,
  }) =>
      MessModel(
        messId: messId,
        name: name ?? this.name,
        address: address ?? this.address,
        description: description ?? this.description,
        createdBy: createdBy,
        memberIds: memberIds ?? this.memberIds,
        createdAt: createdAt,
      );
}

