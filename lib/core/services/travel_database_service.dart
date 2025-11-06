import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/trip.dart';
import '../models/attraction.dart';
import '../models/expense.dart';
import '../models/itinerary.dart';
import '../models/user_account.dart';

/// QuackTrip 旅游数据库服务
class TravelDatabaseService {
  static final TravelDatabaseService instance = TravelDatabaseService._init();
  static Database? _database;

  TravelDatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('quacktrip.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // 用户账户表
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        email TEXT,
        avatar TEXT,
        nickname TEXT,
        created_at TEXT NOT NULL,
        last_login_at TEXT
      )
    ''');

    // 旅行计划表
    await db.execute('''
      CREATE TABLE trips (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        destination TEXT NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        budget REAL NOT NULL,
        status TEXT NOT NULL DEFAULT 'planned',
        description TEXT,
        cover_image TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // 景点表
    await db.execute('''
      CREATE TABLE attractions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        trip_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        location TEXT NOT NULL,
        category TEXT NOT NULL,
        description TEXT,
        image_url TEXT,
        rating REAL,
        price REAL,
        notes TEXT,
        visited INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (trip_id) REFERENCES trips (id) ON DELETE CASCADE
      )
    ''');

    // 花费记录表
    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        trip_id INTEGER NOT NULL,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        currency TEXT NOT NULL DEFAULT 'CNY',
        date TEXT NOT NULL,
        description TEXT,
        receipt TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (trip_id) REFERENCES trips (id) ON DELETE CASCADE
      )
    ''');

    // 行程安排表
    await db.execute('''
      CREATE TABLE itineraries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        trip_id INTEGER NOT NULL,
        day INTEGER NOT NULL,
        time TEXT NOT NULL,
        activity TEXT NOT NULL,
        location TEXT NOT NULL,
        description TEXT,
        attraction_id INTEGER,
        completed INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (trip_id) REFERENCES trips (id) ON DELETE CASCADE,
        FOREIGN KEY (attraction_id) REFERENCES attractions (id) ON DELETE SET NULL
      )
    ''');
  }

  // ==================== 用户账户相关 ====================

  Future<UserAccount> createUser(UserAccount user) async {
    final db = await database;
    final id = await db.insert('users', user.toMap());
    return user.copyWith(id: id);
  }

  Future<UserAccount?> getUserByUsername(String username) async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
    if (maps.isEmpty) return null;
    return UserAccount.fromMap(maps.first);
  }

  Future<int> updateUser(UserAccount user) async {
    final db = await database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  // ==================== 旅行计划相关 ====================

  Future<Trip> createTrip(Trip trip) async {
    final db = await database;
    final id = await db.insert('trips', trip.toMap());
    return trip.copyWith(id: id);
  }

  Future<List<Trip>> getAllTrips() async {
    final db = await database;
    final maps = await db.query('trips', orderBy: 'created_at DESC');
    return maps.map((map) => Trip.fromMap(map)).toList();
  }

  Future<Trip?> getTripById(int id) async {
    final db = await database;
    final maps = await db.query(
      'trips',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Trip.fromMap(maps.first);
  }

  Future<int> updateTrip(Trip trip) async {
    final db = await database;
    return await db.update(
      'trips',
      trip.toMap(),
      where: 'id = ?',
      whereArgs: [trip.id],
    );
  }

  Future<int> deleteTrip(int id) async {
    final db = await database;
    return await db.delete(
      'trips',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== 景点相关 ====================

  Future<Attraction> createAttraction(Attraction attraction) async {
    final db = await database;
    final id = await db.insert('attractions', attraction.toMap());
    return attraction.copyWith(id: id);
  }

  Future<List<Attraction>> getAttractionsByTripId(int tripId) async {
    final db = await database;
    final maps = await db.query(
      'attractions',
      where: 'trip_id = ?',
      whereArgs: [tripId],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => Attraction.fromMap(map)).toList();
  }

  Future<int> updateAttraction(Attraction attraction) async {
    final db = await database;
    return await db.update(
      'attractions',
      attraction.toMap(),
      where: 'id = ?',
      whereArgs: [attraction.id],
    );
  }

  Future<int> deleteAttraction(int id) async {
    final db = await database;
    return await db.delete(
      'attractions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== 花费记录相关 ====================

  Future<Expense> createExpense(Expense expense) async {
    final db = await database;
    final id = await db.insert('expenses', expense.toMap());
    return expense.copyWith(id: id);
  }

  Future<List<Expense>> getExpensesByTripId(int tripId) async {
    final db = await database;
    final maps = await db.query(
      'expenses',
      where: 'trip_id = ?',
      whereArgs: [tripId],
      orderBy: 'date DESC',
    );
    return maps.map((map) => Expense.fromMap(map)).toList();
  }

  Future<double> getTotalExpensesByTripId(int tripId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM expenses WHERE trip_id = ?',
      [tripId],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<int> updateExpense(Expense expense) async {
    final db = await database;
    return await db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<int> deleteExpense(int id) async {
    final db = await database;
    return await db.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== 行程安排相关 ====================

  Future<Itinerary> createItinerary(Itinerary itinerary) async {
    final db = await database;
    final id = await db.insert('itineraries', itinerary.toMap());
    return itinerary.copyWith(id: id);
  }

  Future<List<Itinerary>> getItinerariesByTripId(int tripId) async {
    final db = await database;
    final maps = await db.query(
      'itineraries',
      where: 'trip_id = ?',
      whereArgs: [tripId],
      orderBy: 'day ASC, time ASC',
    );
    return maps.map((map) => Itinerary.fromMap(map)).toList();
  }

  Future<List<Itinerary>> getItinerariesByDay(int tripId, int day) async {
    final db = await database;
    final maps = await db.query(
      'itineraries',
      where: 'trip_id = ? AND day = ?',
      whereArgs: [tripId, day],
      orderBy: 'time ASC',
    );
    return maps.map((map) => Itinerary.fromMap(map)).toList();
  }

  Future<int> updateItinerary(Itinerary itinerary) async {
    final db = await database;
    return await db.update(
      'itineraries',
      itinerary.toMap(),
      where: 'id = ?',
      whereArgs: [itinerary.id],
    );
  }

  Future<int> deleteItinerary(int id) async {
    final db = await database;
    return await db.delete(
      'itineraries',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== 批量插入（AI生成数据时使用） ====================

  Future<void> batchInsertAttractions(List<Attraction> attractions) async {
    final db = await database;
    final batch = db.batch();
    for (final attraction in attractions) {
      batch.insert('attractions', attraction.toMap());
    }
    await batch.commit(noResult: true);
  }

  Future<void> batchInsertItineraries(List<Itinerary> itineraries) async {
    final db = await database;
    final batch = db.batch();
    for (final itinerary in itineraries) {
      batch.insert('itineraries', itinerary.toMap());
    }
    await batch.commit(noResult: true);
  }

  // 关闭数据库
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
