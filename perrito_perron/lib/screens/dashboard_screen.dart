import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/venta_provider.dart';
import '../providers/reporte_provider.dart';
import '../providers/insumo_provider.dart';
import '../models/insumo.dart';
import '../widgets/summary_card.dart';
import '../theme/app_theme.dart';
import 'cierre_diario_screen.dart';
import 'main_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh data when dashboard loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReporteProvider>().cargarDatos();
      context.read<VentaProvider>().cargarVentasHoy();
      context.read<InsumoProvider>().cargarInsumos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final reporte = context.watch<ReporteProvider>();
    final ventas = context.watch<VentaProvider>();
    final insumos = context.watch<InsumoProvider>();
    final currencyFormat = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

    final gananciaNeta = reporte.resumenHoy['gananciaNeta'] ?? 0.0;
    final totalVentas = reporte.resumenHoy['totalVentas'] ?? 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perrito Perrón 🌭'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<ReporteProvider>().cargarDatos();
          await context.read<VentaProvider>().cargarVentasHoy();
          await context.read<InsumoProvider>().cargarInsumos();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Encabezado de fecha
              Text(
                DateFormat.yMMMMEEEEd('es_CO').format(DateTime.now()).toUpperCase(),
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),

              // Tarjetas de resumen
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.3,
                children: [
                  SummaryCard(
                    title: 'Ventas de hoy',
                    value: currencyFormat.format(totalVentas),
                    subtitle: '${ventas.ventasDelDia.length} perros vendidos',
                    color: Theme.of(context).colorScheme.secondary,
                    icon: Icons.point_of_sale,
                  ),
                  SummaryCard(
                    title: 'Ganancia neta',
                    value: currencyFormat.format(gananciaNeta),
                    subtitle: 'Ingresos - Costos - Gastos',
                    color: gananciaNeta >= 0 
                        ? AppTheme.success 
                        : AppTheme.error,
                    icon: Icons.trending_up,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Sección de Alertas
              if (insumos.alertas.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: AppTheme.error),
                    const SizedBox(width: 8),
                    const Text(
                      'Alertas de Inventario',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Card(
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: AppTheme.error.withValues(alpha: 0.5)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: insumos.alertas.length,
                    separatorBuilder: (c, i) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final alerta = insumos.alertas[index];
                      return ListTile(
                        leading: const Text('⚠️', style: TextStyle(fontSize: 20)),
                        title: Text(alerta.nombre),
                        subtitle: Text('Quedan: ${alerta.stockActual} ${alerta.unidadMedida}'),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            minimumSize: const Size(60, 36),
                          ),
                          onPressed: () => _mostrarDialogoSurtir(context, alerta),
                          child: const Text('Surtir'),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Accesos rápidos
              const Text(
                'Accesos rápidos',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        mainScreenKey.currentState?.navegarATab(3);
                      },
                      icon: const Icon(Icons.money_off),
                      label: const Text('Registrar Gasto'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const CierreDiarioScreen()),
                        );
                      },
                      icon: const Icon(Icons.lock_clock),
                      label: const Text('Cierre Diario'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
            autofocus: true,
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
                      SnackBar(
                        content: Text('✅ +$cantidad ${insumo.unidadMedida} de ${insumo.nombre}'),
                        backgroundColor: AppTheme.success,
                      ),
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
}

