// La base de datos LOCAL (SQLite), guardada dentro del teléfono.
//
// Es una copia de lo que hay en Firebase: solo los locales aprobados y los
// catálogos. Las pantallas del visitante leen SIEMPRE de aquí, por eso la
// app funciona aunque no haya internet.
//
// Tiene 4 tablas:
//   establecimientos  (id, nombre, tipo, descripcion, direccion, horario, precio)
//   platos            (establecimiento_id, nombre, precio, comida, dieta)
//   fotos             (establecimiento_id, imagen)
//   catalogos         (grupo, nombre)   grupo = tipo | comida | dieta

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../modelos.dart';

class BaseLocal {
  // Se pueden cambiar en las pruebas para usar una base en memoria.
  static DatabaseFactory fabrica = databaseFactory;
  static String? ruta;

  static Database? _db;

  /// Abre la base (y la crea la primera vez).
  static Future<Database> abrir() async {
    if (_db != null) return _db!;
    final archivo = ruta ?? join(await getDatabasesPath(), 'sabores.db');
    _db = await fabrica.openDatabase(
      archivo,
      options: OpenDatabaseOptions(version: 1, onCreate: _crearTablas),
    );
    return _db!;
  }

  static Future<void> _crearTablas(Database db, int version) async {
    await db.execute('''
      CREATE TABLE establecimientos (
        id TEXT PRIMARY KEY,
        nombre TEXT, tipo TEXT, descripcion TEXT,
        direccion TEXT, horario TEXT, precio INTEGER
      )''');
    await db.execute('''
      CREATE TABLE platos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        establecimiento_id TEXT,
        nombre TEXT, precio REAL, comida TEXT, dieta TEXT
      )''');
    await db.execute('''
      CREATE TABLE fotos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        establecimiento_id TEXT,
        imagen TEXT
      )''');
    await db.execute('CREATE TABLE catalogos (grupo TEXT, nombre TEXT)');
  }

  /// Reemplaza TODA la copia local por lo que llegó de Firebase.
  /// Se hace en una transacción: o se guarda todo, o no se guarda nada.
  static Future<void> guardarCopia(
      List<Establecimiento> locales, Catalogos catalogos) async {
    final db = await abrir();
    await db.transaction((t) async {
      // 1. Borrar la copia anterior.
      await t.delete('establecimientos');
      await t.delete('platos');
      await t.delete('fotos');
      await t.delete('catalogos');

      // 2. Guardar los locales con sus platos y fotos.
      for (final e in locales) {
        await t.insert('establecimientos', {
          'id': e.id,
          'nombre': e.nombre,
          'tipo': e.tipo,
          'descripcion': e.descripcion,
          'direccion': e.direccion,
          'horario': e.horario,
          'precio': e.precio,
        });
        for (final p in e.platos) {
          await t.insert('platos', {'establecimiento_id': e.id, ...p.aMapa()});
        }
        for (final f in e.fotos) {
          await t.insert('fotos', {'establecimiento_id': e.id, 'imagen': f});
        }
      }

      // 3. Guardar los catálogos.
      for (final n in catalogos.tipos) {
        await t.insert('catalogos', {'grupo': 'tipo', 'nombre': n});
      }
      for (final n in catalogos.comidas) {
        await t.insert('catalogos', {'grupo': 'comida', 'nombre': n});
      }
      for (final n in catalogos.dietas) {
        await t.insert('catalogos', {'grupo': 'dieta', 'nombre': n});
      }
    });
  }

  /// Lista de locales con búsqueda y filtros (todos opcionales).
  /// Cada fila trae también su primera foto como 'portada'.
  static Future<List<Map<String, dynamic>>> listar({
    String texto = '',
    String? tipo,
    String? comida,
    int? precio,
    String? dieta,
  }) async {
    final db = await abrir();
    var sql = '''
      SELECT e.*,
        (SELECT imagen FROM fotos f WHERE f.establecimiento_id = e.id
         ORDER BY f.id LIMIT 1) AS portada
      FROM establecimientos e
      WHERE 1 = 1''';
    final valores = <Object>[];

    if (texto.trim().isNotEmpty) {
      // Busca en el nombre del local o en el nombre de sus platos.
      sql += ''' AND (e.nombre LIKE ? OR e.id IN
        (SELECT establecimiento_id FROM platos WHERE nombre LIKE ?))''';
      valores.addAll(['%${texto.trim()}%', '%${texto.trim()}%']);
    }
    if (tipo != null) {
      sql += ' AND e.tipo = ?';
      valores.add(tipo);
    }
    if (precio != null) {
      sql += ' AND e.precio = ?';
      valores.add(precio);
    }
    if (comida != null) {
      sql += ' AND e.id IN (SELECT establecimiento_id FROM platos WHERE comida = ?)';
      valores.add(comida);
    }
    if (dieta != null) {
      sql += ' AND e.id IN (SELECT establecimiento_id FROM platos WHERE dieta = ?)';
      valores.add(dieta);
    }
    sql += ' ORDER BY e.nombre';
    return db.rawQuery(sql, valores);
  }

  /// Un local completo, con su menú y sus fotos.
  static Future<Establecimiento?> detalle(String id) async {
    final db = await abrir();
    final filas =
        await db.query('establecimientos', where: 'id = ?', whereArgs: [id]);
    if (filas.isEmpty) return null;
    final platos = await db.query('platos',
        where: 'establecimiento_id = ?', whereArgs: [id], orderBy: 'comida');
    final fotos = await db.query('fotos',
        where: 'establecimiento_id = ?', whereArgs: [id], orderBy: 'id');
    return Establecimiento.desdeMapa(id, {
      ...filas.first,
      'estado': 'aprobado',
      'fotos': [for (final f in fotos) f['imagen']],
      'platos': platos,
    });
  }

  /// Opciones de un catálogo: grupo = 'tipo', 'comida' o 'dieta'.
  static Future<List<String>> catalogo(String grupo) async {
    final db = await abrir();
    final filas =
        await db.query('catalogos', where: 'grupo = ?', whereArgs: [grupo]);
    return [for (final f in filas) f['nombre'] as String];
  }
}
