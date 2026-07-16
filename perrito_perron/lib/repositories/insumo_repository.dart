import 'package:sqflite/sqflite.dart';
import '../models/insumo.dart';
import '../database/database_helper.dart';

class InsumoRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> insert(Insumo insumo) async {
    Database db = await _dbHelper.database;
    return await db.insert(DatabaseHelper.tableInsumos, insumo.toMap());
  }

  Future<List<Insumo>> getAll() async {
    Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(DatabaseHelper.tableInsumos);
    return List.generate(maps.length, (i) {
      return Insumo.fromMap(maps[i]);
    });
  }

  Future<int> update(Insumo insumo) async {
    Database db = await _dbHelper.database;
    return await db.update(
      DatabaseHelper.tableInsumos,
      insumo.toMap(),
      where: 'id = ?',
      whereArgs: [insumo.id],
    );
  }

  Future<int> delete(int id) async {
    Database db = await _dbHelper.database;
    return await db.delete(
      DatabaseHelper.tableInsumos,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Insumo>> getLowStock() async {
    Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableInsumos,
      where: 'stock_actual <= stock_minimo',
    );
    return List.generate(maps.length, (i) {
      return Insumo.fromMap(maps[i]);
    });
  }
}
