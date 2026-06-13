import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class ThumbnailCacheService {
  static const _dbName = 'thumbnail_cache.db';
  static const _table = 'cover_url_cache';
  static const _ttlMs = 7 * 24 * 60 * 60 * 1000; // 7 days

  Database? _db;

  Future<Database> _getDb() async {
    if (_db != null) return _db!;
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      p.join(dbPath, _dbName),
      version: 1,
      onCreate: (db, _) => db.execute(
        'CREATE TABLE $_table ('
        'path TEXT PRIMARY KEY, '
        'url TEXT NOT NULL, '
        'cached_at INTEGER NOT NULL'
        ')',
      ),
    );
    return _db!;
  }

  Future<String?> getCachedUrl(String bookPath) async {
    final db = await _getDb();
    final rows = await db.query(
      _table,
      columns: ['url', 'cached_at'],
      where: 'path = ?',
      whereArgs: [bookPath],
    );
    if (rows.isEmpty) return null;
    final cachedAt = rows.first['cached_at'] as int;
    if (DateTime.now().millisecondsSinceEpoch - cachedAt > _ttlMs) {
      await db.delete(_table, where: 'path = ?', whereArgs: [bookPath]);
      return null;
    }
    return rows.first['url'] as String;
  }

  Future<void> setCachedUrl(String bookPath, String url) async {
    final db = await _getDb();
    await db.insert(
      _table,
      {
        'path': bookPath,
        'url': url,
        'cached_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> getCount() async {
    final db = await _getDb();
    final result =
        await db.rawQuery('SELECT COUNT(*) as cnt FROM $_table');
    return (result.first['cnt'] as int?) ?? 0;
  }

  Future<void> clearAll() async {
    final db = await _getDb();
    await db.delete(_table);
  }
}
