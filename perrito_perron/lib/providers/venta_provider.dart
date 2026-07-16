import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/venta.dart';
import '../models/detalle_venta.dart';
import '../models/producto.dart';
import '../models/insumo.dart';
import '../repositories/venta_repository.dart';

class VentaProvider extends ChangeNotifier {
  final VentaRepository _repository = VentaRepository();
  
  List<Venta> _ventasDelDia = [];
  List<Venta> get ventasDelDia => _ventasDelDia;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  VentaProvider() {
    cargarVentasHoy();
  }

  String get _hoy => DateFormat('yyyy-MM-dd').format(DateTime.now());

  Future<void> cargarVentasHoy() async {
    _isLoading = true;
    notifyListeners();

    _ventasDelDia = await _repository.getVentasDelDia(_hoy);

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> registrarVenta(Producto producto, List<Insumo> inventarioActual) async {
    // 1. Validar que hay suficiente stock
    bool hasStock = true;
    producto.receta.forEach((insumoId, cantidadRequerida) {
      final insumo = inventarioActual.firstWhere((i) => i.id == insumoId, orElse: () => Insumo(nombre: '', costoUnitario: 0, precioVenta: 0, stockActual: 0, stockMinimo: 0, unidadMedida: ''));
      if (insumo.stockActual < cantidadRequerida) {
        hasStock = false;
      }
    });

    if (!hasStock) return false;

    // 2. Crear Venta
    final venta = Venta(
      fechaHora: DateTime.now().toIso8601String(),
      totalVenta: producto.precioVenta,
      nota: '${producto.emoji} ${producto.nombre}',
    );

    // 3. Crear Detalles (uno por cada insumo en la receta)
    List<DetalleVenta> detalles = [];
    producto.receta.forEach((insumoId, cantidad) {
      final insumo = inventarioActual.firstWhere((i) => i.id == insumoId);
      detalles.add(
        DetalleVenta(
          ventaId: 0, // Se asigna en el repo
          insumoId: insumoId,
          cantidad: cantidad,
          precioUnitario: producto.precioVenta, // Opcional: cómo distribuir el precio
          costoUnitario: insumo.costoUnitario,
          subtotal: 0, // Podría usarse si cobras insumos extra
        )
      );
    });

    // 4. Guardar
    await _repository.registrarVenta(venta, detalles);
    await cargarVentasHoy();
    
    return true; // Éxito
  }

  Future<void> deshacerUltimaVenta() async {
    bool success = await _repository.deshacerUltimaVenta();
    if (success) {
      await cargarVentasHoy();
    }
  }
}
