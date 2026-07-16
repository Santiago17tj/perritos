import 'package:sqflite/sqflite.dart';
import '../models/gasto.dart';
import '../database/database_helper.dart';

class GastoRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> insert(Gasto gasto) async {
    Database db = await _dbHelper.database;
    return await db.insert(DatabaseHelper.tableGastos, gasto.toMap());
  }

  Future<List<Gasto>> getByFecha(String fecha) async {
    Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableGastos,
      where: 'fecha = ?',
      whereArgs: [fecha],
      orderBy: 'id DESC',
    );
    return List.generate(maps.length, (i) {
      return Gasto.fromMap(maps[i]);
    });
  }

  Future<int> update(Gasto gasto) async {
    Database db = await _dbHelper.database;
    return await db.update(
      DatabaseHelper.tableGastos,
      gasto.toMap(),
      where: 'id = ?',
      whereArgs: [gasto.id],
    );
  }

  Future<int> delete(int id) async {
    Database db = await _dbHelper.database;
    return await db.delete(
      DatabaseHelper.tableGastos,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
