import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
//import 'dart:math';

void main() {
  runApp(const EnchantedChroniclesApp());
}

// Authentication Service
class AuthService {
  static const String _usersKey = 'users';
  static const String _currentUserKey = 'current_user';

  static Future<bool> signup(String email, String password, String name) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey) ?? '{}';
    final users = Map<String, dynamic>.from(json.decode(usersJson));
    
    if (users.containsKey(email)) {
      return false; // User already exists
    }
    
    users[email] = {
      'password': password,
      'name': name,
      'created_at': DateTime.now().toIso8601String(),
    };
    
    await prefs.setString(_usersKey, json.encode(users));
    await prefs.setString(_currentUserKey, email);
    return true;
  }

  static Future<bool> login(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey) ?? '{}';
    final users = Map<String, dynamic>.from(json.decode(usersJson));
    
    if (users.containsKey(email) && users[email]['password'] == password) {
      await prefs.setString(_currentUserKey, email);
      return true;
    }
    return false;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
  }

  static Future<String?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentUserKey);
  }

  static Future<Map<String, dynamic>?> getUserData(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey) ?? '{}';
    final users = Map<String, dynamic>.from(json.decode(usersJson));
    return users[email];
  }
}

// Settings Service
class SettingsService {
  static const String _fontKey = 'font_family';
  static const String _cursorKey = 'cursor_type';

  static Future<String> getFontFamily() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_fontKey) ?? 'Default';
  }

  static Future<void> setFontFamily(String font) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fontKey, font);
  }

  static Future<String> getCursorType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_cursorKey) ?? 'Wand';
  }

  static Future<void> setCursorType(String cursor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cursorKey, cursor);
  }
}

// Entry model with better date handling
class Entry {
  final int id;
  final String title;
  final String content;
  final DateTime date;
  final String type; // 'diary' or 'blog'
  final String? author;
  final String userEmail;

  Entry({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    required this.type,
    this.author,
    required this.userEmail,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'date': date.toIso8601String(),
      'type': type,
      'author': author,
      'userEmail': userEmail,
    };
  }

  factory Entry.fromJson(Map<String, dynamic> json) {
    return Entry(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      date: DateTime.parse(json['date']),
      type: json['type'],
      author: json['author'],
      userEmail: json['userEmail'],
    );
  }
}

// Enhanced Data Store with persistence
class DataStore {
  static final DataStore instance = DataStore._();
  DataStore._();

  static const String _entriesKey = 'entries';
  List<Entry> _entries = [];

  Future<void> loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final entriesJson = prefs.getString(_entriesKey) ?? '[]';
    final entriesList = List<Map<String, dynamic>>.from(json.decode(entriesJson));
    _entries = entriesList.map((e) => Entry.fromJson(e)).toList();
  }

  Future<void> saveEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final entriesJson = json.encode(_entries.map((e) => e.toJson()).toList());
    await prefs.setString(_entriesKey, entriesJson);
  }

  List<Entry> getAllEntries(String userEmail) {
    return _entries.where((e) => e.userEmail == userEmail).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }
  
  List<Entry> getDiaryEntries(String userEmail) {
    return _entries.where((e) => e.type == 'diary' && e.userEmail == userEmail).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }
  
  List<Entry> getBlogEntries(String userEmail) {
    return _entries.where((e) => e.type == 'blog' && e.userEmail == userEmail).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Map<DateTime, List<Entry>> getEntriesGroupedByDate(String userEmail) {
    final entries = getAllEntries(userEmail);
    final Map<DateTime, List<Entry>> groupedEntries = {};

    for (final entry in entries) {
      final dateKey = DateTime(entry.date.year, entry.date.month, entry.date.day);
      if (groupedEntries[dateKey] == null) {
        groupedEntries[dateKey] = [];
      }
      groupedEntries[dateKey]!.add(entry);
    }

    return groupedEntries;
  }

  Future<void> addEntry(Entry entry) async {
    _entries.insert(0, entry);
    await saveEntries();
  }

  int get nextId => _entries.isEmpty ? 1 : _entries.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1;
}

// Magical Cursor Widget
class MagicalCursor extends StatefulWidget {
  final Widget child;
  final String cursorType;

  const MagicalCursor({
    super.key,
    required this.child,
    required this.cursorType,
  });

