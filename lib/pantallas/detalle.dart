// Detalle de un local: fotos, datos, menú y botón "Cómo llegar".
// Los datos salen de SQLite, así que se ven aunque no haya internet.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../modelos.dart';
import '../servicios/base_local.dart';

class DetallePantalla extends StatefulWidget {
  const DetallePantalla({super.key, required this.id});
  final String id;

  @override
  State<DetallePantalla> createState() => _DetallePantallaState();
}

class _DetallePantallaState extends State<DetallePantalla> {
  Establecimiento? _local;

  @override
  void initState() {
    super.initState();
    BaseLocal.detalle(widget.id).then((e) => setState(() => _local = e));
  }

  /// Abre Google Maps buscando el nombre y la dirección del local.
  void _comoLlegar() {
    final e = _local!;
    final url = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': '${e.nombre}, ${e.direccion}, Sucre, Bolivia',
    });
    launchUrl(url, mode: LaunchMode.externalApplication);
  }

  /// Muestra la foto en pantalla completa (se puede ampliar con dos dedos).
  void _ampliar(String foto) {
    showDialog(
      context: context,
      builder: (_) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(child: Center(child: Image.memory(base64Decode(foto)))),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final e = _local;
    if (e == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: Text(e.nombre)),
      body: ListView(
        children: [
          if (e.fotos.isNotEmpty)
            SizedBox(
              height: 220,
              child: PageView(
                children: [
                  for (final f in e.fotos)
                    GestureDetector(
                      onTap: () => _ampliar(f),
                      child: Image.memory(base64Decode(f), fit: BoxFit.cover),
                    ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${e.tipo} · ${nombresPrecio[e.precio]}',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(e.descripcion),
                const SizedBox(height: 12),
                _dato(Icons.place, e.direccion),
                _dato(Icons.schedule, e.horario),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: _comoLlegar,
                  icon: const Icon(Icons.directions),
                  label: const Text('Cómo llegar'),
                ),
                const SizedBox(height: 16),
                Text('Menú', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
          ),
          for (final p in e.platos)
            ListTile(
              title: Text(p.nombre),
              subtitle: Text(p.dieta == 'Ninguna' ? p.comida : '${p.comida} · ${p.dieta}'),
              trailing: Text('Bs ${p.precio.toStringAsFixed(2)}'),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _dato(IconData icono, String texto) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(children: [
          Icon(icono, size: 18),
          const SizedBox(width: 6),
          Expanded(child: Text(texto)),
        ]),
      );
}
