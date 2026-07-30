import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Animated Splash Screen for Android IDE.
/// Features scale & fade-in transitions, pulsing glow, Electric Cyan progress bar,
/// and automatic navigation to the main workspace route.
class SplashPage extends StatefulWidget {
  final VoidCallback? onComplete;

  const SplashPage({super.key, this.onComplete});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late AnimationController _introController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();

    // Intro scale & fade animation
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _introController,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _introController,
      curve: Curves.easeIn,
    );

    // Continuous pulsing glow animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 8.0, end: 24.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _introController.forward();

    // Auto-navigate after 2.5 seconds
    _navigationTimer = Timer(const Duration(milliseconds: 2500), _navigateToHome);
  }

  void _navigateToHome() {
    if (!mounted) return;
    if (widget.onComplete != null) {
      widget.onComplete!();
    } else {
      // Fallback navigation
      Navigator.of(context).pushReplacementNamed('/');
    }
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _introController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117), // Obsidian Dark
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),

            // Animated Logo Container
            AnimatedBuilder(
              animation: Listenable.merge([_introController, _pulseController]),
              builder: (context, child) {
                return ScaleTransition(
                  scale: _scaleAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: const Color(0xFF161B22), // Deep Navy
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: const Color(0xFF30363D), width: 2), // Slate Border
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00E5FF).withValues(alpha: 0.35), // Electric Cyan glow
                            blurRadius: _pulseAnimation.value,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(24),
                      child: SvgPicture.asset(
                        'assets/icons/logo.svg',
                        width: 92,
                        height: 92,
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            // Animated Titles
            FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  const Text(
                    'Android IDE',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF0F6FC), // Crisp White
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Pocket-sized Mobile IDE Engine',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8B949E), // Muted Steel
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Electric Cyan Progress Indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 80.0, vertical: 48.0),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: const SizedBox(
                      height: 3,
                      child: LinearProgressIndicator(
                        backgroundColor: Color(0xFF161B22),
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00E5FF)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Initializing workspace...',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF8B949E),
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
