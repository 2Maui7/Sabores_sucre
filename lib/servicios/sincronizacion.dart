// Sincronización: copia lo de Firebase (nube) a SQLite (teléfono).
//
// Es como sacar una fotocopia nueva cada vez:
//   1. Se descargan de Firebase todos los locales aprobados y los catálogos.
//   2. Se borra la copia vieja de SQLite y se guarda la nueva.
// Si no hay internet, no se toca nada y la app sigue mostrando la copia
// que ya tenía.

import 'package:flutter/foundation.dart';

import 'base_local.dart';
import 'firebase_servicio.dart';

/// Devuelve true si se pudo actualizar, o false si no hay conexión.
Future<bool> sincronizar() async {
  debugPrint('Sincronizando...');
  try {
    final locales = await descargarAprobados();
    final catalogos = await descargarCatalogos();
    await BaseLocal.guardarCopia(locales, catalogos);
    debugPrint('Sincronizado: ${locales.length} locales aprobados');
    return true;
  } catch (e) {
    debugPrint('No se pudo sincronizar: $e');
    return false; // sin internet: se usa la copia guardada
  }
}
