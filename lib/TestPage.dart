import 'package:flutter/material.dart';

/// This is the widget you will navigate to from FlutterFlow.
/// Its ONLY purpose is to block the back gesture from its parent navigator.
class TestPage extends StatelessWidget {
  const TestPage({super.key});

  @override
  Widget build(BuildContext context) {
    // This is the core logic we are testing.
    // This WillPopScope uses the `context` from the navigator that pushed it
    // (i.e., FlutterFlow's navigator). It wraps our entire mini-app.
    return WillPopScope(
      onWillPop: () async {
        // We print to the console to prove this code is being executed.
        print("--- BACK GESTURE INTERCEPTED & BLOCKED ---");
        return false; // This should prevent the back navigation.
      },
      child: const MaterialApp(
        // This is a new, self-contained app.
        debugShowCheckedModeBanner: false,
        home: MinimalScreen(),
      ),
    );
  }
}

/// A very simple screen to display inside our test app.
class MinimalScreen extends StatelessWidget {
  const MinimalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: const Text('Minimal Test Page'),
        automaticallyImplyLeading: false, // Ensure no back arrow appears
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text(
            'This is the test page. Try to swipe back now. It should not work. Check your debug console for a message.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
        ),
      ),
    );
  }
}
