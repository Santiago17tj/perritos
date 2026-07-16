import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/insumo_provider.dart';
import '../models/insumo.dart';

class InsumosScreen extends StatelessWidget {
  const InsumosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InsumoProvider>();
    final currencyFormat = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario 📦'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _mostrarDialogoInsumo(context);
            },
          )
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.insumos.isEmpty
              ? const Center(child: Text('No hay insumos registrados. Toca el + para añadir.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.insumos.length,
                  itemBuilder: (context, index) {
                    final insumo = provider.insumos[index];
                    final bool isLowStock = insumo.stockActual <= insumo.stockMinimo;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          color: isLowStock ? Theme.of(context).colorScheme.error : Colors.transparent,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    insumo.nombre,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text('Costo base: ${currencyFormat.format(insumo.costoUnitario)}'),
                                  Text(
                                    'Stock: ${insumo.stockActual} ${insumo.unidadMedida}',
                                    style: TextStyle(
                                      color: isLowStock ? Theme.of(context).colorScheme.error : null,
                                      fontWeight: isLowStock ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () {
                                    _mostrarDialogoSurtir(context, insumo);
                                  },
                                  icon: const Icon(Icons.add_shopping_cart, size: 16),
                                  label: const Text('Surtir'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    _mostrarDialogoInsumo(context, insumoExistente: insumo);
                                  },
                                  child: const Text('Editar'),
                                )
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarDialogoInsumo(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _mostrarDialogoSurtir(BuildContext context, Insumo insumo) {
    final TextEditingController cantidadCtrl = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Surtir ${insumo.nombre}'),
          content: TextField(
            controller: cantidadCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Cantidad a agregar (${insumo.unidadMedida})',
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (cantidadCtrl.text.isNotEmpty) {
                  final cantidad = double.tryParse(cantidadCtrl.text) ?? 0.0;
                  if (cantidad > 0) {
                    context.read<InsumoProvider>().surtirInsumo(insumo.id!, cantidad);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Inventario actualizado: +$cantidad ${insumo.unidadMedida}')),
                    );
                  }
                }
              },
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  void _mostrarDialogoInsumo(BuildContext context, {Insumo? insumoExistente}) {
    final nombreCtrl = TextEditingController(text: insumoExistente?.nombre ?? '');
    final costoCtrl = TextEditingController(text: insumoExistente?.costoUnitario.toString() ?? '');
    final stockMinimoCtrl = TextEditingController(text: insumoExistente?.stockMinimo.toString() ?? '10');
    final unidadCtrl = TextEditingController(text: insumoExistente?.unidadMedida ?? 'unidad');
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(insumoExistente == null ? 'Nuevo Insumo' : 'Editar Insumo'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre (ej: Salchichas, Pan, Servilletas)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: costoCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Costo Unitario (\$)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: stockMinimoCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Stock Mínimo (Alerta)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: unidadCtrl,
                  decoration: const InputDecoration(labelText: 'Unidad de medida (unidad, paquete, kg)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nombreCtrl.text.isNotEmpty && costoCtrl.text.isNotEmpty) {
                  final nuevoInsumo = Insumo(
                    id: insumoExistente?.id,
                    nombre: nombreCtrl.text,
                    costoUnitario: double.tryParse(costoCtrl.text) ?? 0.0,
                    precioVenta: 0.0, // Solo aplica si lo vendes suelto
                    stockActual: insumoExistente?.stockActual ?? 0.0,
                    stockMinimo: double.tryParse(stockMinimoCtrl.text) ?? 10.0,
                    unidadMedida: unidadCtrl.text.isEmpty ? 'unidad' : unidadCtrl.text,
                    fechaActualizacion: DateTime.now().toIso8601String(),
                  );

                  if (insumoExistente == null) {
                    context.read<InsumoProvider>().agregarInsumo(nuevoInsumo);
                  } else {
                    context.read<InsumoProvider>().actualizarInsumo(nuevoInsumo);
                  }
                  
                  Navigator.pop(context);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }
}

