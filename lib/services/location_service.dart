import 'package:geolocator/geolocator.dart';

class LocationService {

  // Check whether location service is enabled
  Future<bool> isLocationEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Check and request location permission
  Future<LocationPermission> checkPermission() async {
    LocationPermission permission =
    await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission;
  }

  // Get current device location
  Future<Position?> getCurrentLocation() async {

    bool serviceEnabled = await isLocationEnabled();

    if (!serviceEnabled) {
      return null;
    }

    LocationPermission permission = await checkPermission();

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
      ),
    );
  }
}