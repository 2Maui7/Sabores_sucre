// Panel del propietario: llena los datos de su local, su menú y sus fotos.
// Todo se guarda directamente en Firebase (no en SQLite).

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../modelos.dart';
import '../servicios/firebase_servicio.dart';
import '../servicios/ubicacion.dart';
import 'mapa.dart';

class PanelPropietario extends StatefulWidget {
  const PanelPropietario({super.key});

  @override
  State<PanelPropietario> createState() => _PanelPropietarioState();
}

class _PanelPropietarioState extends State<PanelPropietario> {
  final _form = GlobalKey<FormState>();
  Establecimiento? _local;
  bool _esNuevo = true;
  Catalogos _catalogos = Catalogos.porDefecto();
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final guardado = await miEstablecimiento();
    final catalogos = await leerCatalogos();
    setState(() {
      _catalogos = catalogos;
      _esNuevo = guardado == null;
      // Si todavía no tiene local, empieza con uno vacío.
      _local = guardado ?? Establecimiento(id: usuarioActual!.uid);
    });
  }

  void _mensaje(String texto) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));

  Future<void> _guardar({bool reenviar = false}) async {
    if (!_form.currentState!.validate()) return;
    if (!_local!.tieneUbicacion) {
      _mensaje('Marca la ubicación de tu local.');
      return;
    }
    if (_local!.platos.isEmpty) {
      _mensaje('Agrega al menos un plato.');
      return;
    }
    setState(() => _guardando = true);
    try {
      await guardarMiEstablecimiento(_local!,
          esNuevo: _esNuevo, reenviar: reenviar);
      _mensaje(_esNuevo || reenviar
          ? 'Enviado. El administrador lo revisará.'
          : 'Cambios guardados.');
      await _cargar();
    } catch (e) {
      _mensaje(mensajeError(e));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  /// Elige una foto de la galería, la achica y la convierte en texto.
  Future<void> _agregarFoto() async {
    final foto = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 800, // reducida para que pese poco (unos 100 KB)
      imageQuality: 60,
    );
    if (foto == null) return;
    final texto = base64Encode(await foto.readAsBytes());
    setState(() => _local!.fotos.add(texto));
  }

  /// Opción 1: usar el GPS del teléfono (estando en el local).
  Future<void> _usarMiUbicacion() async {
    try {
      final aqui = await ubicacionActual();
      setState(() {
        _local!.latitud = aqui.latitude;
        _local!.longitud = aqui.longitude;
      });
    } catch (e) {
      _mensaje(mensajeError(e));
    }
  }

  /// Opción 2: elegir el punto tocando un mapa.
  Future<void> _elegirEnMapa() async {
    final e = _local!;
    final punto = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => ElegirUbicacionPantalla(
          inicial: e.tieneUbicacion ? LatLng(e.latitud!, e.longitud!) : null,
        ),
      ),
    );
    if (punto != null) {
      setState(() {
        e.latitud = punto.latitude;
        e.longitud = punto.longitude;
      });
    }
  }

  /// Vista previa del mapa y los dos botones para marcar la ubicación.
  Widget _seccionUbicacion(Establecimiento e) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (e.tieneUbicacion)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: MapaConMarcador(punto: LatLng(e.latitud!, e.longitud!)),
          )
        else
          const Text('Todavía no marcaste la ubicación de tu local.'),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: [
          OutlinedButton.icon(
            onPressed: _usarMiUbicacion,
            icon: const Icon(Icons.my_location),
            label: const Text('Usar mi ubicación actual'),
          ),
          OutlinedButton.icon(
            onPressed: _elegirEnMapa,
            icon: const Icon(Icons.map),
            label: const Text('Elegir en el mapa'),
          ),
        ]),
      ],
    );
  }

  /// Ventana para agregar o editar un plato.
  Future<void> _editarPlato([Plato? plato]) async {
    final nombre = TextEditingController(text: plato?.nombre);
    final precio = TextEditingController(
        text: plato == null ? '' : plato.precio.toStringAsFixed(2));
    var comida = plato?.comida ?? _catalogos.comidas.first;
    var dieta = plato?.dieta ?? _catalogos.dietas.first;
    final formPlato = GlobalKey<FormState>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(plato == null ? 'Nuevo plato' : 'Editar plato'),
        content: Form(
          key: formPlato,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(
              controller: nombre,
              decoration: const InputDecoration(labelText: 'Nombre'),
              validator: (v) => v!.trim().isEmpty ? 'Escribe el nombre' : null,
            ),
            TextFormField(
              controller: precio,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Precio (Bs)'),
              validator: (v) {
                final n = double.tryParse(v!.replaceAll(',', '.'));
                return n == null || n <= 0 ? 'Precio mayor a 0' : null;
              },
            ),
            DropdownButtonFormField(
              initialValue: _catalogos.comidas.contains(comida) ? comida : null,
              decoration: const InputDecoration(labelText: 'Tipo de comida'),
              items: [
                for (final c in _catalogos.comidas)
                  DropdownMenuItem(value: c, child: Text(c))
              ],
              onChanged: (v) => comida = v!,
            ),
            DropdownButtonFormField(
              initialValue: _catalogos.dietas.contains(dieta) ? dieta : null,
              decoration: const InputDecoration(labelText: 'Dieta'),
              items: [
                for (final d in _catalogos.dietas)
                  DropdownMenuItem(value: d, child: Text(d))
              ],
              onChanged: (v) => dieta = v!,
            ),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              if (formPlato.currentState!.validate()) Navigator.pop(context, true);
            },
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final nuevo = Plato(
      nombre: nombre.text.trim(),
      precio: double.parse(precio.text.replaceAll(',', '.')),
      comida: comida,
      dieta: dieta,
    );
    setState(() {
      if (plato == null) {
        _local!.platos.add(nuevo);
      } else {
        _local!.platos[_local!.platos.indexOf(plato)] = nuevo;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final e = _local;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi local'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await cerrarSesion();
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
      body: e == null
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _avisoEstado(e),
                  TextFormField(
                    initialValue: e.nombre,
                    decoration: const InputDecoration(labelText: 'Nombre del local'),
                    validator: (v) => v!.trim().isEmpty ? 'Obligatorio' : null,
                    onChanged: (v) => e.nombre = v.trim(),
                  ),
                  DropdownButtonFormField(
                    initialValue: _catalogos.tipos.contains(e.tipo) ? e.tipo : null,
                    decoration: const InputDecoration(labelText: 'Tipo de local'),
                    items: [
                      for (final t in _catalogos.tipos)
                        DropdownMenuItem(value: t, child: Text(t))
                    ],
                    validator: (v) => v == null ? 'Elige uno' : null,
                    onChanged: (v) => e.tipo = v!,
                  ),
                  TextFormField(
                    initialValue: e.descripcion,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Descripción'),
                    onChanged: (v) => e.descripcion = v.trim(),
                  ),
                  TextFormField(
                    initialValue: e.direccion,
                    decoration: const InputDecoration(labelText: 'Dirección'),
                    validator: (v) => v!.trim().isEmpty ? 'Obligatorio' : null,
                    onChanged: (v) => e.direccion = v.trim(),
                  ),
                  TextFormField(
                    initialValue: e.horario,
                    decoration: const InputDecoration(
                        labelText: 'Horario', hintText: 'Lun–Sáb 11:30–15:00'),
                    onChanged: (v) => e.horario = v.trim(),
                  ),
                  DropdownButtonFormField(
                    initialValue: e.precio,
                    decoration: const InputDecoration(labelText: 'Precios'),
                    items: [
                      for (final p in nombresPrecio.entries)
                        DropdownMenuItem(value: p.key, child: Text(p.value))
                    ],
                    onChanged: (v) => e.precio = v!,
                  ),
                  const SizedBox(height: 16),
                  _titulo('Ubicación en el mapa'),
                  _seccionUbicacion(e),
                  const SizedBox(height: 16),
                  _titulo('Fotos (máximo 3)'),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final f in e.fotos)
                      Stack(children: [
                        Image.memory(base64Decode(f),
                            width: 90, height: 90, fit: BoxFit.cover),
                        Positioned(
                          right: 0,
                          child: IconButton.filled(
                            iconSize: 16,
                            icon: const Icon(Icons.close),
                            onPressed: () => setState(() => e.fotos.remove(f)),
                          ),
                        ),
                      ]),
                    if (e.fotos.length < 3)
                      OutlinedButton(
                        onPressed: _agregarFoto,
                        style: OutlinedButton.styleFrom(
                            fixedSize: const Size(90, 90)),
                        child: const Icon(Icons.add_a_photo),
                      ),
                  ]),
                  const SizedBox(height: 16),
                  _titulo('Menú'),
                  for (final p in e.platos)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(p.nombre),
                      subtitle: Text('${p.comida} · ${p.dieta}'),
                      leading: Text('Bs ${p.precio.toStringAsFixed(2)}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => setState(() => e.platos.remove(p)),
                      ),
                      onTap: () => _editarPlato(p),
                    ),
                  TextButton.icon(
                    onPressed: () => _editarPlato(),
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar plato'),
                  ),
                  const SizedBox(height: 24),
                  if (e.estado == 'rechazado' && !_esNuevo)
                    FilledButton(
                      onPressed: _guardando ? null : () => _guardar(reenviar: true),
                      child: const Text('Corregir y volver a enviar'),
                    )
                  else
                    FilledButton(
                      onPressed: _guardando || e.estado == 'suspendido'
                          ? null
                          : _guardar,
                      child: Text(_esNuevo ? 'Enviar para aprobación' : 'Guardar cambios'),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _titulo(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t, style: Theme.of(context).textTheme.titleMedium),
      );

  /// Cuadro que le dice al dueño en qué estado está su local.
  Widget _avisoEstado(Establecimiento e) {
    final (texto, color) = _esNuevo
        ? ('Llena los datos de tu local y envíalo para su aprobación.', Colors.blue)
        : switch (e.estado) {
            'aprobado' => ('Tu local está aprobado y visible en la app.', Colors.green),
            'rechazado' => ('Rechazado: ${e.motivo}', Colors.red),
            'suspendido' => ('Tu local está suspendido.', Colors.grey),
            _ => ('Pendiente: el administrador lo está revisando.', Colors.orange),
          };
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      color: color.withValues(alpha: 0.15),
      child: Text(texto),
    );
  }
}
