import 'package:flutter/material.dart';
import 'package:TBConsult/outer_shell.dart';
import 'package:TBConsult/core/theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Initial slide from bottom to center
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 6),
      end: const Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    // Fade in
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    ));

    _controller.forward();

    _navigateNext();
  }

  Future<void> _navigateNext() async {
    // Wait for the animation to complete and hold slightly
    await Future.delayed(const Duration(milliseconds: 2800));
    
    if (!mounted) return;

    // Direct routing to the OuterShell since there is no Auth needed right now
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const OuterShell()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppColors.background,
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Image.asset(
                'assets/images/logo.png', // Main Splash Image
                width: 160,
              ),
            ),
          ),
        ),
      ),
    );
  }
}