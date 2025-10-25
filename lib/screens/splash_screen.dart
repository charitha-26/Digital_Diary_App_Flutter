import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/theme_service.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await ThemeService.instance.init();
    
    // Wait for splash animation
    await Future.delayed(const Duration(seconds: 3));
    
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.auto_stories,
                size: 80,
                color: Colors.white,
              )
                  .animate()
                  .scale(duration: 1000.ms)
                  .then()
                  .shimmer(duration: 2000.ms),
              const SizedBox(height: 24),
              Text(
                'Enchanted Chronicles',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              )
                  .animate()
                  .fadeIn(delay: 500.ms, duration: 1000.ms)
                  .slideY(begin: 0.3, end: 0),
              const SizedBox(height: 16),
              Text(
                'Your magical diary awaits...',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white70,
                ),
              )
                  .animate()
                  .fadeIn(delay: 1000.ms, duration: 1000.ms),
            ],
          ),
        ),
      ),
    );
  }
}
