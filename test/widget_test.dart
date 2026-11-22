import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartschool/app.dart'; // ✅ import the correct file

void main() {
  testWidgets('App starts and shows login screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SmartSchoolApp());

    // Verify that the login screen is displayed.
    // The login screen has a "Welcome Back" text.
    expect(find.text('Welcome Back'), findsOneWidget);

    // You can also verify that the login button is present.
    expect(find.widgetWithText(ElevatedButton, 'Sign In'), findsOneWidget);
  });
}
