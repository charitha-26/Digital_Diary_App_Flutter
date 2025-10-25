import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/entry.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    try {
      _database = await _initDB('entries.db');
      return _database!;
    } catch (e) {
      print('Database initialization error: $e');
      // Return a mock database or handle gracefully
      rethrow;
    }
  }

  Future<Database> _initDB(String filePath) async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, filePath);

      return await openDatabase(
        path,
        version: 1,
        onCreate: _createDB,
      );
    } catch (e) {
      print('Database initialization error: $e');
      rethrow;
    }
  }

  Future _createDB(Database db, int version) async {
    try {
      await db.execute('''
        CREATE TABLE entries (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          content TEXT NOT NULL,
          date TEXT NOT NULL,
          type TEXT NOT NULL,
          author TEXT
        )
      ''');

      // Insert sample data
      await _insertSampleData(db);
    } catch (e) {
      print('Database creation error: $e');
    }
  }

  Future _insertSampleData(Database db) async {
    try {
      final sampleEntries = [
        {
          'title': 'My Magical Journey Begins',
          'content': 'Today I started my enchanted diary. The castle looks beautiful in the twilight...',
          'date': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
          'type': 'diary',
          'author': null,
        },
        {
          'title': 'Adventures in the Enchanted Forest',
          'content': 'I discovered a hidden path today that led to the most beautiful clearing. The dragons were flying overhead, and the sunset painted the sky in magical colors...',
          'date': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
          'type': 'blog',
          'author': 'You',
        },
        {
          'title': 'The Art of Dragon Watching',
          'content': 'For those new to our realm, dragon watching is one of the most peaceful activities. Here\'s my guide to the best spots around the castle...',
          'date': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
          'type': 'blog',
          'author': 'MysticWriter',
        },
      ];

      for (final entry in sampleEntries) {
        await db.insert('entries', entry);
      }
    } catch (e) {
      print('Sample data insertion error: $e');
    }
  }

  Future<int> insertEntry(Entry entry) async {
    try {
      final db = await instance.database;
      return await db.insert('entries', entry.toMap());
    } catch (e) {
      print('Insert entry error: $e');
      return -1;
    }
  }

  Future<List<Entry>> getAllEntries() async {
    try {
      final db = await instance.database;
      final result = await db.query('entries', orderBy: 'date DESC');
      return result.map((map) => Entry.fromMap(map)).toList();
    } catch (e) {
      print('Get all entries error: $e');
      return [];
    }
  }

  Future<List<Entry>> getEntriesByType(EntryType type) async {
    try {
      final db = await instance.database;
      final result = await db.query(
        'entries',
        where: 'type = ?',
        whereArgs: [type.name],
        orderBy: 'date DESC',
      );
      return result.map((map) => Entry.fromMap(map)).toList();
    } catch (e) {
      print('Get entries by type error: $e');
      return [];
    }
  }

  Future<List<Entry>> getEntriesByDate(DateTime date) async {
    try {
      final db = await instance.database;
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      final result = await db.query(
        'entries',
        where: 'date >= ? AND date < ?',
        whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
        orderBy: 'date DESC',
      );
      return result.map((map) => Entry.fromMap(map)).toList();
    } catch (e) {
      print('Get entries by date error: $e');
      return [];
    }
  }

  Future<Map<DateTime, List<Entry>>> getEntriesGroupedByDate() async {
    try {
      final entries = await getAllEntries();
      final Map<DateTime, List<Entry>> groupedEntries = {};

      for (final entry in entries) {
        final dateKey = DateTime(entry.date.year, entry.date.month, entry.date.day);
        if (groupedEntries[dateKey] == null) {
          groupedEntries[dateKey] = [];
        }
        groupedEntries[dateKey]!.add(entry);
      }

      return groupedEntries;
    } catch (e) {
      print('Get grouped entries error: $e');
      return {};
    }
  }

  Future<int> updateEntry(Entry entry) async {
    try {
      final db = await instance.database;
      return await db.update(
        'entries',
        entry.toMap(),
        where: 'id = ?',
        whereArgs: [entry.id],
      );
    } catch (e) {
      print('Update entry error: $e');
      return -1;
    }
  }

  Future<int> deleteEntry(int id) async {
    try {
      final db = await instance.database;
      return await db.delete(
        'entries',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print('Delete entry error: $e');
      return -1;
    }
  }

  Future close() async {
    try {
      final db = await instance.database;
      db.close();
    } catch (e) {
      print('Database close error: $e');
    }
  }
}
