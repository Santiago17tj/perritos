import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/gasto.dart';
import '../repositories/gasto_repository.dart';

class GastoProvider extends ChangeNotifier {
  final GastoRepository _repository = GastoRepository();
  
  List<Gasto> _gastosDelDia = [];
  List<Gasto> get gastosDelDia => _gastosDelDia;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  double get totalGastosHoy => _gastosDelDia.fold(0, (sum, item) => sum + item.monto);

  GastoProvider() {
    cargarGastosHoy();
  }

  String get _hoy => DateFormat('yyyy-MM-dd').format(DateTime.now());

  Future<void> cargarGastosHoy() async {
    _isLoading = true;
    notifyListeners();

    _gastosDelDia = await _repository.getByFecha(_hoy);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> agregarGasto(Gasto gasto) async {
    await _repository.insert(gasto);
    await cargarGastosHoy();
  }

  Future<void> editarGasto(Gasto gasto) async {
    await _repository.update(gasto);
    await cargarGastosHoy();
  }

  Future<void> eliminarGasto(int id) async {
    await _repository.delete(id);
    await cargarGastosHoy();
  }
}
