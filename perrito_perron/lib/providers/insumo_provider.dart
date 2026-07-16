import 'package:flutter/material.dart';
import '../models/insumo.dart';
import '../repositories/insumo_repository.dart';

class InsumoProvider extends ChangeNotifier {
  final InsumoRepository _repository = InsumoRepository();
  
  List<Insumo> _insumos = [];
  List<Insumo> get insumos => _insumos;

  List<Insumo> _alertas = [];
  List<Insumo> get alertas => _alertas;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  InsumoProvider() {
    cargarInsumos();
  }

  Future<void> cargarInsumos() async {
    _isLoading = true;
    notifyListeners();

    _insumos = await _repository.getAll();
    _alertas = await _repository.getLowStock();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> agregarInsumo(Insumo insumo) async {
    await _repository.insert(insumo);
    await cargarInsumos();
  }

  Future<void> actualizarInsumo(Insumo insumo) async {
    await _repository.update(insumo);
    await cargarInsumos();
  }

  Future<void> eliminarInsumo(int id) async {
    await _repository.delete(id);
    await cargarInsumos();
  }

  // Método para surtir inventario (suma a la cantidad actual)
  Future<void> surtirInsumo(int id, double cantidadAgregada) async {
    final insumo = _insumos.firstWhere((i) => i.id == id);
    final insumoActualizado = insumo.copyWith(
      stockActual: insumo.stockActual + cantidadAgregada,
      fechaActualizacion: DateTime.now().toIso8601String(),
    );
    await _repository.update(insumoActualizado);
    await cargarInsumos();
  }
}