  @override
  State<MagicalCursor> createState() => _MagicalCursorState();
}

class _MagicalCursorState extends State<MagicalCursor>
    with TickerProviderStateMixin {
  late AnimationController _twinkleController;
  late Animation<double> _twinkleAnimation;
  Offset _cursorPosition = Offset.zero;

  @override
  void initState() {
    super.initState();
    _twinkleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    
    _twinkleAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _twinkleController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _twinkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (event) {
        setState(() {
          _cursorPosition = event.localPosition;
        });
      },
      child: Stack(
        children: [
          widget.child,
          Positioned(
            left: _cursorPosition.dx - 12,
            top: _cursorPosition.dy - 12,
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _twinkleAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _twinkleAnimation.value,
                    child: _buildCursor(),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCursor() {
    switch (widget.cursorType) {
      case 'Star':
        return const Icon(
          Icons.star,
          color: Colors.amber,
          size: 24,
        );
      case 'Heart':
        return const Icon(
          Icons.favorite,
          color: Colors.pink,
          size: 24,
        );
      default: // Wand
        return Transform.rotate(
          angle: 0.785398, // 45 degrees
          child: const Icon(
            Icons.auto_fix_high,
            color: Colors.purple,
            size: 24,
          ),
        );
    }
  }
}

class EnchantedChroniclesApp extends StatefulWidget {
  const EnchantedChroniclesApp({super.key});

  @override
  State<EnchantedChroniclesApp> createState() => _EnchantedChroniclesAppState();
}

class _EnchantedChroniclesAppState extends State<EnchantedChroniclesApp> {
  ThemeMode _themeMode = ThemeMode.dark;
  String _fontFamily = 'Default';
  String _cursorType = 'Wand';

  @override
  void initState() {
    super.initState();
    _loadSettings();
    DataStore.instance.loadEntries();
  }

  Future<void> _loadSettings() async {
    final font = await SettingsService.getFontFamily();
    final cursor = await SettingsService.getCursorType();
    setState(() {
      _fontFamily = font;
      _cursorType = cursor;
    });
  }

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  String _getFontFamily() {
    switch (_fontFamily) {
      case 'Serif':
        return 'serif';
      case 'Monospace':
        return 'monospace';
      case 'Cursive':
        return 'cursive';
      case 'Fantasy':
        return 'fantasy';
      case 'Sans-serif':
        return 'sans-serif';
      default:
        return 'serif';
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Enchanted Chronicles',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C3AED),
          brightness: Brightness.light,
        ),
        fontFamily: _getFontFamily(),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C3AED),
          brightness: Brightness.dark,
        ),
        fontFamily: _getFontFamily(),
      ),
      themeMode: _themeMode,
      home: MagicalCursor(
        cursorType: _cursorType,
        child: AuthWrapper(
          themeMode: _themeMode,
          onThemeToggle: _toggleTheme,
          onSettingsChanged: _loadSettings,
        ),
      ),
    );
  }
}

// Auth Wrapper to handle login state
class AuthWrapper extends StatefulWidget {
  final ThemeMode themeMode;
  final VoidCallback onThemeToggle;
  final VoidCallback onSettingsChanged;

  const AuthWrapper({
    super.key,
    required this.themeMode,
    required this.onThemeToggle,
    required this.onSettingsChanged,
  });

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  String? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    final user = await AuthService.getCurrentUser();
    setState(() {
      _currentUser = user;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentUser == null) {
      return AuthScreen(
        themeMode: widget.themeMode,
        onThemeToggle: widget.onThemeToggle,
        onAuthSuccess: () => _checkAuthState(),
      );
    }

    return DashboardScreen(
      themeMode: widget.themeMode,
      onThemeToggle: widget.onThemeToggle,
      onSettingsChanged: widget.onSettingsChanged,
      userEmail: _currentUser!,
      onLogout: () {
        AuthService.logout();
        _checkAuthState();
      },
    );
  }
}

// Authentication Screen
class AuthScreen extends StatefulWidget {
  final ThemeMode themeMode;
  final VoidCallback onThemeToggle;
  final VoidCallback onAuthSuccess;

