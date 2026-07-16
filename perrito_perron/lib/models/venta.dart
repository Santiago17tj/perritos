class Venta {
  final int? id;
  final String fechaHora; // Formato ISO8601
  final double totalVenta;
  final String? metodoPago;
  final String? nota;

  Venta({
    this.id,
    required this.fechaHora,
    required this.totalVenta,
    this.metodoPago,
    this.nota,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fecha_hora': fechaHora,
      'total_venta': totalVenta,
      'metodo_pago': metodoPago,
      'nota': nota,
    };
  }

  factory Venta.fromMap(Map<String, dynamic> map) {
    return Venta(
      id: map['id'],
      fechaHora: map['fecha_hora'],
      totalVenta: map['total_venta']?.toDouble() ?? 0.0,
      metodoPago: map['metodo_pago'],
      nota: map['nota'],
    );
  }

  Venta copyWith({
    int? id,
    String? fechaHora,
    double? totalVenta,
    String? metodoPago,
    String? nota,
  }) {
    return Venta(
      id: id ?? this.id,
      fechaHora: fechaHora ?? this.fechaHora,
      totalVenta: totalVenta ?? this.totalVenta,
      metodoPago: metodoPago ?? this.metodoPago,
      nota: nota ?? this.nota,
    );
  }
}
