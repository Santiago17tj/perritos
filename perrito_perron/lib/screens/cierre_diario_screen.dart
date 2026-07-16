import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../providers/reporte_provider.dart';
import '../providers/insumo_provider.dart';
import '../models/cierre_diario.dart';
import '../database/database_helper.dart';

class CierreDiarioScreen extends StatefulWidget {
  const CierreDiarioScreen({super.key});

  @override
  State<CierreDiarioScreen> createState() => _CierreDiarioScreenState();
}

class _CierreDiarioScreenState extends State<CierreDiarioScreen> {
  bool _guardando = false;

  @override
  Widget build(BuildContext context) {
    final reporte = context.watch<ReporteProvider>();
    final insumos = context.watch<InsumoProvider>();
    final currencyFormat = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

    final gananciaNeta = reporte.resumenHoy['gananciaNeta'] ?? 0.0;
    final totalVentas = reporte.resumenHoy['totalVentas'] ?? 0.0;
    final costoVentas = reporte.resumenHoy['costoVentas'] ?? 0.0;
    final totalGastos = reporte.resumenHoy['totalGastos'] ?? 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cierre de Caja 🔒'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Resumen del Día',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildRow('Total Ventas:', totalVentas, currencyFormat, Colors.white),
                    const Divider(),
                    _buildRow('Costo de Ventas (Insumos):', -costoVentas, currencyFormat, Colors.orange),
                    const Divider(),
                    _buildRow('Total Gastos Extras:', -totalGastos, currencyFormat, Colors.red),
                    const Divider(thickness: 2),
                    _buildRow('Ganancia Neta Calculada:', gananciaNeta, currencyFormat, gananciaNeta >= 0 ? Colors.green : Colors.red, isBold: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '¿Estás seguro de hacer el cierre?',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Esto guardará un historial de hoy para tus reportes.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).primaryColor,
              ),
              onPressed: _guardando ? null : () => _realizarCierre(
                totalVentas,
                totalGastos,
                costoVentas,
                gananciaNeta,
                insumos.insumos,
              ),
              icon: _guardando ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.lock),
              label: const Text('Confirmar Cierre Diario', style: TextStyle(fontSize: 16)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, double value, NumberFormat format, Color color, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 16, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(
            format.format(value),
            style: TextStyle(fontSize: 16, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color),
          ),
        ],
      ),
    );
  }

  Future<void> _realizarCierre(
    double totalVentas,
    double totalGastos,
    double costoInsumos,
    double gananciaNeta,
    List<dynamic> insumos,
  ) async {
    setState(() => _guardando = true);
    
    try {
      final dbHelper = DatabaseHelper.instance;
      final db = await dbHelper.database;

      // Crear snapshot del inventario
      Map<String, dynamic> inventarioSnapshot = {};
      for (var insumo in insumos) {
        inventarioSnapshot[insumo.nombre] = insumo.stockActual;
      }

      final cierre = CierreDiario(
        fecha: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        totalVentas: totalVentas,
        totalGastos: totalGastos,
        costoInsumos: costoInsumos,
        gananciaNeta: gananciaNeta,
        inventarioSnapshot: jsonEncode(inventarioSnapshot),
      );

      await db.insert(DatabaseHelper.tableCierres, cierre.toMap());
      
      // Actualizar reportes
      if (mounted) {
        await context.read<ReporteProvider>().cargarDatos();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cierre diario guardado exitosamente ✅')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }
}