  const AuthScreen({
    super.key,
    required this.themeMode,
    required this.onThemeToggle,
    required this.onAuthSuccess,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;

  String _getBackgroundImage() {
    return 'assets/images/castle-twilight.png';
  }

  Future<void> _handleAuth() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showMessage('Please fill in all fields');
      return;
    }

    if (!_isLogin && _nameController.text.isEmpty) {
      _showMessage('Please enter your name');
      return;
    }

    setState(() => _isLoading = true);

    bool success;
    if (_isLogin) {
      success = await AuthService.login(_emailController.text, _passwordController.text);
    } else {
      success = await AuthService.signup(_emailController.text, _passwordController.text, _nameController.text);
    }

    setState(() => _isLoading = false);

    if (success) {
      widget.onAuthSuccess();
    } else {
      _showMessage(_isLogin ? 'Invalid credentials' : 'User already exists');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(_getBackgroundImage()),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.4),
                Colors.black.withOpacity(0.7),
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Card(
                  elevation: 12,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  color: Colors.black.withOpacity(0.8),
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
                            ),
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: const Icon(
                            Icons.auto_stories,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          _isLogin ? 'Welcome Back' : 'Join the Realm',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isLogin 
                            ? 'Enter your credentials to access your chronicles'
                            : 'Create your account to begin your magical journey',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 32),
                        if (!_isLogin) ...[
                          TextField(
                            controller: _nameController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Your magical name',
                              labelStyle: const TextStyle(color: Colors.white70),
                              prefixIcon: const Icon(Icons.person, color: Colors.white70),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.white30),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.white30),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF7C3AED)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        TextField(
                          controller: _emailController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Email',
                            labelStyle: const TextStyle(color: Colors.white70),
                            prefixIcon: const Icon(Icons.email, color: Colors.white70),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.white30),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.white30),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF7C3AED)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            labelStyle: const TextStyle(color: Colors.white70),
                            prefixIcon: const Icon(Icons.lock, color: Colors.white70),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.white30),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.white30),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF7C3AED)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleAuth,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7C3AED),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  _isLogin ? 'Enter the Realm' : 'Begin Journey',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isLogin = !_isLogin;
                              _emailController.clear();
                              _passwordController.clear();
                              _nameController.clear();
                            });
                          },
                          child: Text(
                            _isLogin 
                              ? "Don't have an account? Create one"
                              : "Already have an account? Sign in",
                            style: const TextStyle(
                              color: Color(0xFF7C3AED),
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  final ThemeMode themeMode;
  final VoidCallback onThemeToggle;
  final VoidCallback onSettingsChanged;
  final String userEmail;
  final VoidCallback onLogout;

  const DashboardScreen({
    super.key,
    required this.themeMode,
    required this.onThemeToggle,
    required this.onSettingsChanged,
    required this.userEmail,
    required this.onLogout,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _getBackgroundImage() {
    return widget.themeMode == ThemeMode.light
        ? 'assets/images/castle-dragon-day.png'
        : 'assets/images/hero-castle-night.png';
  }

  bool get _isDarkMode => widget.themeMode == ThemeMode.dark;

  @override
  Widget build(BuildContext context) {
    final diaryCount = DataStore.instance.getDiaryEntries(widget.userEmail).length;
    final blogCount = DataStore.instance.getBlogEntries(widget.userEmail).length;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(_getBackgroundImage()),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: _isDarkMode
                  ? [
                      Colors.black.withOpacity(0.5),
                      Colors.black.withOpacity(0.7),
                    ]
                  : [
                      Colors.black.withOpacity(0.3),
                      Colors.black.withOpacity(0.5),
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
                  Expanded(child: _buildMenuGrid(diaryCount, blogCount)),
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
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.auto_stories,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Enchanted Chronicles',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    offset: Offset(1, 1),
                    blurRadius: 3,
                    color: Colors.black54,
                  ),
                ],
              ),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              onPressed: widget.onThemeToggle,
              icon: Icon(
                _isDarkMode ? Icons.light_mode : Icons.dark_mode,
                color: Colors.white,
              ),
            ),
            IconButton(
              onPressed: widget.onLogout,
              icon: const Icon(
                Icons.logout,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWelcomeSection() {
    return const Column(
      children: [
        Text(
          'Welcome to Your Magical Realm',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                offset: Offset(2, 2),
                blurRadius: 4,
                color: Colors.black54,
              ),
            ],
          ),
        ),
        SizedBox(height: 16),
        Text(
          'Choose your adventure below',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            color: Colors.white70,
            shadows: [
              Shadow(
                offset: Offset(1, 1),
                blurRadius: 2,
                color: Colors.black54,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuGrid(int diaryCount, int blogCount) {
    final menuItems = [
      {
        'title': 'Diary Writing',
        'icon': Icons.lock,
        'color': const Color(0xFF7C3AED),
        'description': '$diaryCount private entries',
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DiaryScreen(
              themeMode: widget.themeMode,
              userEmail: widget.userEmail,
            ),
          ),
        ).then((_) => setState(() {})),
      },
      {
        'title': 'Blog Posts',
        'icon': Icons.public,
        'color': const Color(0xFFEC4899),
        'description': '$blogCount blog posts',
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BlogScreen(
              themeMode: widget.themeMode,
              userEmail: widget.userEmail,
            ),
          ),
        ).then((_) => setState(() {})),
      },
      {
        'title': 'Calendar',
        'icon': Icons.calendar_today,
        'color': const Color(0xFF10B981),
        'description': 'Track your journey',
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CalendarScreen(
              themeMode: widget.themeMode,
              userEmail: widget.userEmail,
            ),
          ),
        ),
      },
      {
        'title': 'Settings',
        'icon': Icons.settings,
        'color': const Color(0xFFF59E0B),
        'description': 'Customize experience',
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SettingsScreen(
              themeMode: widget.themeMode,
              onThemeToggle: widget.onThemeToggle,
              onSettingsChanged: widget.onSettingsChanged,
            ),
          ),
        ),
      },
    ];

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemCount: menuItems.length,
      itemBuilder: (context, index) {
        final item = menuItems[index];
        return Card(
          elevation: 12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          color: Colors.black.withOpacity(0.6),
          child: InkWell(
            onTap: item['onTap'] as VoidCallback,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: (item['color'] as Color).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Icon(
                      item['icon'] as IconData,
                      color: item['color'] as Color,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    item['title'] as String,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item['description'] as String,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
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
}

class DiaryScreen extends StatefulWidget {
  final ThemeMode themeMode;
  final String userEmail;

  const DiaryScreen({
    super.key,
    required this.themeMode,
    required this.userEmail,
  });

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  String _getBackgroundImage() {
    return widget.themeMode == ThemeMode.light
        ? 'assets/images/castle-dragon-day.png'
        : 'assets/images/hero-castle-night.png';
  }

  bool get _isDarkMode => widget.themeMode == ThemeMode.dark;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveEntry() async {
    if (_titleController.text.isNotEmpty && _contentController.text.isNotEmpty) {
      final entry = Entry(
        id: DataStore.instance.nextId,
        title: _titleController.text,
        content: _contentController.text,
        date: DateTime.now(),
        type: 'diary',
        userEmail: widget.userEmail,
      );

      await DataStore.instance.addEntry(entry);
      _titleController.clear();
      _contentController.clear();
      setState(() {});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Diary entry saved! ✨'),
            backgroundColor: Color(0xFF7C3AED),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = DataStore.instance.getDiaryEntries(widget.userEmail);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Private Diary', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(_getBackgroundImage()),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: _isDarkMode
                  ? [
                      Colors.black.withOpacity(0.5),
                      Colors.black.withOpacity(0.7),
                    ]
                  : [
                      Colors.black.withOpacity(0.3),
                      Colors.black.withOpacity(0.5),
                    ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildNewEntryCard(),
                const SizedBox(height: 24),
                _buildEntriesList(entries),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNewEntryCard() {
    return Card(
      elevation: 12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.black.withOpacity(0.7),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.add, color: Color(0xFF7C3AED)),
                SizedBox(width: 8),
                Text(
                  'New Diary Entry',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Entry title...',
                labelStyle: const TextStyle(color: Colors.white70),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white30),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white30),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF7C3AED)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              maxLines: 6,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Dear diary, today...',
                labelStyle: const TextStyle(color: Colors.white70),
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white30),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white30),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF7C3AED)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saveEntry,
                icon: const Icon(Icons.lock),
                label: const Text('Save Private Entry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntriesList(List<Entry> entries) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Diary Entries (${entries.length})',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  offset: Offset(1, 1),
                  blurRadius: 2,
                  color: Colors.black54,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: entries.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        color: Colors.black.withOpacity(0.6),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFF7C3AED).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.lock,
                              color: Color(0xFF7C3AED),
                            ),
                          ),
                          title: Text(
                            entry.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                '${entry.date.day}/${entry.date.month}/${entry.date.year}',
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                entry.content,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                          onTap: () => _showEntryDialog(entry),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock,
            size: 64,
            color: Colors.white30,
          ),
          SizedBox(height: 16),
          Text(
            'No diary entries yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white60,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Start writing your first private entry!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  void _showEntryDialog(Entry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        title: Row(
          children: [
            const Icon(Icons.lock, color: Colors.amber),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                entry.title,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${entry.date.day}/${entry.date.month}/${entry.date.year}',
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                entry.content,
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: Color(0xFF7C3AED)),
            ),
          ),
        ],
      ),
    );
  }
}

