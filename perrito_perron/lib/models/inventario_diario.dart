class InventarioDiario {
  final int? id;
  final String fecha; // YYYY-MM-DD
  final int insumoId;
  final double cantidadInicial;

  InventarioDiario({
    this.id,
    required this.fecha,
    required this.insumoId,
    required this.cantidadInicial,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fecha': fecha,
      'insumo_id': insumoId,
      'cantidad_inicial': cantidadInicial,
    };
  }

  factory InventarioDiario.fromMap(Map<String, dynamic> map) {
    return InventarioDiario(
      id: map['id'],
      fecha: map['fecha'],
      insumoId: map['insumo_id'],
      cantidadInicial: map['cantidad_inicial']?.toDouble() ?? 0.0,
    );
  }
}
