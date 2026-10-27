// TODO lo que la app hace con Firebase está en este archivo.
//
// Firebase tiene dos partes que usamos:
//  - Authentication: las cuentas (correo y contraseña).
//  - Firestore: la base de datos en la nube, con 3 colecciones:
//      usuarios/{uid}          -> nombre, correo, rol, activo
//      establecimientos/{uid}  -> el local de cada propietario
//      catalogos/general       -> listas de tipos, comidas y dietas
//
// Las reglas de seguridad (archivo firestore.rules) se revisan en el
// servidor: aunque alguien modifique la app, no puede saltárselas.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../modelos.dart';

final _auth = FirebaseAuth.instance;
final _db = FirebaseFirestore.instance;

// ---------------------------------------------------------------- CUENTAS

/// El usuario con sesión iniciada, o null si nadie inició sesión.
User? get usuarioActual => _auth.currentUser;

/// Crea la cuenta del propietario y su ficha en `usuarios`.
Future<void> registrar(String nombre, String correo, String clave) async {
  final cuenta = await _auth.createUserWithEmailAndPassword(
      email: correo.trim(), password: clave);
  await _db.collection('usuarios').doc(cuenta.user!.uid).set({
    'nombre': nombre.trim(),
    'correo': correo.trim(),
    'rol': 'propietario', // nadie puede registrarse como admin
    'activo': true,
  });
}

/// Inicia sesión y devuelve el rol ('propietario' o 'admin').
Future<String> iniciarSesion(String correo, String clave) async {
  await _auth.signInWithEmailAndPassword(email: correo.trim(), password: clave);
  final perfil = await leerPerfil();
  if (perfil == null || perfil['activo'] != true) {
    await _auth.signOut();
    throw Exception('Tu cuenta está suspendida o no existe.');
  }
  return perfil['rol'];
}

/// Lee la ficha del usuario actual: {nombre, correo, rol, activo}.
Future<Map<String, dynamic>?> leerPerfil() async {
  final uid = usuarioActual?.uid;
  if (uid == null) return null;
  final doc = await _db.collection('usuarios').doc(uid).get();
  return doc.data();
}

Future<void> recuperarClave(String correo) =>
    _auth.sendPasswordResetEmail(email: correo.trim());

Future<void> cerrarSesion() => _auth.signOut();

/// Traduce los errores de Firebase a un mensaje entendible.
String mensajeError(Object e) {
  if (e is FirebaseAuthException) {
    return switch (e.code) {
      'email-already-in-use' => 'Ese correo ya está registrado.',
      'invalid-email' => 'El correo no es válido.',
      'weak-password' => 'La contraseña debe tener al menos 6 caracteres.',
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' =>
        'Correo o contraseña incorrectos.',
      'network-request-failed' => 'No hay conexión a internet.',
      _ when '${e.message}'.contains('CONFIGURATION_NOT_FOUND') =>
        'Authentication no está activado en Firebase (consola → Authentication → Comenzar).',
      _ => 'Error: ${e.code} ${e.message ?? ''}',
    };
  }
  if (e is FirebaseException && e.code == 'permission-denied') {
    return 'No tienes permiso para hacer eso.';
  }
  return e.toString().replaceFirst('Exception: ', '');
}

// ------------------------------------------------------- PROPIETARIO

/// El local del propietario actual (o null si todavía no lo creó).
Future<Establecimiento?> miEstablecimiento() async {
  final uid = usuarioActual!.uid;
  final doc = await _db.collection('establecimientos').doc(uid).get();
  if (!doc.exists) return null;
  return Establecimiento.desdeMapa(doc.id, doc.data()!);
}

/// Guarda el local del propietario.
/// - Si es nuevo, se crea como 'pendiente' (espera la aprobación del admin).
/// - Si ya existe, solo se actualizan sus datos; el estado no cambia.
/// - Si fue rechazado y [reenviar] es true, vuelve a quedar 'pendiente'.
Future<void> guardarMiEstablecimiento(Establecimiento e,
    {required bool esNuevo, bool reenviar = false}) async {
  final ref = _db.collection('establecimientos').doc(e.id);
  if (esNuevo) {
    await ref.set({...e.aMapa(), 'estado': 'pendiente', 'motivo': ''});
  } else if (reenviar) {
    await ref.update({...e.aMapa(), 'estado': 'pendiente', 'motivo': ''});
  } else {
    await ref.update(e.aMapa());
  }
}

// ------------------------------------------------------- ADMINISTRADOR

/// Locales en un estado ('pendiente', 'aprobado' o 'suspendido').
Future<List<Establecimiento>> establecimientosPorEstado(String estado) async {
  final r = await _db
      .collection('establecimientos')
      .where('estado', isEqualTo: estado)
      .get();
  return [for (final d in r.docs) Establecimiento.desdeMapa(d.id, d.data())];
}

/// Aprobar, rechazar (con motivo), suspender o reactivar un local.
Future<void> cambiarEstado(String id, String estado, {String motivo = ''}) =>
    _db
        .collection('establecimientos')
        .doc(id)
        .update({'estado': estado, 'motivo': motivo});

/// Todas las cuentas de propietarios.
Future<List<Map<String, dynamic>>> propietarios() async {
  final r = await _db
      .collection('usuarios')
      .where('rol', isEqualTo: 'propietario')
      .get();
  return [for (final d in r.docs) {'uid': d.id, ...d.data()}];
}

/// Suspende o reactiva la cuenta de un propietario.
/// Al suspenderla, su local también se suspende.
Future<void> cambiarCuenta(String uid, bool activo) async {
  await _db.collection('usuarios').doc(uid).update({'activo': activo});
  final local = _db.collection('establecimientos').doc(uid);
  if (!activo && (await local.get()).exists) {
    await local.update({
      'estado': 'suspendido',
      'motivo': 'Cuenta suspendida por el administrador.',
    });
  }
}

// ------------------------------------------------------- CATÁLOGOS

Future<Catalogos> leerCatalogos() async {
  final doc = await _db.collection('catalogos').doc('general').get();
  return doc.exists ? Catalogos.desdeMapa(doc.data()!) : Catalogos.porDefecto();
}

Future<void> guardarCatalogos(Catalogos c) =>
    _db.collection('catalogos').doc('general').set(c.aMapa());

// ------------------------------------------------------- SINCRONIZACIÓN

/// Descarga del servidor todos los locales aprobados.
/// `Source.server` obliga a ir a internet: si no hay conexión, da error.
Future<List<Establecimiento>> descargarAprobados() async {
  final r = await _db
      .collection('establecimientos')
      .where('estado', isEqualTo: 'aprobado')
      .get(const GetOptions(source: Source.server));
  return [for (final d in r.docs) Establecimiento.desdeMapa(d.id, d.data())];
}

/// Descarga los catálogos del servidor (o los de inicio si no hay).
Future<Catalogos> descargarCatalogos() async {
  final doc = await _db
      .collection('catalogos')
      .doc('general')
      .get(const GetOptions(source: Source.server));
  return doc.exists ? Catalogos.desdeMapa(doc.data()!) : Catalogos.porDefecto();
}
