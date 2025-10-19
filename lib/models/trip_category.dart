/// Categorisation for a recorded trip.
enum TripCategory { business, personal, commute, other }

extension TripCategoryDisplay on TripCategory {
  String get label {
    switch (this) {
      case TripCategory.business:
        return 'Business';
      case TripCategory.personal:
        return 'Personal';
      case TripCategory.commute:
        return 'Commute';
      case TripCategory.other:
        return 'Other';
    }
  }
}
