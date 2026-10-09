/// `TokenResponse` / `AuthResponse` — weft-backend/app/schemas/auth.py.
library;

import 'package:equatable/equatable.dart';

import 'json_utils.dart';
import 'user_profile.dart';

/// `POST /auth/refresh` body; also the token half of [AuthResponse].
/// Never log or `toString()` these values.
class AuthTokens extends Equatable {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    this.tokenType = 'bearer',
  });

  factory AuthTokens.fromJson(Json json) => AuthTokens(
    accessToken: requireString(json, 'access_token'),
    refreshToken: requireString(json, 'refresh_token'),
    tokenType: optString(json, 'token_type') ?? 'bearer',
    expiresIn: requireInt(json, 'expires_in'),
  );

  final String accessToken;
  final String refreshToken;
  final String tokenType;

  /// Access token lifetime in seconds (86400 = 24 h).
  final int expiresIn;

  @override
  List<Object?> get props => [accessToken, refreshToken, tokenType, expiresIn];

  @override
  String toString() => 'AuthTokens(<redacted>, expiresIn: $expiresIn)';
}

/// `POST /auth/login` (and the future OAuth endpoints): tokens + profile.
class AuthResponse extends Equatable {
  const AuthResponse({required this.tokens, required this.user});

  factory AuthResponse.fromJson(Json json) => AuthResponse(
    tokens: AuthTokens.fromJson(json),
    user: UserProfile.fromJson(requireField<Json>(json, 'user')),
  );

  final AuthTokens tokens;
  final UserProfile user;

  @override
  List<Object?> get props => [tokens, user];
}
