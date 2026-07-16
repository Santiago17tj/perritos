import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DatabaseHelper {
  static const _databaseName = "PerritoPerron.db";
  static const _databaseVersion = 1;

  // Tablas
  static const tableInsumos = 'insumos';
  static const tableProductos = 'productos';
  static const tableVentas = 'ventas';
  static const tableDetalleVenta = 'detalle_venta';
  static const tableGastos = 'gastos_operativos';
  static const tableInventarioDiario = 'inventario_diario';
  static const tableCierres = 'cierres_diarios';

  // Make this a singleton class
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableInsumos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        costo_unitario REAL NOT NULL,
        precio_venta REAL NOT NULL,
        stock_actual REAL NOT NULL,
        stock_minimo REAL NOT NULL,
        unidad_medida TEXT NOT NULL,
        fecha_actualizacion TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableProductos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        emoji TEXT NOT NULL,
        precio_venta REAL NOT NULL,
        receta TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableVentas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fecha_hora TEXT NOT NULL,
        total_venta REAL NOT NULL,
        metodo_pago TEXT,
        nota TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableDetalleVenta (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        venta_id INTEGER NOT NULL,
        insumo_id INTEGER NOT NULL,
        cantidad REAL NOT NULL,
        precio_unitario REAL NOT NULL,
        costo_unitario REAL NOT NULL,
        subtotal REAL NOT NULL,
        FOREIGN KEY (venta_id) REFERENCES $tableVentas (id) ON DELETE CASCADE,
        FOREIGN KEY (insumo_id) REFERENCES $tableInsumos (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableGastos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fecha TEXT NOT NULL,
        concepto TEXT NOT NULL,
        monto REAL NOT NULL,
        categoria TEXT,
        tipo TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableInventarioDiario (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fecha TEXT NOT NULL,
        insumo_id INTEGER NOT NULL,
        cantidad_inicial REAL NOT NULL,
        FOREIGN KEY (insumo_id) REFERENCES $tableInsumos (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableCierres (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fecha TEXT NOT NULL,
        total_ventas REAL NOT NULL,
        total_gastos REAL NOT NULL,
        costo_insumos REAL NOT NULL,
        ganancia_neta REAL NOT NULL,
        inventario_snapshot TEXT
      )
    ''');
    
    // Insert initial default products
    await _seedDefaultData(db);
  }

  Future<void> _seedDefaultData(Database db) async {
    // 1. Insertar insumos por defecto
    List<Map<String, dynamic>> insumosIniciales = [
      {'nombre': 'Salchichas', 'costo_unitario': 1500.0, 'precio_venta': 0.0, 'stock_actual': 0.0, 'stock_minimo': 10.0, 'unidad_medida': 'unidad'},
      {'nombre': 'Panes', 'costo_unitario': 800.0, 'precio_venta': 0.0, 'stock_actual': 0.0, 'stock_minimo': 10.0, 'unidad_medida': 'unidad'},
      {'nombre': 'Bebidas', 'costo_unitario': 2000.0, 'precio_venta': 0.0, 'stock_actual': 0.0, 'stock_minimo': 10.0, 'unidad_medida': 'unidad'},
      {'nombre': 'Queso', 'costo_unitario': 500.0, 'precio_venta': 0.0, 'stock_actual': 0.0, 'stock_minimo': 5.0, 'unidad_medida': 'porción'},
    ];
    
    for (var insumo in insumosIniciales) {
      await db.insert(tableInsumos, insumo);
    }

    // 2. Insertar productos por defecto
    // Asumiendo IDs: 1=Salchichas, 2=Panes, 3=Bebidas
    List<Map<String, dynamic>> productosIniciales = [
      {'nombre': 'Sencillo', 'emoji': '🌭', 'precio_venta': 6000.0, 'receta': '{"1":1.0,"2":1.0,"3":1.0}'},
      {'nombre': 'Doble', 'emoji': '🌭🌭', 'precio_venta': 8000.0, 'receta': '{"1":2.0,"2":1.0,"3":1.0}'},
      {'nombre': 'Americano', 'emoji': '🔥', 'precio_venta': 10000.0, 'receta': '{"1":1.0,"2":1.0,"3":1.0,"4":1.0}'},
    ];

    for (var producto in productosIniciales) {
      await db.insert(tableProductos, producto);
    }
  }

  // Backup method could go here
}
