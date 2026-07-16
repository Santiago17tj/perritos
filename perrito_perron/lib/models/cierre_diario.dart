class CierreDiario {
  final int? id;
  final String fecha; // YYYY-MM-DD
  final double totalVentas;
  final double totalGastos;
  final double costoInsumos;
  final double gananciaNeta;
  final String? inventarioSnapshot; // JSON con el estado del inventario al cierre

  CierreDiario({
    this.id,
    required this.fecha,
    required this.totalVentas,
    required this.totalGastos,
    required this.costoInsumos,
    required this.gananciaNeta,
    this.inventarioSnapshot,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fecha': fecha,
      'total_ventas': totalVentas,
      'total_gastos': totalGastos,
      'costo_insumos': costoInsumos,
      'ganancia_neta': gananciaNeta,
      'inventario_snapshot': inventarioSnapshot,
    };
  }

  factory CierreDiario.fromMap(Map<String, dynamic> map) {
    return CierreDiario(
      id: map['id'],
      fecha: map['fecha'],
      totalVentas: map['total_ventas']?.toDouble() ?? 0.0,
      totalGastos: map['total_gastos']?.toDouble() ?? 0.0,
      costoInsumos: map['costo_insumos']?.toDouble() ?? 0.0,
      gananciaNeta: map['ganancia_neta']?.toDouble() ?? 0.0,
      inventarioSnapshot: map['inventario_snapshot'],
    );
  }
}
