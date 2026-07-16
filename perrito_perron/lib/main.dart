import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io' show Platform;
import 'theme/app_theme.dart';
import 'screens/main_screen.dart';

// Providers
import 'providers/insumo_provider.dart';
import 'providers/producto_provider.dart';
import 'providers/venta_provider.dart';
import 'providers/gasto_provider.dart';
import 'providers/reporte_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar SQLite para Windows/Linux/Mac para poder probar en PC
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await initializeDateFormatting('es_CO', null);
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => InsumoProvider()),
        ChangeNotifierProvider(create: (_) => ProductoProvider()),
        ChangeNotifierProvider(create: (_) => VentaProvider()),
        ChangeNotifierProvider(create: (_) => GastoProvider()),
        ChangeNotifierProvider(create: (_) => ReporteProvider()),
      ],
      child: const PerritoPerronApp(),
    ),
  );
}

class PerritoPerronApp extends StatelessWidget {
  const PerritoPerronApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Perrito Perrón',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme, // Por ahora forzamos modo oscuro
      home: MainScreen(key: mainScreenKey),
    );
  }
}
