import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String userId;
  final String displayName;
  final String authProvider; // 'apple' or 'google'
  final Map<String, dynamic> characterCustomization;
  final String relationshipType; // 'couple', 'bestfriend', 'family', 'adventure'
  final DateTime createdAt;

  UserModel({
    required this.userId,
    required this.displayName,
    required this.authProvider,
    this.characterCustomization = const {},
    this.relationshipType = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      userId: map['user_id'] ?? '',
      displayName: map['display_name'] ?? '',
      authProvider: map['auth_provider'] ?? '',
      characterCustomization:
          Map<String, dynamic>.from(map['character_customization'] ?? {}),
      relationshipType: map['relationship_type'] ?? '',
      createdAt: (map['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'display_name': displayName,
      'auth_provider': authProvider,
      'character_customization': characterCustomization,
      'relationship_type': relationshipType,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  UserModel copyWith({
    String? displayName,
    Map<String, dynamic>? characterCustomization,
    String? relationshipType,
  }) {
    return UserModel(
      userId: userId,
      displayName: displayName ?? this.displayName,
      authProvider: authProvider,
      characterCustomization:
          characterCustomization ?? this.characterCustomization,
      relationshipType: relationshipType ?? this.relationshipType,
      createdAt: createdAt,
    );
  }
}
