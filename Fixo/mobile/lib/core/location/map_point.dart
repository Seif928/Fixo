class ServiceMapPoint {
  ServiceMapPoint(this.latitude, this.longitude) {
    if (!latitude.isFinite ||
        !longitude.isFinite ||
        latitude.abs() > 90 ||
        longitude.abs() > 180) {
      throw ArgumentError('Invalid map coordinate.');
    }
  }
  final double latitude, longitude;
}
