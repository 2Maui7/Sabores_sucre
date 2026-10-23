// Pantalla principal del visitante: lista, búsqueda y filtros.
// Todo lo que muestra sale de SQLite (la copia local).

import 'dart:convert';

import 'package:flutter/material.dart';

import '../modelos.dart';
import '../servicios/base_local.dart';
import '../servicios/firebase_servicio.dart';
import '../servicios/sincronizacion.dart';
import 'detalle.dart';
import 'filtros.dart';
import 'login.dart';
import 'panel_admin.dart';
import 'panel_propietario.dart';

class InicioPantalla extends StatefulWidget {
  const InicioPantalla({super.key});

  @override
  State<InicioPantalla> createState() => _InicioPantallaState();
}

class _InicioPantallaState extends State<InicioPantalla> {
  List<Map<String, dynamic>> _locales = [];
  String _texto = '';
  Filtros _filtros = Filtros();
  bool _sinConexion = false;

  @override
  void initState() {
    super.initState();
    _actualizar();
  }

  /// Sincroniza con Firebase y vuelve a leer la lista desde SQLite.
  Future<void> _actualizar() async {
    final ok = await sincronizar();
    _sinConexion = !ok;
    await _cargar();
  }

  /// Lee la lista desde SQLite con la búsqueda y los filtros actuales.
  Future<void> _cargar() async {
    final lista = await BaseLocal.listar(
      texto: _texto,
      tipo: _filtros.tipo,
      comida: _filtros.comida,
      precio: _filtros.precio,
      dieta: _filtros.dieta,
    );
    if (mounted) setState(() => _locales = lista);
  }

  Future<void> _abrirFiltros() async {
    final nuevos = await mostrarFiltros(context, _filtros);
    if (nuevos != null) {
      _filtros = nuevos;
      _cargar();
    }
  }

  /// Ícono de cuenta: si no hay sesión, primero pide el login;
  /// después abre el panel según el rol (admin o propietario).
  Future<void> _abrirCuenta() async {
    String? rol;
    if (usuarioActual == null) {
      // El login devuelve el rol, o null si el usuario volvió atrás.
      rol = await Navigator.push<String>(
          context, MaterialPageRoute(builder: (_) => const LoginPantalla()));
    } else {
      rol = (await leerPerfil())?['rol'];
    }
    if (rol == null || !mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            rol == 'admin' ? const PanelAdmin() : const PanelPropietario(),
      ),
    );
    _actualizar(); // al volver del panel, sincronizar por si algo cambió
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sabores de Sucre'),
        actions: [
          IconButton(icon: const Icon(Icons.account_circle), onPressed: _abrirCuenta),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Buscar local o plato',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (t) {
                      _texto = t;
                      _cargar();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  icon: Badge(
                    isLabelVisible: _filtros.activos > 0,
                    label: Text('${_filtros.activos}'),
                    child: const Icon(Icons.tune),
                  ),
                  onPressed: _abrirFiltros,
                ),
              ],
            ),
          ),
          if (_sinConexion)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(8),
              color: Colors.amber.shade100,
              child: const Text('Sin conexión: mostrando los datos guardados',
                  textAlign: TextAlign.center),
            ),
          Expanded(
            // Deslizar hacia abajo = sincronizar de nuevo.
            child: RefreshIndicator(
              onRefresh: _actualizar,
              child: _locales.isEmpty
                  ? ListView(children: const [
                      Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('No hay locales para mostrar.',
                            textAlign: TextAlign.center),
                      )
                    ])
                  : ListView.builder(
                      itemCount: _locales.length,
                      itemBuilder: (_, i) => _tarjeta(_locales[i]),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tarjeta(Map<String, dynamic> local) {
    final portada = local['portada'] as String?;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.all(8),
        leading: SizedBox(
          width: 72,
          height: 72,
          child: portada != null
              ? Image.memory(base64Decode(portada), fit: BoxFit.cover)
              : const Icon(Icons.restaurant, size: 40),
        ),
        title: Text(local['nombre']),
        subtitle: Text('${local['tipo']} · ${nombresPrecio[local['precio']]}\n'
            '${local['direccion']}'),
        isThreeLine: true,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DetallePantalla(id: local['id'])),
        ),
      ),
    );
  }
}
