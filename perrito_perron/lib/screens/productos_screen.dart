import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/producto_provider.dart';
import '../providers/insumo_provider.dart';
import '../models/producto.dart';
import '../theme/app_theme.dart';

class ProductosScreen extends StatelessWidget {
  const ProductosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final productoProvider = context.watch<ProductoProvider>();
    final insumoProvider = context.watch<InsumoProvider>();
    final currencyFormat = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo de Productos 🌭'),
      ),
      body: productoProvider.isLoading || insumoProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: productoProvider.productos.length,
              itemBuilder: (context, index) {
                final producto = productoProvider.productos[index];
                
                // Construir string de receta amigable
                List<String> recetaNombres = [];
                producto.receta.forEach((insumoId, cantidad) {
                  final matches = insumoProvider.insumos.where((i) => i.id == insumoId);
                  if (matches.isNotEmpty) {
                    recetaNombres.add('${cantidad}x ${matches.first.nombre}');
                  }
                });

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Text(producto.emoji, style: const TextStyle(fontSize: 32)),
                    title: Text(producto.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Receta: ${recetaNombres.join(", ")}'),
                    trailing: Text(
                      currencyFormat.format(producto.precioVenta),
                      style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    onTap: () => _mostrarDialogoProducto(context, producto),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarDialogoProducto(context, null),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _mostrarDialogoProducto(BuildContext context, Producto? productoExistente) {
    final insumoProvider = context.read<InsumoProvider>();
    
    final nombreCtrl = TextEditingController(text: productoExistente?.nombre ?? '');
    final emojiCtrl = TextEditingController(text: productoExistente?.emoji ?? '🌭');
    final precioCtrl = TextEditingController(text: productoExistente?.precioVenta.toString() ?? '');
    
    // Clonar la receta existente o crear una vacía
    Map<int, double> recetaLocal = productoExistente != null 
        ? Map<int, double>.from(productoExistente.receta) 
        : {};

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(productoExistente == null ? 'Nuevo Producto' : 'Editar Producto'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 60,
                          child: TextField(
                            controller: emojiCtrl,
                            decoration: const InputDecoration(labelText: 'Emoji'),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: nombreCtrl,
                            decoration: const InputDecoration(labelText: 'Nombre del producto'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: precioCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Precio de Venta (\$)'),
                    ),
                    const SizedBox(height: 24),
                    const Text('Receta (Insumos que consume):', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    
                    // Lista de insumos en la receta actual
                    ...insumoProvider.insumos.map((insumo) {
                      bool estaEnReceta = recetaLocal.containsKey(insumo.id);
                      double cantidad = estaEnReceta ? recetaLocal[insumo.id!]! : 0.0;
                      
                      return CheckboxListTile(
                        title: Text(insumo.nombre),
                        subtitle: estaEnReceta 
                            ? Text('Cantidad: $cantidad ${insumo.unidadMedida}') 
                            : null,
                        value: estaEnReceta,
                        onChanged: (bool? checked) {
                          if (checked == true) {
                            // Mostrar dialog para pedir cantidad
                            _pedirCantidadInsumo(context, insumo.nombre, insumo.unidadMedida).then((valor) {
                              if (valor != null && valor > 0) {
                                setState(() {
                                  recetaLocal[insumo.id!] = valor;
                                });
                              }
                            });
                          } else {
                            setState(() {
                              recetaLocal.remove(insumo.id);
                            });
                          }
                        },
                      );
                    }),
                  ],
                ),
              ),
              actions: [
                if (productoExistente != null)
                  TextButton(
                    onPressed: () {
                      context.read<ProductoProvider>().eliminarProducto(productoExistente.id!);
                      Navigator.pop(context);
                    },
                    child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nombreCtrl.text.isNotEmpty && precioCtrl.text.isNotEmpty && recetaLocal.isNotEmpty) {
                      final nuevoProducto = Producto(
                        id: productoExistente?.id,
                        nombre: nombreCtrl.text,
                        emoji: emojiCtrl.text.isEmpty ? '🌭' : emojiCtrl.text,
                        precioVenta: double.tryParse(precioCtrl.text) ?? 0.0,
                        receta: recetaLocal,
                      );

                      if (productoExistente == null) {
                        context.read<ProductoProvider>().agregarProducto(nuevoProducto);
                      } else {
                        context.read<ProductoProvider>().actualizarProducto(nuevoProducto);
                      }
                      
                      Navigator.pop(context);
                    } else if (recetaLocal.isEmpty) {
                       ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Debes agregar al menos un insumo a la receta')),
                      );
                    }
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  Future<double?> _pedirCantidadInsumo(BuildContext context, String nombre, String unidad) async {
    final ctrl = TextEditingController();
    return showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Cantidad de $nombre'),
          content: TextField(
            controller: ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: 'Cantidad en $unidad'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, double.tryParse(ctrl.text));
              },
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }
}
