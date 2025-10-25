import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/entry.dart';
import 'diary_screen.dart';
import 'blog_screen.dart';
import 'calendar_screen.dart';
import '../services/theme_service.dart';
import 'home_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _diaryCount = 0;
  int _blogCount = 0;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    final diaryEntries = await DatabaseService.instance.getEntriesByType(EntryType.diary);
    final blogEntries = await DatabaseService.instance.getEntriesByType(EntryType.blog);
    
    setState(() {
      _diaryCount = diaryEntries.length;
      _blogCount = blogEntries.length;
    });
  }

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
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 40),
                _buildWelcomeSection(),
                const SizedBox(height: 40),
                Expanded(child: _buildMenuGrid()),
              ],
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
        Row(
          children: [
            IconButton(
              onPressed: ThemeService.instance.toggleTheme,
              icon: Icon(
                Theme.of(context).brightness == Brightness.dark
                    ? Icons.light_mode
                    : Icons.dark_mode,
              ),
            ),
            IconButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                );
              },
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWelcomeSection() {
    return Column(
      children: [
        Text(
          'Welcome to Your Magical Realm',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Choose your adventure below',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuGrid() {
    final menuItems = [
      {
        'title': 'Diary Writing',
        'icon': Icons.lock,
        'color': Theme.of(context).colorScheme.primary,
        'description': '$_diaryCount private entries',
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DiaryScreen()),
        ).then((_) => _loadCounts()),
      },
      {
        'title': 'Blog Posts',
        'icon': Icons.public,
        'color': Theme.of(context).colorScheme.secondary,
        'description': '$_blogCount blog posts',
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const BlogScreen()),
        ).then((_) => _loadCounts()),
      },
      {
        'title': 'Calendar',
        'icon': Icons.calendar_today,
        'color': Colors.green,
        'description': 'Track your writing journey',
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CalendarScreen()),
        ),
      },
      {
        'title': 'Settings',
        'icon': Icons.settings,
        'color': Colors.orange,
        'description': 'Customize your experience',
        'onTap': () => _showSettingsDialog(),
      },
    ];

return GridView.builder(
  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    crossAxisSpacing: 16,
    mainAxisSpacing: 16,
    mainAxisExtent: 120, // ✅ This sets fixed height for each block
  ),
  itemCount: menuItems.length,
  itemBuilder: (context, index) {
    final item = menuItems[index];
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: item['onTap'] as VoidCallback,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(8), // ✅ reduced from 20
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,  // ✅ smaller
                height: 40,
                decoration: BoxDecoration(
                  color: (item['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  item['icon'] as IconData,
                  color: item['color'] as Color,
                  size: 20, // ✅ smaller
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item['title'] as String,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                item['description'] as String,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  },
);
}

 void _showSettingsDialog() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Settings'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            title: const Text('Toggle Theme'),
            onTap: () {
              ThemeService.instance.toggleTheme();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

}
