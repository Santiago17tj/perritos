import 'dart:convert';

class Producto {
  final int? id;
  final String nombre;
  final String emoji;
  final double precioVenta;
  final Map<int, double> receta; // {insumo_id: cantidad}

  Producto({
    this.id,
    required this.nombre,
    required this.emoji,
    required this.precioVenta,
    required this.receta,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'emoji': emoji,
      'precio_venta': precioVenta,
      'receta': jsonEncode(receta.map((key, value) => MapEntry(key.toString(), value))),
    };
  }

  factory Producto.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic> recetaMap = jsonDecode(map['receta'] ?? '{}');
    Map<int, double> recetaParseada = {};
    recetaMap.forEach((key, value) {
      recetaParseada[int.parse(key)] = (value as num).toDouble();
    });

    return Producto(
      id: map['id'],
      nombre: map['nombre'],
      emoji: map['emoji'],
      precioVenta: map['precio_venta']?.toDouble() ?? 0.0,
      receta: recetaParseada,
    );
  }

  Producto copyWith({
    int? id,
    String? nombre,
    String? emoji,
    double? precioVenta,
    Map<int, double>? receta,
  }) {
    return Producto(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      emoji: emoji ?? this.emoji,
      precioVenta: precioVenta ?? this.precioVenta,
      receta: receta ?? this.receta,
    );
  }
}
