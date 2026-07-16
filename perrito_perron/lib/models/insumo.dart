class Insumo {
  final int? id;
  final String nombre;
  final double costoUnitario;
  final double precioVenta;
  final double stockActual;
  final double stockMinimo;
  final String unidadMedida;
  final String? fechaActualizacion;

  Insumo({
    this.id,
    required this.nombre,
    required this.costoUnitario,
    required this.precioVenta,
    required this.stockActual,
    required this.stockMinimo,
    required this.unidadMedida,
    this.fechaActualizacion,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'costo_unitario': costoUnitario,
      'precio_venta': precioVenta,
      'stock_actual': stockActual,
      'stock_minimo': stockMinimo,
      'unidad_medida': unidadMedida,
      'fecha_actualizacion': fechaActualizacion,
    };
  }

  factory Insumo.fromMap(Map<String, dynamic> map) {
    return Insumo(
      id: map['id'],
      nombre: map['nombre'],
      costoUnitario: map['costo_unitario']?.toDouble() ?? 0.0,
      precioVenta: map['precio_venta']?.toDouble() ?? 0.0,
      stockActual: map['stock_actual']?.toDouble() ?? 0.0,
      stockMinimo: map['stock_minimo']?.toDouble() ?? 0.0,
      unidadMedida: map['unidad_medida'],
      fechaActualizacion: map['fecha_actualizacion'],
    );
  }

  Insumo copyWith({
    int? id,
    String? nombre,
    double? costoUnitario,
    double? precioVenta,
    double? stockActual,
    double? stockMinimo,
    String? unidadMedida,
    String? fechaActualizacion,
  }) {
    return Insumo(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      costoUnitario: costoUnitario ?? this.costoUnitario,
      precioVenta: precioVenta ?? this.precioVenta,
      stockActual: stockActual ?? this.stockActual,
      stockMinimo: stockMinimo ?? this.stockMinimo,
      unidadMedida: unidadMedida ?? this.unidadMedida,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
    );
  }
}
