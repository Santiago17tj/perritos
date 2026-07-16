import 'package:flutter/material.dart';
import '../models/producto.dart';
import '../repositories/producto_repository.dart';

class ProductoProvider extends ChangeNotifier {
  final ProductoRepository _repository = ProductoRepository();
  
  List<Producto> _productos = [];
  List<Producto> get productos => _productos;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  ProductoProvider() {
    cargarProductos();
  }

  Future<void> cargarProductos() async {
    _isLoading = true;
    notifyListeners();

    _productos = await _repository.getAll();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> agregarProducto(Producto producto) async {
    await _repository.insert(producto);
    await cargarProductos();
  }

  Future<void> actualizarProducto(Producto producto) async {
    await _repository.update(producto);
    await cargarProductos();
  }

  Future<void> eliminarProducto(int id) async {
    await _repository.delete(id);
    await cargarProductos();
  }
}