class BlogScreen extends StatefulWidget {
  final ThemeMode themeMode;
  final String userEmail;

  const BlogScreen({
    super.key,
    required this.themeMode,
    required this.userEmail,
  });

  @override
  State<BlogScreen> createState() => _BlogScreenState();
}

class _BlogScreenState extends State<BlogScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  String _getBackgroundImage() {
    return widget.themeMode == ThemeMode.light
        ? 'assets/images/castle-dragon-sunset.png'
        : 'assets/images/castle-twilight.png';
  }

  bool get _isDarkMode => widget.themeMode == ThemeMode.dark;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveEntry() async {
    if (_titleController.text.isNotEmpty && _contentController.text.isNotEmpty) {
      final entry = Entry(
        id: DataStore.instance.nextId,
        title: _titleController.text,
        content: _contentController.text,
        date: DateTime.now(),
        type: 'blog',
        author: 'You',
        userEmail: widget.userEmail,
      );

      await DataStore.instance.addEntry(entry);
      _titleController.clear();
      _contentController.clear();
      setState(() {});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Blog post published! 🌟'),
            backgroundColor: Color(0xFFEC4899),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = DataStore.instance.getBlogEntries(widget.userEmail);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Blog Posts', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(_getBackgroundImage()),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: _isDarkMode
                  ? [
                      Colors.black.withOpacity(0.5),
                      Colors.black.withOpacity(0.7),
                    ]
                  : [
                      Colors.black.withOpacity(0.3),
                      Colors.black.withOpacity(0.5),
                    ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildNewEntryCard(),
                const SizedBox(height: 24),
                _buildEntriesList(entries),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNewEntryCard() {
    return Card(
      elevation: 12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.black.withOpacity(0.7),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.add, color: Color(0xFFEC4899)),
                SizedBox(width: 8),
                Text(
                  'New Blog Post',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Blog title...',
                labelStyle: const TextStyle(color: Colors.white70),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white30),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white30),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFEC4899)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              maxLines: 6,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Share your story with the world...',
                labelStyle: const TextStyle(color: Colors.white70),
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white30),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white30),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFEC4899)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saveEntry,
                icon: const Icon(Icons.public),
                label: const Text('Publish Blog Post'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEC4899),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntriesList(List<Entry> entries) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'All Blog Posts (${entries.length})',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  offset: Offset(1, 1),
                  blurRadius: 2,
                  color: Colors.black54,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: entries.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        color: Colors.black.withOpacity(0.6),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEC4899).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.public,
                              color: Color(0xFFEC4899),
                            ),
                          ),
                          title: Text(
                            entry.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    '${entry.date.day}/${entry.date.month}/${entry.date.year}',
                                    style: const TextStyle(
                                      color: Colors.white60,
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (entry.author != null) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        entry.author!,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                entry.content,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Public',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          onTap: () => _showEntryDialog(entry),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.public,
            size: 64,
            color: Colors.white30,
          ),
          SizedBox(height: 16),
          Text(
            'No blog posts yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white60,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Share your first adventure with the world!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  void _showEntryDialog(Entry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        title: Row(
          children: [
            const Icon(Icons.public, color: Colors.green),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                entry.title,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    '${entry.date.day}/${entry.date.month}/${entry.date.year}',
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                    ),
                  ),
                  if (entry.author != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        entry.author!,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              Text(
                entry.content,
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: Color(0xFFEC4899)),
            ),
          ),
        ],
      ),
    );
  }
}

