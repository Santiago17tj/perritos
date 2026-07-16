class DetalleVenta {
  final int? id;
  final int ventaId;
  final int insumoId;
  final double cantidad;
  final double precioUnitario; // Precio al que se vendió (si aplica)
  final double costoUnitario;  // Costo del insumo en el momento de la venta
  final double subtotal;

  DetalleVenta({
    this.id,
    required this.ventaId,
    required this.insumoId,
    required this.cantidad,
    required this.precioUnitario,
    required this.costoUnitario,
    required this.subtotal,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'venta_id': ventaId,
      'insumo_id': insumoId,
      'cantidad': cantidad,
      'precio_unitario': precioUnitario,
      'costo_unitario': costoUnitario,
      'subtotal': subtotal,
    };
  }

  factory DetalleVenta.fromMap(Map<String, dynamic> map) {
    return DetalleVenta(
      id: map['id'],
      ventaId: map['venta_id'],
      insumoId: map['insumo_id'],
      cantidad: map['cantidad']?.toDouble() ?? 0.0,
      precioUnitario: map['precio_unitario']?.toDouble() ?? 0.0,
      costoUnitario: map['costo_unitario']?.toDouble() ?? 0.0,
      subtotal: map['subtotal']?.toDouble() ?? 0.0,
    );
  }
}
