/// Small, strict JSON helpers shared by the hand-written model parsers.
///
/// Hand-written `fromJson`/`toJson` (no build_runner) so there are no
/// generated files to keep in sync. Required fields throw [FormatException]
/// with the field name, so a contract drift fails loudly in tests rather than
/// as a null deep in the UI.
library;

typedef Json = Map<String, dynamic>;

T requireField<T>(Json json, String key) {
  final value = json[key];
  if (value is T) return value;
  throw FormatException(
    'Expected "$key" to be $T but got ${value.runtimeType}',
    json,
  );
}

String requireString(Json json, String key) => requireField<String>(json, key);

String? optString(Json json, String key) {
  final value = json[key];
  return value is String ? value : null;
}

int requireInt(Json json, String key) {
  final value = json[key];
  if (value is int) return value;
  if (value is num) return value.toInt();
  throw FormatException('Expected "$key" to be int', json);
}

int? optInt(Json json, String key) {
  final value = json[key];
  return value is num ? value.toInt() : null;
}

/// Pydantic serialises floats as JSON numbers, which may arrive as int.
double requireDouble(Json json, String key) {
  final value = json[key];
  if (value is num) return value.toDouble();
  throw FormatException('Expected "$key" to be a number', json);
}

bool requireBool(Json json, String key) => requireField<bool>(json, key);

DateTime requireDate(Json json, String key) {
  final value = json[key];
  if (value is String) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed;
  }
  throw FormatException('Expected "$key" to be an ISO 8601 timestamp', json);
}

DateTime? optDate(Json json, String key) {
  final value = json[key];
  return value is String ? DateTime.tryParse(value) : null;
}

List<T> requireList<T>(Json json, String key, T Function(Json) parse) {
  final value = json[key];
  if (value is List) {
    return value.map((e) => parse(e as Json)).toList(growable: false);
  }
  throw FormatException('Expected "$key" to be a list', json);
}

/// Server timestamps are UTC; send them back the same way.
String? dateToJson(DateTime? value) => value?.toUtc().toIso8601String();
