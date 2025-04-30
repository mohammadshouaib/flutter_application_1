// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_application_1/Pages/RoutePage/RouteRecommendationsPage.dart';
import 'package:flutter_application_1/Pages/SettingsPage/Settings.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/main.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

class MockAuthService extends Mock implements AuthService {
  get currentUser => null;
}

void main() {
  testWidgets('AUTH-004: Logout confirmation dialog appears', (WidgetTester tester) async {
    // Build our app and trigger a frame
    final mockAuth = MockAuthService();
    when(mockAuth.currentUser).thenReturn(null);

    await tester.pumpWidget(
      Provider<AuthService>.value(
        value: mockAuth,
        child: const MaterialApp(home: SettingsPage()),
      ),
    );

    // Tap the logout button
    await tester.tap(find.text('Log Out'));
    await tester.pump();

    // Verify the dialog appears
    expect(find.text('Confirm Logout'), findsOneWidget);
    expect(find.text('Are you sure you want to log out?'), findsOneWidget);
  });

  testWidgets('ROUTE-004: Route details screen shows correctly', (WidgetTester tester) async {
    // Build route details screen
    await tester.pumpWidget(
      MaterialApp(
        home: RouteFeedPage(
        ),
      ),
    );

    // Verify content
    expect(find.text('Test Route'), findsOneWidget);
    expect(find.text('5.0 km'), findsOneWidget);
    expect(find.text('Medium'), findsOneWidget);
  });
}

