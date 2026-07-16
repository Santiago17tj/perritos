import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/venta_provider.dart';
import '../providers/producto_provider.dart';
import '../providers/insumo_provider.dart';
import '../widgets/product_button.dart';
import '../theme/app_theme.dart';
import 'productos_screen.dart';

class VentasScreen extends StatelessWidget {
  const VentasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ventaProvider = context.watch<VentaProvider>();
    final productoProvider = context.watch<ProductoProvider>();
    final insumoProvider = context.watch<InsumoProvider>();
    final currencyFormat = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Venta ⚡'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProductosScreen()),
              );
            },
          )
        ],
      ),
      body: productoProvider.isLoading || insumoProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Toca el perro vendido. Se descuenta del inventario automáticamente.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  
                  // Lista de productos
                  ...productoProvider.productos.map((producto) {
                    // Calcular cuántos se pueden hacer
                    int maxPosibles = 9999;
                    producto.receta.forEach((insumoId, cantidadRequerida) {
                      final insumos = insumoProvider.insumos.where((i) => i.id == insumoId);
                      if (insumos.isNotEmpty && cantidadRequerida > 0) {
                        final insumo = insumos.first;
                        int posibles = (insumo.stockActual / cantidadRequerida).floor();
                        if (posibles < maxPosibles) {
                          maxPosibles = posibles;
                        }
                      }
                    });

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: ProductButton(
                        producto: producto,
                        maxPosibles: maxPosibles,
                        onTap: () async {
                          bool exito = await context.read<VentaProvider>().registrarVenta(
                            producto,
                            insumoProvider.insumos,
                          );
                          if (exito) {
                            // Actualizar inventario en UI
                            await context.read<InsumoProvider>().cargarInsumos();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('✅ Vendido: ${producto.nombre}'),
                                  duration: const Duration(seconds: 1),
                                  backgroundColor: AppTheme.success,
                                ),
                              );
                            }
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('❌ No hay inventario suficiente'),
                                  backgroundColor: AppTheme.error,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    );
                  }),

                  const SizedBox(height: 16),
                  
                  // Botón Deshacer
                  if (ventaProvider.ventasDelDia.isNotEmpty)
                    OutlinedButton.icon(
                      onPressed: () async {
                        await context.read<VentaProvider>().deshacerUltimaVenta();
                        await context.read<InsumoProvider>().cargarInsumos();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('↩️ Venta deshecha y stock restaurado')),
                          );
                        }
                      },
                      icon: const Icon(Icons.undo),
                      label: Text(
                        'Deshacer última venta (${currencyFormat.format(ventaProvider.ventasDelDia.first.totalVenta)})',
                      ),
                    ),

                  const SizedBox(height: 24),
                  
                  // Resumen de ventas
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('🕐 Últimas ventas', style: TextStyle(fontWeight: FontWeight.bold)),
                          const Divider(),
                          if (ventaProvider.ventasDelDia.isEmpty)
                            const Text('No hay ventas hoy', style: TextStyle(color: Colors.grey)),
                          ...ventaProvider.ventasDelDia.take(5).map((venta) {
                            final hora = DateFormat('hh:mm a').format(DateTime.parse(venta.fechaHora));
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Text(hora, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                      const SizedBox(width: 8),
                                      if (venta.nota != null)
                                        Text(
                                          venta.nota!,
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                    ],
                                  ),
                                  Text(
                                    currencyFormat.format(venta.totalVenta),
                                    style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
    );
  }
}

