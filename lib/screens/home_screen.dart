import 'package:flutter/material.dart';
import '../services/theme_service.dart';
import 'dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: Theme.of(context).brightness == Brightness.dark
                ? [
                    const Color(0xFF1F2937),
                    const Color(0xFF111827),
                  ]
                : [
                    const Color(0xFFF8FAFC),
                    const Color(0xFFE2E8F0),
                  ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 60),
                  _buildHeroSection(),
                  const SizedBox(height: 80),
                  _buildFeaturesSection(),
                  const SizedBox(height: 60),
                  _buildCallToAction(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              Icons.auto_stories,
              color: Theme.of(context).colorScheme.primary,
              size: 32,
            ),
            const SizedBox(width: 12),
            Text(
              'Enchanted Chronicles',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        IconButton(
          onPressed: ThemeService.instance.toggleTheme,
          icon: Icon(
            Theme.of(context).brightness == Brightness.dark
                ? Icons.light_mode
                : Icons.dark_mode,
          ),
        ),
      ],
    );
  }

  Widget _buildHeroSection() {
  return Column(
    children: [
      Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
          ),
          borderRadius: BorderRadius.circular(60),
        ),
        child: const Icon(
          Icons.auto_stories,
          size: 60,
          color: Colors.white,
        ),
      ),
      const SizedBox(height: 32),
      Text(
        'Enchanted\nChronicles',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.bold,
              height: 1.1,
            ),
      ),
      const SizedBox(height: 24),
      Text(
        'Step into a realm where your thoughts become magical tales. Write private diary entries and share your adventures with the world.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              height: 1.5,
            ),
      ),
      const SizedBox(height: 40),

      // ✅ COMPACT BUTTONS
      Wrap(
        spacing: 16,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: [
          ElevatedButton.icon(
            onPressed: _navigateToDashboard,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.auto_stories),
            label: const Text(
              'Begin Journey',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          OutlinedButton.icon(
            onPressed: _navigateToDashboard,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.login),
            label: const Text(
              'Return',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    ],
  );
}


  Widget _buildFeaturesSection() {
    final features = [
      {
        'icon': Icons.lock,
        'title': 'Enchanted Diary',
        'description': 'Write private entries protected by magical locks. Only you can access your deepest thoughts.',
        'color': Theme.of(context).colorScheme.primary,
      },
      {
        'icon': Icons.public,
        'title': 'Mystical Blog',
        'description': 'Share your adventures with the world through beautifully crafted public posts.',
        'color': Theme.of(context).colorScheme.secondary,
      },
      {
        'icon': Icons.calendar_today,
        'title': 'Chronicle Calendar',
        'description': 'Track your writing journey with a magical calendar that shows your daily entries.',
        'color': Colors.amber,
      },
    ];

    return Column(
      children: [
        Text(
          'Magical Features',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 32),
        ...features.map((feature) {
          return Container(
            margin: const EdgeInsets.only(bottom: 24),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: (feature['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: Icon(
                        feature['icon'] as IconData,
                        color: feature['color'] as Color,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      feature['title'] as String,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      feature['description'] as String,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildCallToAction() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) => 
                const Icon(
                  Icons.star,
                  color: Colors.amber,
                  size: 24,
                )
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Ready to Begin Your Magical Journey?',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Join thousands of writers who have discovered the magic of chronicling their lives in our enchanted realm.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white70,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _buildBadge('✨ Secure & Private'),
                _buildBadge('🏰 Fantasy Themed'),
                _buildBadge('📱 Mobile Friendly'),
                _buildBadge('📅 Calendar Tracking'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _navigateToDashboard() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const DashboardScreen()),
    );
  }
}
