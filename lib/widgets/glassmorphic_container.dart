import 'dart:ui'; // Required for ImageFilter
import 'package:flutter/material.dart';

class GlassmorphicContainer extends StatelessWidget {
  final double width;
  final double height;
  final Widget child;

  const GlassmorphicContainer({
    super.key,
    required this.width,
    required this.height,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20.0),
      child: Container(
        width: width,
        height: height,
        color: Colors
            .transparent, // Important: The container itself should be transparent
        // Stack is used to layer the blur, the gradient, and the content
        child: Stack(
          children: [
            // 1. The blur effect
            BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 4.0, // Adjust the blur intensity
                sigmaY: 4.0,
              ),
              child:
                  Container(), // The child is empty as the filter affects what's behind it
            ),

            // 2. The semi-transparent overlay and border
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.0),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1), // Subtle border
                  width: 1.5,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    // Semi-transparent colors for the glass effect
                    Colors.white.withOpacity(0.15),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
              ),
            ),

            // 3. The actual content of the container
            Center(child: child),
          ],
        ),
      ),
    );
  }
}
