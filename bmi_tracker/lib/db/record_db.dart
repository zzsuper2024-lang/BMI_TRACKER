import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class RecordDB {

  static final RecordDB _instance = RecordDB._();
  factory RecordDB() => _instance;
  RecordDB._();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'bmi_records.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE records (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT,          -- yyyy-MM-dd
            weight REAL,        -- kg
            height REAL         -- cm
          )
        ''');
      },
    );
  }

  Future<int> insert(Map<String, dynamic> data) async {
    final db = await database;
    return db.insert('records', data);
  }

  // 全部记录：先按日期降序，再按 id 降序
  Future<List<Map<String, dynamic>>> fetchAll() async {
    final db = await database;
    return db.query('records', orderBy: 'date DESC, id DESC');
  }

// 最近 N 条：同样使用双重排序
  Future<List<Map<String, dynamic>>> fetchRecent(int limit) async {
    final db = await database;
    final rows = await db.query(
      'records',
      orderBy: 'date DESC, id DESC',
      limit: limit,
    );
    return rows.reversed.toList();  // 时间正序给折线用
  }
}