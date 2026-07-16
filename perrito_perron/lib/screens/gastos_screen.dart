import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/gasto_provider.dart';
import '../models/gasto.dart';
import '../theme/app_theme.dart';

class GastosScreen extends StatelessWidget {
  const GastosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GastoProvider>();
    final currencyFormat = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gastos Diarios 💸'),
      ),
      body: Column(
        children: [
          // Resumen
          Container(
            padding: const EdgeInsets.all(24.0),
            color: AppTheme.error.withValues(alpha: 0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total de gastos hoy:', style: TextStyle(fontSize: 14, color: Colors.grey)),
                    SizedBox(height: 4),
                  ],
                ),
                Text(
                  currencyFormat.format(provider.totalGastosHoy),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.error,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.gastosDelDia.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('💸', style: TextStyle(fontSize: 48)),
                            SizedBox(height: 12),
                            Text('No hay gastos registrados hoy.', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: provider.gastosDelDia.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final gasto = provider.gastosDelDia[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                              child: Icon(Icons.receipt_long, color: AppTheme.primary, size: 20),
                            ),
                            title: Text(
                              gasto.concepto,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              gasto.categoria ?? 'General',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  currencyFormat.format(gasto.monto),
                                  style: TextStyle(
                                    color: AppTheme.error,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, size: 20),
                                  onSelected: (value) {
                                    if (value == 'editar') {
                                      _mostrarDialogoGasto(context, gastoExistente: gasto);
                                    } else if (value == 'eliminar') {
                                      _mostrarDialogoEliminar(context, gasto.id!);
                                    }
                                  },
                                  itemBuilder: (ctx) => [
                                    const PopupMenuItem(
                                      value: 'editar',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit, size: 18),
                                          SizedBox(width: 8),
                                          Text('Editar'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'eliminar',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, size: 18, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Eliminar', style: TextStyle(color: Colors.red)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarDialogoGasto(context),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Gasto'),
      ),
    );
  }

  void _mostrarDialogoGasto(BuildContext context, {Gasto? gastoExistente}) {
    final conceptoCtrl = TextEditingController(text: gastoExistente?.concepto ?? '');
    final montoCtrl = TextEditingController(text: gastoExistente?.monto != null ? gastoExistente!.monto.toInt().toString() : '');
    String categoriaSel = gastoExistente?.categoria ?? 'Operativo';
    final List<String> categorias = ['Operativo', 'Insumos extra', 'Nómina', 'Servicios', 'Otro'];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(gastoExistente == null ? 'Registrar Gasto' : 'Editar Gasto'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: conceptoCtrl,
                    decoration: const InputDecoration(labelText: 'Concepto (ej: Ayudante, Gas, Hielo)'),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: montoCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Monto (\$)'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: categoriaSel,
                    decoration: const InputDecoration(labelText: 'Categoría'),
                    items: categorias.map((cat) {
                      return DropdownMenuItem(value: cat, child: Text(cat));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => categoriaSel = val);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (conceptoCtrl.text.isNotEmpty && montoCtrl.text.isNotEmpty) {
                      final nuevoGasto = Gasto(
                        id: gastoExistente?.id,
                        fecha: gastoExistente?.fecha ?? DateFormat('yyyy-MM-dd').format(DateTime.now()),
                        concepto: conceptoCtrl.text,
                        monto: double.tryParse(montoCtrl.text) ?? 0.0,
                        categoria: categoriaSel,
                        tipo: 'variable',
                      );

                      if (gastoExistente == null) {
                        context.read<GastoProvider>().agregarGasto(nuevoGasto);
                      } else {
                        context.read<GastoProvider>().editarGasto(nuevoGasto);
                      }
                      Navigator.pop(context);
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

  void _mostrarDialogoEliminar(BuildContext context, int gastoId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('¿Eliminar gasto?'),
          content: const Text('Esta acción no se puede deshacer.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                context.read<GastoProvider>().eliminarGasto(gastoId);
                Navigator.pop(context);
              },
              child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
