/// `UserProfile` and `RegisterResponse` — weft-backend/app/schemas/user.py and
/// schemas/auth.py. Field names are the backend's, in snake_case on the wire.
library;

import 'package:equatable/equatable.dart';

import '../../core/l10n/app_language.dart';
import 'enums.dart';
import 'json_utils.dart';

/// `GET /users/me`, and `user` inside the login response. Carries no
/// credential material.
class UserProfile extends Equatable {
  const UserProfile({
    required this.id,
    required this.role,
    required this.trustScore,
    required this.totalPoints,
    required this.isAnonymous,
    required this.preferredLang,
    required this.createdAt,
    this.email,
    this.name,
    this.title,
  });

  factory UserProfile.fromJson(Json json) => UserProfile(
    id: requireString(json, 'id'),
    email: optString(json, 'email'),
    name: optString(json, 'name'),
    role: UserRole.fromWire(optString(json, 'role')),
    trustScore: requireDouble(json, 'trust_score'),
    totalPoints: requireInt(json, 'total_points'),
    title: optString(json, 'title'),
    isAnonymous: requireBool(json, 'is_anonymous'),
    preferredLang:
        AppLanguage.tryParse(optString(json, 'preferred_lang')) ??
        AppLanguage.fallback,
    createdAt: requireDate(json, 'created_at'),
  );

  final String id;

  /// Null for anonymous or phone-only accounts.
  final String? email;

  /// Null for anonymous accounts.
  final String? name;
  final UserRole role;

  /// 0–100: percentage of this user's reports that were resolved.
  final double trustScore;

  /// May be negative after spam penalties.
  final int totalPoints;

  /// Gamification title (Newcomer, Helper, Civic Contributor, City Guardian,
  /// City Hero); null until the gamification service (task 4.2) sets one.
  final String? title;
  final bool isAnonymous;
  final AppLanguage preferredLang;
  final DateTime createdAt;

  /// Best human label for greetings/avatars.
  String get displayName {
    final n = name?.trim();
    if (n != null && n.isNotEmpty) return n;
    final e = email;
    if (e != null && e.isNotEmpty) return e.split('@').first;
    return 'Citizen';
  }

  Json toJson() => {
    'id': id,
    'email': email,
    'name': name,
    'role': role.wire,
    'trust_score': trustScore,
    'total_points': totalPoints,
    'title': title,
    'is_anonymous': isAnonymous,
    'preferred_lang': preferredLang.code,
    'created_at': dateToJson(createdAt),
  };

  @override
  List<Object?> get props => [
    id,
    email,
    name,
    role,
    trustScore,
    totalPoints,
    title,
    isAnonymous,
    preferredLang,
    createdAt,
  ];
}

/// `POST /auth/register` 201 body. NOT tokens — the client logs in next.
class RegisterResponse extends Equatable {
  const RegisterResponse({
    required this.userId,
    required this.email,
    required this.name,
    required this.role,
    required this.createdAt,
  });

  factory RegisterResponse.fromJson(Json json) => RegisterResponse(
    userId: requireString(json, 'user_id'),
    email: requireString(json, 'email'),
    name: requireString(json, 'name'),
    role: UserRole.fromWire(optString(json, 'role')),
    createdAt: requireDate(json, 'created_at'),
  );

  final String userId;
  final String email;
  final String name;
  final UserRole role;
  final DateTime createdAt;

  @override
  List<Object?> get props => [userId, email, name, role, createdAt];
}
