// Hoja de filtros: tipo de local, tipo de comida, precio y dieta.
// Las opciones salen de los catálogos guardados en SQLite.

import 'package:flutter/material.dart';

import '../modelos.dart';
import '../servicios/base_local.dart';

/// Filtros elegidos. null = "Todos".
class Filtros {
  Filtros({this.tipo, this.comida, this.precio, this.dieta});

  String? tipo;
  String? comida;
  int? precio;
  String? dieta;

  int get activos =>
      [tipo, comida, precio, dieta].where((f) => f != null).length;
}

/// Muestra la hoja y devuelve los filtros elegidos (o null si se cerró).
Future<Filtros?> mostrarFiltros(BuildContext context, Filtros actuales) async {
  final tipos = await BaseLocal.catalogo('tipo');
  final comidas = await BaseLocal.catalogo('comida');
  final dietas = await BaseLocal.catalogo('dieta');
  if (!context.mounted) return null;

  final f = Filtros(
    tipo: actuales.tipo,
    comida: actuales.comida,
    precio: actuales.precio,
    dieta: actuales.dieta,
  );

  return showModalBottomSheet<Filtros>(
    context: context,
    isScrollControlled: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Filtros', style: Theme.of(context).textTheme.titleLarge),
            _lista('Tipo de local', tipos, f.tipo,
                (v) => setState(() => f.tipo = v)),
            _lista('Tipo de comida', comidas, f.comida,
                (v) => setState(() => f.comida = v)),
            DropdownButtonFormField<int?>(
              initialValue: f.precio,
              decoration: const InputDecoration(labelText: 'Precio'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Todos')),
                for (final p in nombresPrecio.entries)
                  DropdownMenuItem(value: p.key, child: Text(p.value)),
              ],
              onChanged: (v) => setState(() => f.precio = v),
            ),
            _lista('Dieta', dietas.where((d) => d != 'Ninguna').toList(),
                f.dieta, (v) => setState(() => f.dieta = v)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, Filtros()),
                    child: const Text('Limpiar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, f),
                    child: const Text('Aplicar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _lista(String titulo, List<String> opciones, String? valor,
    ValueChanged<String?> alCambiar) {
  return DropdownButtonFormField<String?>(
    initialValue: opciones.contains(valor) ? valor : null,
    decoration: InputDecoration(labelText: titulo),
    items: [
      const DropdownMenuItem(value: null, child: Text('Todos')),
      for (final o in opciones) DropdownMenuItem(value: o, child: Text(o)),
    ],
    onChanged: alCambiar,
  );
}
