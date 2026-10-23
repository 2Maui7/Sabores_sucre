// Pruebas de los modelos y de la base local (SQLite en memoria).
// Se ejecutan con:  flutter test

import 'package:flutter_test/flutter_test.dart';
import 'package:sabores_sucre/modelos.dart';
import 'package:sabores_sucre/servicios/base_local.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  // Usar SQLite de la PC, en memoria, en vez del teléfono.
  sqfliteFfiInit();
  BaseLocal.fabrica = databaseFactoryFfi;
  BaseLocal.ruta = inMemoryDatabasePath;

  final pension = Establecimiento(
    id: 'uid1',
    nombre: 'Pensión Doña Julia',
    tipo: 'Pensión',
    direccion: 'Calle Ravelo',
    precio: 1,
    estado: 'aprobado',
    fotos: ['Zm90bw=='],
    platos: [
      Plato(nombre: 'Mondongo', precio: 35, comida: 'Plato fuerte', dieta: 'Ninguna'),
      Plato(nombre: 'Sopa de maní', precio: 12, comida: 'Sopa', dieta: 'Vegetariana'),
    ],
  );
  final salteneria = Establecimiento(
    id: 'uid2',
    nombre: 'Salteñería La Recoleta',
    tipo: 'Salteñería',
    precio: 2,
    platos: [
      Plato(nombre: 'Salteña de carne', precio: 8, comida: 'Entrada o snack', dieta: 'Ninguna'),
    ],
  );

  test('El modelo se conserva al pasar por un mapa (como en Firebase)', () {
    final copia = Establecimiento.desdeMapa(pension.id, {
      ...pension.aMapa(),
      'estado': 'aprobado',
    });
    expect(copia.nombre, 'Pensión Doña Julia');
    expect(copia.platos.length, 2);
    expect(copia.platos.first.precio, 35.0);
    expect(copia.fotos.single, 'Zm90bw==');
  });

  test('aMapa no envía estado ni motivo (los decide el admin)', () {
    expect(pension.aMapa().containsKey('estado'), isFalse);
    expect(pension.aMapa().containsKey('motivo'), isFalse);
  });

  group('Base local', () {
    setUp(() => BaseLocal.guardarCopia([pension, salteneria], Catalogos.porDefecto()));

    test('lista todos los locales con su foto de portada', () async {
      final lista = await BaseLocal.listar();
      expect(lista.length, 2);
      expect(lista.first['portada'], 'Zm90bw==');
    });

    test('busca por nombre de plato', () async {
      final lista = await BaseLocal.listar(texto: 'salteña');
      expect(lista.single['nombre'], 'Salteñería La Recoleta');
    });

    test('combina filtros de tipo y precio', () async {
      expect((await BaseLocal.listar(tipo: 'Salteñería', precio: 1)), isEmpty);
      expect((await BaseLocal.listar(tipo: 'Salteñería', precio: 2)).length, 1);
    });

    test('filtra por dieta', () async {
      final lista = await BaseLocal.listar(dieta: 'Vegetariana');
      expect(lista.single['id'], 'uid1');
    });

    test('el detalle trae menú y fotos', () async {
      final e = await BaseLocal.detalle('uid1');
      expect(e!.platos.length, 2);
      expect(e.fotos.length, 1);
    });

    test('una nueva copia reemplaza a la anterior (un local suspendido desaparece)',
        () async {
      await BaseLocal.guardarCopia([pension], Catalogos.porDefecto());
      expect((await BaseLocal.listar()).length, 1);
      expect(await BaseLocal.detalle('uid2'), isNull);
    });

    test('guarda los catálogos', () async {
      expect(await BaseLocal.catalogo('dieta'), contains('Vegana'));
    });
  });
}
