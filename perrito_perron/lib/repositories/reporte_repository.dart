import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';

class ReporteRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<Map<String, dynamic>>> getResumenPorDias(int diasLimit) async {
    Database db = await _dbHelper.database;
    
    // Asumimos que los cierres diarios se guardan en la tabla cierres_diarios
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableCierres,
      orderBy: 'fecha DESC',
      limit: diasLimit,
    );
    
    return maps;
  }
  
  Future<Map<String, dynamic>> calcularResumenDelDia(String fecha) async {
    Database db = await _dbHelper.database;
    
    // 1. Total Ventas
    final ventasResult = await db.rawQuery(
      'SELECT SUM(total_venta) as total FROM ${DatabaseHelper.tableVentas} WHERE fecha_hora LIKE ?',
      ['$fecha%']
    );
    double totalVentas = (ventasResult.first['total'] as num?)?.toDouble() ?? 0.0;
    
    // 2. Costo de Ventas
    final costosResult = await db.rawQuery(
      '''SELECT SUM(dv.costo_unitario * dv.cantidad) as costo_total 
         FROM ${DatabaseHelper.tableDetalleVenta} dv 
         JOIN ${DatabaseHelper.tableVentas} v ON dv.venta_id = v.id 
         WHERE v.fecha_hora LIKE ?''',
      ['$fecha%']
    );
    double costoVentas = (costosResult.first['costo_total'] as num?)?.toDouble() ?? 0.0;
    
    // 3. Gastos
    final gastosResult = await db.rawQuery(
      'SELECT SUM(monto) as total FROM ${DatabaseHelper.tableGastos} WHERE fecha = ?',
      [fecha]
    );
    double totalGastos = (gastosResult.first['total'] as num?)?.toDouble() ?? 0.0;
    
    return {
      'totalVentas': totalVentas,
      'costoVentas': costoVentas,
      'totalGastos': totalGastos,
      'gananciaNeta': totalVentas - costoVentas - totalGastos,
    };
  }
}
