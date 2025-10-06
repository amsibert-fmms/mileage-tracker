/// Representation of a vehicle that can be associated with a trip.
class Vehicle {
  const Vehicle({
    required this.id,
    required this.displayName,
    this.make,
    this.model,
    this.year,
    this.licensePlate,
    this.defaultOdometer,
    this.isActive = false,
  });

  final String id;
  final String displayName;
  final String? make;
  final String? model;
  final int? year;
  final String? licensePlate;

  /// Optional odometer value that will pre-fill a new trip.
  final double? defaultOdometer;

  /// Whether this vehicle is the currently active one for quick selection.
  final bool isActive;

  Vehicle copyWith({
    String? id,
    String? displayName,
    String? make,
    String? model,
    int? year,
    String? licensePlate,
    double? defaultOdometer,
    bool? isActive,
  }) {
    return Vehicle(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      licensePlate: licensePlate ?? this.licensePlate,
      defaultOdometer: defaultOdometer ?? this.defaultOdometer,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
        'make': make,
        'model': model,
        'year': year,
        'licensePlate': licensePlate,
        'defaultOdometer': defaultOdometer,
        'isActive': isActive,
      };

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      make: json['make'] as String?,
      model: json['model'] as String?,
      year: json['year'] as int?,
      licensePlate: json['licensePlate'] as String?,
      defaultOdometer: (json['defaultOdometer'] as num?)?.toDouble(),
      isActive: json['isActive'] as bool? ?? false,
    );
  }

  @override
  String toString() => 'Vehicle($displayName)';

  @override
  bool operator ==(Object other) {
    return other is Vehicle &&
        other.id == id &&
        other.displayName == displayName &&
        other.make == make &&
        other.model == model &&
        other.year == year &&
        other.licensePlate == licensePlate &&
        other.defaultOdometer == defaultOdometer &&
        other.isActive == isActive;
  }

  @override
  int get hashCode => Object.hash(
      id, displayName, make, model, year, licensePlate, defaultOdometer, isActive);
}
