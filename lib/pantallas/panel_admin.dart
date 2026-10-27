// Panel del administrador (superadministrador):
//  - Pendientes: aprobar o rechazar locales nuevos.
//  - Aprobados / Suspendidos: suspender o reactivar locales.
//  - Propietarios: suspender o reactivar cuentas.
//  - Catálogos: editar las opciones de los filtros.
// Todo se guarda directamente en Firebase.

import 'package:flutter/material.dart';

import '../modelos.dart';
import '../servicios/firebase_servicio.dart';
import 'panel_propietario.dart';

class PanelAdmin extends StatelessWidget {
  const PanelAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Administración'),
          actions: [
            // Por si el administrador también es dueño de un local.
            IconButton(
              icon: const Icon(Icons.storefront),
              tooltip: 'Mi local',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PanelPropietario()),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Cerrar sesión',
              onPressed: () async {
                await cerrarSesion();
                if (context.mounted) Navigator.pop(context);
              },
            ),
          ],
          bottom: const TabBar(isScrollable: true, tabs: [
            Tab(text: 'Pendientes'),
            Tab(text: 'Aprobados'),
            Tab(text: 'Suspendidos'),
            Tab(text: 'Propietarios'),
            Tab(text: 'Catálogos'),
          ]),
        ),
        body: const TabBarView(children: [
          _ListaLocales(estado: 'pendiente'),
          _ListaLocales(estado: 'aprobado'),
          _ListaLocales(estado: 'suspendido'),
          _ListaPropietarios(),
          _EditorCatalogos(),
        ]),
      ),
    );
  }
}

// ------------------------------------------------------- LOCALES

class _ListaLocales extends StatefulWidget {
  const _ListaLocales({required this.estado});
  final String estado;

  @override
  State<_ListaLocales> createState() => _ListaLocalesState();
}

class _ListaLocalesState extends State<_ListaLocales> {
  List<Establecimiento>? _locales;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final lista = await establecimientosPorEstado(widget.estado);
    if (mounted) setState(() => _locales = lista);
  }

  Future<void> _cambiar(Establecimiento e, String nuevoEstado,
      {String motivo = ''}) async {
    try {
      await cambiarEstado(e.id, nuevoEstado, motivo: motivo);
      await _cargar();
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(mensajeError(err))));
      }
    }
  }

  /// Pide el motivo antes de rechazar o suspender un local.
  /// El dueño ve ese motivo en su panel ("Mi local").
  Future<void> _conMotivo(Establecimiento e, String nuevoEstado, String accion) async {
    final motivo = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$accion "${e.nombre}"'),
        content: TextField(
          controller: motivo,
          decoration: const InputDecoration(labelText: 'Motivo'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(context, motivo.text.trim().isNotEmpty),
              child: Text(accion)),
        ],
      ),
    );
    if (ok == true) _cambiar(e, nuevoEstado, motivo: motivo.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final locales = _locales;
    if (locales == null) return const Center(child: CircularProgressIndicator());
    if (locales.isEmpty) return const Center(child: Text('No hay locales aquí.'));
    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(children: [
        for (final e in locales)
          Card(
            margin: const EdgeInsets.all(8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.nombre, style: Theme.of(context).textTheme.titleMedium),
                  Text('${e.tipo} · ${e.direccion}'),
                  Text('${e.platos.length} platos · ${e.fotos.length} fotos'),
                  if (e.descripcion.isNotEmpty) Text(e.descripcion),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, children: [
                    if (widget.estado == 'pendiente') ...[
                      FilledButton(
                          onPressed: () => _cambiar(e, 'aprobado'),
                          child: const Text('Aprobar')),
                      OutlinedButton(
                          onPressed: () => _conMotivo(e, 'rechazado', 'Rechazar'),
                          child: const Text('Rechazar')),
                    ],
                    if (widget.estado == 'aprobado')
                      OutlinedButton(
                          onPressed: () => _conMotivo(e, 'suspendido', 'Suspender'),
                          child: const Text('Suspender')),
                    if (widget.estado == 'suspendido') ...[
                      if (e.motivo.isNotEmpty) Text('Motivo: ${e.motivo}'),
                      FilledButton(
                          onPressed: () => _cambiar(e, 'aprobado'), // borra el motivo
                          child: const Text('Reactivar')),
                    ],
                  ]),
                ],
              ),
            ),
          ),
      ]),
    );
  }
}

// ------------------------------------------------------- PROPIETARIOS

class _ListaPropietarios extends StatefulWidget {
  const _ListaPropietarios();

  @override
  State<_ListaPropietarios> createState() => _ListaPropietariosState();
}

class _ListaPropietariosState extends State<_ListaPropietarios> {
  List<Map<String, dynamic>>? _cuentas;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final lista = await propietarios();
    if (mounted) setState(() => _cuentas = lista);
  }

  @override
  Widget build(BuildContext context) {
    final cuentas = _cuentas;
    if (cuentas == null) return const Center(child: CircularProgressIndicator());
    if (cuentas.isEmpty) return const Center(child: Text('No hay propietarios.'));
    return ListView(children: [
      for (final c in cuentas)
        SwitchListTile(
          title: Text(c['nombre'] ?? ''),
          subtitle: Text('${c['correo']}\n'
              '${c['activo'] == true ? 'Cuenta activa' : 'Cuenta suspendida'}'),
          isThreeLine: true,
          value: c['activo'] == true,
          onChanged: (activo) async {
            await cambiarCuenta(c['uid'], activo);
            _cargar();
          },
        ),
    ]);
  }
}

// ------------------------------------------------------- CATÁLOGOS

class _EditorCatalogos extends StatefulWidget {
  const _EditorCatalogos();

  @override
  State<_EditorCatalogos> createState() => _EditorCatalogosState();
}

class _EditorCatalogosState extends State<_EditorCatalogos> {
  Catalogos? _c;

  @override
  void initState() {
    super.initState();
    leerCatalogos().then((c) => setState(() => _c = c));
  }

  Future<void> _guardar() async {
    await guardarCatalogos(_c!);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Catálogos guardados.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _c;
    if (c == null) return const Center(child: CircularProgressIndicator());
    return ListView(padding: const EdgeInsets.all(16), children: [
      _grupo('Tipos de local', c.tipos),
      _grupo('Tipos de comida', c.comidas),
      _grupo('Dietas', c.dietas),
      const SizedBox(height: 16),
      FilledButton(onPressed: _guardar, child: const Text('Guardar catálogos')),
    ]);
  }

  /// Una lista editable: chips con X para quitar y un campo para agregar.
  Widget _grupo(String titulo, List<String> lista) {
    final nuevo = TextEditingController();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 12),
      Text(titulo, style: Theme.of(context).textTheme.titleMedium),
      Wrap(spacing: 6, children: [
        for (final item in lista)
          Chip(
            label: Text(item),
            onDeleted: () => setState(() => lista.remove(item)),
          ),
      ]),
      Row(children: [
        Expanded(
          child: TextField(
            controller: nuevo,
            decoration: const InputDecoration(hintText: 'Agregar opción'),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () {
            final t = nuevo.text.trim();
            if (t.isNotEmpty && !lista.contains(t)) {
              setState(() => lista.add(t));
            }
          },
        ),
      ]),
    ]);
  }
}
