import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../repositories/reporte_repository.dart';

class ReporteProvider extends ChangeNotifier {
  final ReporteRepository _repository = ReporteRepository();
  
  Map<String, dynamic> _resumenHoy = {
    'totalVentas': 0.0,
    'costoVentas': 0.0,
    'totalGastos': 0.0,
    'gananciaNeta': 0.0,
  };
  
  Map<String, dynamic> get resumenHoy => _resumenHoy;
  
  List<Map<String, dynamic>> _historialDias = [];
  List<Map<String, dynamic>> get historialDias => _historialDias;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  ReporteProvider() {
    cargarDatos();
  }

  String get _hoy => DateFormat('yyyy-MM-dd').format(DateTime.now());

  Future<void> cargarDatos() async {
    _isLoading = true;
    notifyListeners();

    _resumenHoy = await _repository.calcularResumenDelDia(_hoy);
    _historialDias = await _repository.getResumenPorDias(7); // Últimos 7 días

    _isLoading = false;
    notifyListeners();
  }
}
