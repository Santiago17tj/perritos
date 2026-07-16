import 'package:sqflite/sqflite.dart';
import '../models/venta.dart';
import '../models/detalle_venta.dart';
import '../database/database_helper.dart';

class VentaRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Registrar venta y descontar inventario en una transacción
  Future<int> registrarVenta(Venta venta, List<DetalleVenta> detalles) async {
    Database db = await _dbHelper.database;
    
    int ventaId = 0;
    await db.transaction((txn) async {
      // 1. Insertar venta
      ventaId = await txn.insert(DatabaseHelper.tableVentas, venta.toMap());

      // 2. Insertar detalles y actualizar inventario
      for (var detalle in detalles) {
        var detalleConVentaId = DetalleVenta(
          ventaId: ventaId,
          insumoId: detalle.insumoId,
          cantidad: detalle.cantidad,
          precioUnitario: detalle.precioUnitario,
          costoUnitario: detalle.costoUnitario,
          subtotal: detalle.subtotal,
        );
        await txn.insert(DatabaseHelper.tableDetalleVenta, detalleConVentaId.toMap());

        // 3. Descontar del inventario
        await txn.rawUpdate(
          'UPDATE ${DatabaseHelper.tableInsumos} SET stock_actual = stock_actual - ? WHERE id = ?',
          [detalle.cantidad, detalle.insumoId],
        );
      }
    });
    return ventaId;
  }

  // Obtener ventas del día
  Future<List<Venta>> getVentasDelDia(String fecha) async {
    Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableVentas,
      where: 'fecha_hora LIKE ?',
      whereArgs: ['$fecha%'],
      orderBy: 'id DESC',
    );
    return List.generate(maps.length, (i) => Venta.fromMap(maps[i]));
  }

  // Deshacer última venta (eliminar y restaurar stock)
  Future<bool> deshacerUltimaVenta() async {
    Database db = await _dbHelper.database;
    bool success = false;
    
    await db.transaction((txn) async {
      // 1. Obtener última venta
      final List<Map<String, dynamic>> ultimasVentas = await txn.query(
        DatabaseHelper.tableVentas,
        orderBy: 'id DESC',
        limit: 1,
      );
      
      if (ultimasVentas.isNotEmpty) {
        int ventaId = ultimasVentas.first['id'];
        
        // 2. Obtener detalles
        final List<Map<String, dynamic>> detallesMap = await txn.query(
          DatabaseHelper.tableDetalleVenta,
          where: 'venta_id = ?',
          whereArgs: [ventaId],
        );
        
        // 3. Restaurar inventario
        for (var d in detallesMap) {
          await txn.rawUpdate(
            'UPDATE ${DatabaseHelper.tableInsumos} SET stock_actual = stock_actual + ? WHERE id = ?',
            [d['cantidad'], d['insumo_id']],
          );
        }
        
        // 4. Eliminar detalles y venta (On Delete Cascade debería encargarse de los detalles si está activado)
        await txn.delete(DatabaseHelper.tableDetalleVenta, where: 'venta_id = ?', whereArgs: [ventaId]);
        await txn.delete(DatabaseHelper.tableVentas, where: 'id = ?', whereArgs: [ventaId]);
        
        success = true;
      }
    });
    
    return success;
  }
}
