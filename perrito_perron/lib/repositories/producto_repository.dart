import 'package:sqflite/sqflite.dart';
import '../models/producto.dart';
import '../database/database_helper.dart';

class ProductoRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> insert(Producto producto) async {
    Database db = await _dbHelper.database;
    return await db.insert(DatabaseHelper.tableProductos, producto.toMap());
  }

  Future<List<Producto>> getAll() async {
    Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(DatabaseHelper.tableProductos);
    return List.generate(maps.length, (i) {
      return Producto.fromMap(maps[i]);
    });
  }

  Future<int> update(Producto producto) async {
    Database db = await _dbHelper.database;
    return await db.update(
      DatabaseHelper.tableProductos,
      producto.toMap(),
      where: 'id = ?',
      whereArgs: [producto.id],
    );
  }

  Future<int> delete(int id) async {
    Database db = await _dbHelper.database;
    return await db.delete(
      DatabaseHelper.tableProductos,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
