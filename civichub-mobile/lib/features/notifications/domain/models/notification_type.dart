enum CitizenNotificationType {
  reportAssigned('REPORT_ASSIGNED', 'Report assigned'),
  reportStatusChanged('REPORT_STATUS_CHANGED', 'Report status changed'),
  unknown('UNKNOWN', 'Notification');

  const CitizenNotificationType(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static CitizenNotificationType fromApiValue(Object? value) {
    if (value is! String) {
      return CitizenNotificationType.unknown;
    }
    return CitizenNotificationType.values.firstWhere(
      (type) => type.apiValue == value,
      orElse: () => CitizenNotificationType.unknown,
    );
  }
}
