import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naturaai/features/auth/view/signup_page.dart';

void main() {
  testWidgets('SignupPage UI renders correctly and handles input',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SignupPage(),
        ),
      ),
    );

    expect(find.byKey(const Key('nameField')), findsOneWidget);
    expect(find.byKey(const Key('emailField')), findsOneWidget);
    expect(find.byKey(const Key('passwordField')), findsOneWidget);
    expect(find.byKey(const Key('confirmPasswordField')), findsOneWidget);
    expect(find.text('Sign Up'), findsOneWidget);
    expect(find.text("Already have an account? Log in"), findsOneWidget);


    await tester.enterText(find.byKey(const Key('nameField')), 'Test User');
    await tester.enterText(find.byKey(const Key('emailField')), 'test@example.com');
    await tester.enterText(find.byKey(const Key('passwordField')), 'password123');
    await tester.enterText(find.byKey(const Key('confirmPasswordField')), 'password123');

    await tester.tap(find.text('Sign Up'));
    await tester.pump(); 
  });
}