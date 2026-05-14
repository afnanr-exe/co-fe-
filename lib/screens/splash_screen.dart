import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _rotateController;
  late AnimationController _bylineController;
  late AnimationController _fadeOutController;

  late Animation<double> _logoOpacity;
  late Animation<double> _logoRotation;
  late Animation<double> _logoScale;
  late Animation<double> _bylineOpacity;
  late Animation<double> _fadeOut;

  String _typedText = '';
  final String _fullText = 'co:fe';
  Timer? _typeTimer;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _bylineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeOutController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeIn),
    );
    _logoRotation = Tween<double>(begin: pi / 2, end: 0).animate(
      CurvedAnimation(
        parent: _rotateController,
        curve: Curves.easeInOutCubic,
      ),
    );
    _logoScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _rotateController, curve: Curves.easeOutBack),
    );
    _bylineOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _bylineController, curve: Curves.easeIn),
    );
    _fadeOut = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _fadeOutController, curve: Curves.easeOut),
    );

    _runSequence();
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _logoController.forward();

    await Future.delayed(const Duration(milliseconds: 200));
    _rotateController.forward();

    await Future.delayed(const Duration(milliseconds: 600));
    _startTypewriter();

    await Future.delayed(const Duration(milliseconds: 700));
    _bylineController.forward();

    await Future.delayed(const Duration(milliseconds: 1400));
    _fadeOutController.forward();

    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  void _startTypewriter() {
    int index = 0;
    _typeTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (index < _fullText.length) {
        setState(() {
          _typedText = _fullText.substring(0, index + 1);
        });
        index++;
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _rotateController.dispose();
    _bylineController.dispose();
    _fadeOutController.dispose();
    _typeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: FadeTransition(
        opacity: _fadeOut,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              FadeTransition(
                opacity: _logoOpacity,
                child: AnimatedBuilder(
                  animation: _rotateController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _logoRotation.value,
                      child: Transform.scale(
                        scale: _logoScale.value,
                        child: child,
                      ),
                    );
                  },
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 200,
                    height: 200,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _typedText,
                    style: const TextStyle(
                      color: Color(0xFFF5F5F5),
                      fontSize: 48,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 6,
                    ),
                  ),
                  const SizedBox(width: 12),
                  FadeTransition(
                    opacity: _bylineOpacity,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(
                              text: 'by ',
                              style: TextStyle(
                                color: Color(0xFF666666),
                                fontSize: 16,
                                letterSpacing: 2,
                              ),
                            ),
                            TextSpan(
                              text: 'ASTAR',
                              style: TextStyle(
                                color: Color(0xFF888888),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}