// Calendar Screen
class CalendarScreen extends StatefulWidget {
  final ThemeMode themeMode;
  final String userEmail;

  const CalendarScreen({
    super.key,
    required this.themeMode,
    required this.userEmail,
  });

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDate = DateTime.now();

  String _getBackgroundImage() {
    return widget.themeMode == ThemeMode.light
        ? 'assets/images/castle-dragon-day.png'
        : 'assets/images/hero-castle-night.png';
  }

  bool get _isDarkMode => widget.themeMode == ThemeMode.dark;

  List<Entry> _getEntriesForDay(DateTime day) {
    final entries = DataStore.instance.getAllEntries(widget.userEmail);
    return entries.where((entry) {
      return entry.date.year == day.year &&
             entry.date.month == day.month &&
             entry.date.day == day.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chronicle Calendar', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(_getBackgroundImage()),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: _isDarkMode
                  ? [
                      Colors.black.withOpacity(0.5),
                      Colors.black.withOpacity(0.7),
                    ]
                  : [
                      Colors.black.withOpacity(0.3),
                      Colors.black.withOpacity(0.5),
                    ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildCalendarCard(),
                const SizedBox(height: 16),
                _buildLegend(),
                const SizedBox(height: 16),
                _buildSelectedDateEntries(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarCard() {
    return Card(
      elevation: 12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.black.withOpacity(0.7),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _focusedDate = DateTime(_focusedDate.year, _focusedDate.month - 1);
                    });
                  },
                  icon: const Icon(Icons.chevron_left, color: Colors.white),
                ),
                Text(
                  '${_getMonthName(_focusedDate.month)} ${_focusedDate.year}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _focusedDate = DateTime(_focusedDate.year, _focusedDate.month + 1);
                    });
                  },
                  icon: const Icon(Icons.chevron_right, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildCalendarGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_focusedDate.year, _focusedDate.month, 1);
    final lastDayOfMonth = DateTime(_focusedDate.year, _focusedDate.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday % 7;
    
    return Column(
      children: [
        // Weekday headers
        Row(
          children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
              .map((day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),
        // Calendar days
        ...List.generate(6, (weekIndex) {
          return Row(
            children: List.generate(7, (dayIndex) {
              final dayNumber = weekIndex * 7 + dayIndex - firstWeekday + 1;
              
              if (dayNumber < 1 || dayNumber > lastDayOfMonth.day) {
                return const Expanded(child: SizedBox(height: 40));
              }
              
              final date = DateTime(_focusedDate.year, _focusedDate.month, dayNumber);
              final entries = _getEntriesForDay(date);
              final isSelected = _selectedDate.year == date.year &&
                                _selectedDate.month == date.month &&
                                _selectedDate.day == date.day;
              final isToday = DateTime.now().year == date.year &&
                             DateTime.now().month == date.month &&
                             DateTime.now().day == date.day;
              
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = date;
                    });
                  },
                  child: Container(
                    height: 40,
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF7C3AED)
                          : isToday
                              ? const Color(0xFFEC4899).withOpacity(0.3)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: entries.isNotEmpty
                          ? Border.all(color: Colors.amber, width: 2)
                          : null,
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Text(
                            dayNumber.toString(),
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : isToday
                                      ? Colors.white
                                      : Colors.white70,
                              fontWeight: isSelected || isToday
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (entries.isNotEmpty)
                          Positioned(
                            top: 2,
                            right: 2,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.amber,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          );
        }),
      ],
    );
  }

  Widget _buildLegend() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.black.withOpacity(0.6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildLegendItem(
              icon: Icons.lock,
              label: 'Diary',
              color: const Color(0xFF7C3AED),
            ),
            _buildLegendItem(
              icon: Icons.public,
              label: 'Blog',
              color: const Color(0xFFEC4899),
            ),
            _buildLegendItem(
              icon: Icons.circle,
              label: 'Has Entries',
              color: Colors.amber,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedDateEntries() {
    final entries = _getEntriesForDay(_selectedDate);
    
    return Expanded(
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.black.withOpacity(0.6),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Entries for ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: entries.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_note,
                              size: 64,
                              color: Colors.white30,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No entries for this date',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white60,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: entries.length,
                        itemBuilder: (context, index) {
                          final entry = entries[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            color: Colors.black.withOpacity(0.4),
                            child: ListTile(
                              leading: Icon(
                                entry.type == 'diary' ? Icons.lock : Icons.public,
                                color: entry.type == 'diary'
                                    ? const Color(0xFF7C3AED)
                                    : const Color(0xFFEC4899),
                              ),
                              title: Text(
                                entry.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                entry.content,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white70),
                              ),
                              onTap: () => _showEntryDialog(entry),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  void _showEntryDialog(Entry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        title: Row(
          children: [
            Icon(
              entry.type == 'diary' ? Icons.lock : Icons.public,
              color: entry.type == 'diary' ? Colors.amber : Colors.green,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                entry.title,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${entry.date.day}/${entry.date.month}/${entry.date.year}',
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                entry.content,
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(
                color: entry.type == 'diary'
                    ? const Color(0xFF7C3AED)
                    : const Color(0xFFEC4899),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Settings Screen
class SettingsScreen extends StatefulWidget {
  final ThemeMode themeMode;
  final VoidCallback onThemeToggle;
  final VoidCallback onSettingsChanged;

  const SettingsScreen({
    super.key,
    required this.themeMode,
    required this.onThemeToggle,
    required this.onSettingsChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedFont = 'Default';
  String _selectedCursor = 'Wand';

  final List<String> _fontOptions = [
    'Default',
    'Serif',
    'Sans-serif',
    'Monospace',
    'Cursive',
    'Fantasy',
  ];

  final List<String> _cursorOptions = [
    'Wand',
    'Star',
    'Heart',
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final font = await SettingsService.getFontFamily();
    final cursor = await SettingsService.getCursorType();
    setState(() {
      _selectedFont = font;
      _selectedCursor = cursor;
    });
  }

  Future<void> _saveSettings() async {
    await SettingsService.setFontFamily(_selectedFont);
    await SettingsService.setCursorType(_selectedCursor);
    widget.onSettingsChanged();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved! ✨'),
          backgroundColor: Color(0xFF7C3AED),
        ),
      );
    }
  }

  String _getBackgroundImage() {
    return widget.themeMode == ThemeMode.light
        ? 'assets/images/castle-dragon-day.png'
        : 'assets/images/hero-castle-night.png';
  }

  bool get _isDarkMode => widget.themeMode == ThemeMode.dark;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(_getBackgroundImage()),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: _isDarkMode
                  ? [
                      Colors.black.withOpacity(0.5),
                      Colors.black.withOpacity(0.7),
                    ]
                  : [
                      Colors.black.withOpacity(0.3),
                      Colors.black.withOpacity(0.5),
                    ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildThemeCard(),
                const SizedBox(height: 16),
                _buildFontCard(),
                const SizedBox(height: 16),
                _buildCursorCard(),
                const SizedBox(height: 32),
                _buildSaveButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeCard() {
    return Card(
      elevation: 12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.black.withOpacity(0.7),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.palette, color: Color(0xFF7C3AED)),
                SizedBox(width: 8),
                Text(
                  'Theme',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Dark Mode',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                Switch(
                  value: _isDarkMode,
                  onChanged: (_) => widget.onThemeToggle(),
                  activeColor: const Color(0xFF7C3AED),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFontCard() {
    return Card(
      elevation: 12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.black.withOpacity(0.7),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.font_download, color: Color(0xFFEC4899)),
                SizedBox(width: 8),
                Text(
                  'Font Style',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _fontOptions.map((font) {
                final isSelected = _selectedFont == font;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedFont = font;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFEC4899)
                          : Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFEC4899)
                            : Colors.white30,
                      ),
                    ),
                    child: Text(
                      font,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCursorCard() {
    return Card(
      elevation: 12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.black.withOpacity(0.7),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.mouse, color: Color(0xFF10B981)),
                SizedBox(width: 8),
                Text(
                  'Cursor Style',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _cursorOptions.map((cursor) {
                final isSelected = _selectedCursor == cursor;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCursor = cursor;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF10B981)
                          : Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF10B981)
                            : Colors.white30,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          cursor == 'Wand'
                              ? Icons.auto_fix_high
                              : cursor == 'Star'
                                  ? Icons.star
                                  : Icons.favorite,
                          color: isSelected ? Colors.white : Colors.white70,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          cursor,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _saveSettings,
        icon: const Icon(Icons.save),
        label: const Text('Save Settings'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF7C3AED),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
