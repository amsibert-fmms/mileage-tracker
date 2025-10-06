import 'geo_point.dart';

/// Represents a location saved by the user for quick reuse when logging trips.
class SavedLocation {
  const SavedLocation({
    required this.id,
    required this.label,
    required this.position,
    this.addressLine,
    this.notes,
  });

  /// Unique identifier for persistence. Can be generated with UUIDs.
  final String id;

  /// User facing label such as "Home" or "Client HQ".
  final String label;

  /// Geographic coordinates of the saved place.
  final GeoPoint position;

  /// Optional human readable address to surface in the UI.
  final String? addressLine;

  /// Optional notes about the location.
  final String? notes;

  SavedLocation copyWith({
    String? id,
    String? label,
    GeoPoint? position,
    String? addressLine,
    String? notes,
  }) {
    return SavedLocation(
      id: id ?? this.id,
      label: label ?? this.label,
      position: position ?? this.position,
      addressLine: addressLine ?? this.addressLine,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'position': position.toJson(),
        'addressLine': addressLine,
        'notes': notes,
      };

  factory SavedLocation.fromJson(Map<String, dynamic> json) {
    return SavedLocation(
      id: json['id'] as String,
      label: json['label'] as String,
      position: GeoPoint.fromJson(json['position'] as Map<String, dynamic>),
      addressLine: json['addressLine'] as String?,
      notes: json['notes'] as String?,
    );
  }

  @override
  String toString() => 'SavedLocation(label: $label, position: $position)';

  @override
  bool operator ==(Object other) {
    return other is SavedLocation &&
        other.id == id &&
        other.label == label &&
        other.position == position &&
        other.addressLine == addressLine &&
        other.notes == notes;
  }

  @override
  int get hashCode =>
      Object.hash(id, label, position, addressLine, notes);
}
