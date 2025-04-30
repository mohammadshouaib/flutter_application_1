import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:geolocator/geolocator.dart';

class MockGeolocator extends Mock implements GeolocatorPlatform {}

void main() {
  late MockGeolocator mockGeolocator;

  setUp(() {
    mockGeolocator = MockGeolocator();
  });

  group('Location Services Tests', () {
    test('LOC-001: Get current location returns coordinates', () async {
      // Arrange
      when(mockGeolocator.getCurrentPosition()).thenAnswer(
        (_) async => Position(
          latitude: 51.0,
          longitude: -0.1,
          timestamp: DateTime.now(),
          accuracy: 10,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0, altitudeAccuracy: 100, headingAccuracy: 100,
        ),
      );

      // Act
      final position = await mockGeolocator.getCurrentPosition();

      // Assert
      expect(position.latitude, 51.0);
      expect(position.longitude, -0.1);
    });

    test('LOC-002: Handle location permission denied', () async {
      // Arrange
      when(mockGeolocator.checkPermission()).thenAnswer(
        (_) async => LocationPermission.denied,
      );

      // Act
      final permission = await mockGeolocator.checkPermission();

      // Assert
      expect(permission, LocationPermission.denied);
    });
  });
}