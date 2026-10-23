// Mapas de OpenStreetMap (gratis, sin clave) con el paquete flutter_map.
//  - MapaConMarcador: mapa pequeño que solo muestra un punto.
//  - ElegirUbicacionPantalla: mapa grande para tocar y elegir un punto.
// Los mapas necesitan internet para descargar las imágenes de las calles.

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../servicios/firebase_servicio.dart' show mensajeError;
import '../servicios/ubicacion.dart';

/// Capa con las imágenes de las calles (OpenStreetMap).
TileLayer _calles() => TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'bo.edu.itsec.sabores_sucre',
    );

/// Pin rojo en el punto indicado.
MarkerLayer _marcador(LatLng punto) => MarkerLayer(markers: [
      Marker(
        point: punto,
        width: 40,
        height: 40,
        alignment: Alignment.topCenter,
        child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
      ),
    ]);

/// Mapa pequeño, sin interacción, que muestra dónde está el local.
class MapaConMarcador extends StatelessWidget {
  const MapaConMarcador({super.key, required this.punto, this.alto = 160});
  final LatLng punto;
  final double alto;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: alto,
      child: FlutterMap(
        // La key hace que el mapa se vuelva a centrar si cambia el punto.
        key: ValueKey(punto),
        options: MapOptions(
          initialCenter: punto,
          initialZoom: 16,
          interactionOptions:
              const InteractionOptions(flags: InteractiveFlag.none),
        ),
        children: [_calles(), _marcador(punto)],
      ),
    );
  }
}

/// Pantalla para elegir la ubicación tocando el mapa.
/// Devuelve el punto elegido al pulsar "Confirmar".
class ElegirUbicacionPantalla extends StatefulWidget {
  const ElegirUbicacionPantalla({super.key, this.inicial});
  final LatLng? inicial;

  @override
  State<ElegirUbicacionPantalla> createState() =>
      _ElegirUbicacionPantallaState();
}

class _ElegirUbicacionPantallaState extends State<ElegirUbicacionPantalla> {
  final _mapa = MapController();
  late LatLng _punto = widget.inicial ?? centroSucre;

  /// Mueve el pin y el mapa a la ubicación actual del teléfono.
  Future<void> _irAMiUbicacion() async {
    try {
      final aqui = await ubicacionActual();
      setState(() => _punto = aqui);
      _mapa.move(aqui, 17);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(mensajeError(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Toca el mapa para marcar tu local')),
      body: FlutterMap(
        mapController: _mapa,
        options: MapOptions(
          initialCenter: _punto,
          initialZoom: 16,
          // Tocar el mapa mueve el pin a ese lugar.
          onTap: (_, punto) => setState(() => _punto = punto),
        ),
        children: [_calles(), _marcador(_punto)],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Mi ubicación',
        onPressed: _irAMiUbicacion,
        child: const Icon(Icons.my_location),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(
            onPressed: () => Navigator.pop(context, _punto),
            icon: const Icon(Icons.check),
            label: const Text('Confirmar ubicación'),
          ),
        ),
      ),
    );
  }
}
