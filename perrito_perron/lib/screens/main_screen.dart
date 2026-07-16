import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'ventas_screen.dart';
import 'insumos_screen.dart';
import 'gastos_screen.dart';
import 'reportes_screen.dart';

// GlobalKey para poder navegar entre tabs desde cualquier pantalla
final GlobalKey<MainScreenState> mainScreenKey = GlobalKey<MainScreenState>();

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  void navegarATab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  final List<Widget> _screens = const [
    DashboardScreen(),
    VentasScreen(),
    InsumosScreen(),
    GastosScreen(),
    ReportesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Text('🌭', style: TextStyle(fontSize: 20)),
            label: 'Ventas',
          ),
          BottomNavigationBarItem(
            icon: Text('📦', style: TextStyle(fontSize: 20)),
            label: 'Inventario',
          ),
          BottomNavigationBarItem(
            icon: Text('💸', style: TextStyle(fontSize: 20)),
            label: 'Gastos',
          ),
          BottomNavigationBarItem(
            icon: Text('📈', style: TextStyle(fontSize: 20)),
            label: 'Reportes',
          ),
        ],
      ),
    );
  }
}
