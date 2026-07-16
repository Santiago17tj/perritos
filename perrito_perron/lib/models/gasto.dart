class Gasto {
  final int? id;
  final String fecha; // YYYY-MM-DD
  final String concepto;
  final double monto;
  final String? categoria;
  final String tipo; // 'fijo' o 'variable'

  Gasto({
    this.id,
    required this.fecha,
    required this.concepto,
    required this.monto,
    this.categoria,
    required this.tipo,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fecha': fecha,
      'concepto': concepto,
      'monto': monto,
      'categoria': categoria,
      'tipo': tipo,
    };
  }

  factory Gasto.fromMap(Map<String, dynamic> map) {
    return Gasto(
      id: map['id'],
      fecha: map['fecha'],
      concepto: map['concepto'],
      monto: map['monto']?.toDouble() ?? 0.0,
      categoria: map['categoria'],
      tipo: map['tipo'] ?? 'variable',
    );
  }

  Gasto copyWith({
    int? id,
    String? fecha,
    String? concepto,
    double? monto,
    String? categoria,
    String? tipo,
  }) {
    return Gasto(
      id: id ?? this.id,
      fecha: fecha ?? this.fecha,
      concepto: concepto ?? this.concepto,
      monto: monto ?? this.monto,
      categoria: categoria ?? this.categoria,
      tipo: tipo ?? this.tipo,
    );
  }
}
