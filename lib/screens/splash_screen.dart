import 'package:flutter/material.dart';

/// Shown while [AuthProvider] is resolving session state (cold start, or an
/// interactive sign-in in flight). The native pre-Flutter splash can only
/// show a size-capped, centered icon (a platform limit, not a choice), so
/// this is where the full NooLure.png wordmark — uncropped, pinned to the
/// top — actually appears.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF555A50),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            Image.asset(
              'assets/icons/NooLure.png',
              width: double.infinity,
              fit: BoxFit.fitWidth,
            ),
            const Spacer(),
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
