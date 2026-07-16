import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/reporte_provider.dart';
import '../theme/app_theme.dart';

class ReportesScreen extends StatelessWidget {
  const ReportesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReporteProvider>();
    final currencyFormat = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes 📈'),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.historialDias.isEmpty
              ? const Center(child: Text('No hay historial de cierres.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Evolución de Ganancias (Últimos Cierres)',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      
                      // Gráfico de Barras
                      SizedBox(
                        height: 250,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: _getMaxGanancia(provider.historialDias) * 1.2,
                              minY: _getMinGanancia(provider.historialDias),
                              barTouchData: BarTouchData(enabled: true),
                              titlesData: FlTitlesData(
                                show: true,
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      if (value.toInt() >= 0 && value.toInt() < provider.historialDias.length) {
                                        // Los datos vienen ordenados DESC, los invertimos para el gráfico
                                        int index = provider.historialDias.length - 1 - value.toInt();
                                        final fechaStr = provider.historialDias[index]['fecha'];
                                        final date = DateTime.parse(fechaStr);
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 8.0),
                                          child: Text(DateFormat('dd/MM').format(date), style: const TextStyle(fontSize: 10)),
                                        );
                                      }
                                      return const Text('');
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false), // Ocultar eje Y para limpieza visual
                                ),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              gridData: const FlGridData(show: false),
                              borderData: FlBorderData(show: false),
                              barGroups: _generarBarGroups(provider.historialDias, context),
                            ),
                          ),
                        ),
                      ),
                      ),
                      
                      const SizedBox(height: 24),
                      const Text(
                        'Historial Detallado',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      
                      // Lista histórica
                      ...provider.historialDias.map((dia) {
                        final fechaStr = dia['fecha'];
                        final date = DateTime.parse(fechaStr);
                        final ganancia = (dia['ganancia_neta'] as num).toDouble();
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ExpansionTile(
                            leading: Icon(
                              ganancia >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                              color: ganancia >= 0 ? AppTheme.success : AppTheme.error,
                            ),
                            title: Text(DateFormat.yMMMd('es_CO').format(date)),
                            subtitle: Text('Ganancia: ${currencyFormat.format(ganancia)}'),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Total Ventas:'),
                                        Text(currencyFormat.format(dia['total_ventas']), style: TextStyle(color: AppTheme.success)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Costo Insumos:'),
                                        Text(currencyFormat.format(dia['costo_insumos']), style: const TextStyle(color: Colors.orange)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Total Gastos:'),
                                        Text(currencyFormat.format(dia['total_gastos']), style: TextStyle(color: AppTheme.error)),
                                      ],
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
    );
  }

  double _getMaxGanancia(List<Map<String, dynamic>> historial) {
    if (historial.isEmpty) return 10000;
    double max = 0;
    for (var dia in historial) {
      final ganancia = (dia['ganancia_neta'] as num).toDouble();
      if (ganancia > max) max = ganancia;
    }
    return max == 0 ? 10000 : max;
  }

  double _getMinGanancia(List<Map<String, dynamic>> historial) {
    if (historial.isEmpty) return 0;
    double min = 0;
    for (var dia in historial) {
      final ganancia = (dia['ganancia_neta'] as num).toDouble();
      if (ganancia < min) min = ganancia;
    }
    return min < 0 ? min * 1.2 : 0;
  }

  List<BarChartGroupData> _generarBarGroups(List<Map<String, dynamic>> historial, BuildContext context) {
    List<BarChartGroupData> groups = [];
    // historial está DESC (más reciente primero), iteramos invertido para el gráfico (izq a der = viejo a nuevo)
    for (int i = 0; i < historial.length; i++) {
      int reversedIndex = historial.length - 1 - i;
      final dia = historial[reversedIndex];
      final ganancia = (dia['ganancia_neta'] as num).toDouble();
      
      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: ganancia,
              color: ganancia >= 0 ? AppTheme.success : AppTheme.error,
              width: 16,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }
    return groups;
  }
}

