// GPS del teléfono: obtener la ubicación actual.
//
// Pasos: 1) revisar que el GPS esté encendido, 2) pedir permiso al usuario,
// 3) leer la posición. Si algo falla, devuelve un mensaje para mostrar.

import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Centro de Sucre (Plaza 25 de Mayo), para centrar el mapa por defecto.
const centroSucre = LatLng(-19.0476, -65.2596);

/// Devuelve la ubicación actual, o lanza una excepción con el motivo.
Future<LatLng> ubicacionActual() async {
  if (!await Geolocator.isLocationServiceEnabled()) {
    throw Exception('Activa la ubicación (GPS) del teléfono.');
  }
  var permiso = await Geolocator.checkPermission();
  if (permiso == LocationPermission.denied) {
    permiso = await Geolocator.requestPermission();
  }
  if (permiso == LocationPermission.denied ||
      permiso == LocationPermission.deniedForever) {
    throw Exception('La app necesita permiso de ubicación.');
  }
  final p = await Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
  );
  return LatLng(p.latitude, p.longitude);
}
