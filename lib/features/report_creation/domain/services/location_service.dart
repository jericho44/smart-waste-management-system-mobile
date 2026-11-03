import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

/// GPS coordinates wrapper.
class UserLocation {
  final double latitude;
  final double longitude;
  final double? accuracy;

  const UserLocation({
    required this.latitude,
    required this.longitude,
    this.accuracy,
  });

  @override
  String toString() =>
      '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
}

/// Abstract contract for device GPS location retrieval.
abstract class LocationService {
  /// Check if system location services (GPS hardware) are enabled.
  Future<bool> isLocationServiceEnabled();

  /// Check current app location permission state.
  Future<LocationPermission> checkPermission();

  /// Request location permission from the operating system.
  Future<LocationPermission> requestPermission();

  /// Retrieve the current GPS coordinates.
  Future<UserLocation> getCurrentLocation();

  /// Open device app permission settings.
  Future<bool> openAppSettings();

  /// Open device location settings.
  Future<bool> openLocationSettings();
}

/// Production implementation of LocationService using geolocator.
class GeolocatorLocationService implements LocationService {
  const GeolocatorLocationService();

  @override
  Future<bool> isLocationServiceEnabled() {
    return Geolocator.isLocationServiceEnabled();
  }

  @override
  Future<LocationPermission> checkPermission() {
    return Geolocator.checkPermission();
  }

  @override
  Future<LocationPermission> requestPermission() {
    return Geolocator.requestPermission();
  }

  @override
  Future<UserLocation> getCurrentLocation() async {
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );

    return UserLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
    );
  }

  @override
  Future<bool> openAppSettings() {
    return Geolocator.openAppSettings();
  }

  @override
  Future<bool> openLocationSettings() {
    return Geolocator.openLocationSettings();
  }
}

/// Riverpod provider for LocationService
final locationServiceProvider = Provider<LocationService>((ref) {
  return const GeolocatorLocationService();
});

