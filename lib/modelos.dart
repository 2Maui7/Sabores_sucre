// Los datos con los que trabaja la app.
//
// Un establecimiento tiene sus platos y sus fotos dentro de sí mismo.
// Así se guarda en Firebase: un solo documento por local.

/// Un plato del menú.
class Plato {
  Plato({
    required this.nombre,
    required this.precio,
    required this.comida,
    required this.dieta,
  });

  String nombre;
  double precio; // en bolivianos
  String comida; // tipo de comida: "Plato fuerte", "Sopa", ...
  String dieta; // "Ninguna", "Vegetariana", ...

  /// Convierte un mapa (como viene de Firebase o SQLite) en un Plato.
  factory Plato.desdeMapa(Map<String, dynamic> m) => Plato(
        nombre: m['nombre'] ?? '',
        precio: (m['precio'] as num? ?? 0).toDouble(),
        comida: m['comida'] ?? '',
        dieta: m['dieta'] ?? 'Ninguna',
      );

  /// Convierte el Plato en un mapa para guardarlo.
  Map<String, dynamic> aMapa() => {
        'nombre': nombre,
        'precio': precio,
        'comida': comida,
        'dieta': dieta,
      };
}

/// Un local de comida (restaurante, pensión, salteñería, ...).
/// Su id es el mismo id del propietario: cada dueño tiene un solo local.
class Establecimiento {
  Establecimiento({
    required this.id,
    this.nombre = '',
    this.tipo = '',
    this.descripcion = '',
    this.direccion = '',
    this.horario = '',
    this.precio = 1,
    this.estado = 'pendiente',
    this.motivo = '',
    List<String>? fotos,
    List<Plato>? platos,
  })  : fotos = fotos ?? [],
        platos = platos ?? [];

  String id;
  String nombre;
  String tipo;
  String descripcion;
  String direccion;
  String horario;
  int precio; // 1 = económico, 2 = medio, 3 = alto

  /// pendiente, aprobado, rechazado o suspendido. Solo el admin lo cambia.
  String estado;
  String motivo; // por qué se rechazó (si fue rechazado)

  /// Fotos guardadas como texto (base64). Máximo 3.
  List<String> fotos;
  List<Plato> platos;

  factory Establecimiento.desdeMapa(String id, Map<String, dynamic> m) =>
      Establecimiento(
        id: id,
        nombre: m['nombre'] ?? '',
        tipo: m['tipo'] ?? '',
        descripcion: m['descripcion'] ?? '',
        direccion: m['direccion'] ?? '',
        horario: m['horario'] ?? '',
        precio: (m['precio'] as num? ?? 1).toInt(),
        estado: m['estado'] ?? 'pendiente',
        motivo: m['motivo'] ?? '',
        fotos: List<String>.from(m['fotos'] ?? []),
        platos: [
          for (final p in (m['platos'] as List? ?? []))
            Plato.desdeMapa(Map<String, dynamic>.from(p))
        ],
      );

  /// Datos que escribe el propietario. No incluye `estado` ni `motivo`,
  /// porque eso lo decide el administrador.
  Map<String, dynamic> aMapa() => {
        'nombre': nombre,
        'tipo': tipo,
        'descripcion': descripcion,
        'direccion': direccion,
        'horario': horario,
        'precio': precio,
        'fotos': fotos,
        'platos': [for (final p in platos) p.aMapa()],
      };
}

/// Las opciones de los filtros. El administrador puede editarlas.
class Catalogos {
  Catalogos({required this.tipos, required this.comidas, required this.dietas});

  List<String> tipos;
  List<String> comidas;
  List<String> dietas;

  /// Valores de inicio, por si el administrador todavía no guardó ninguno.
  factory Catalogos.porDefecto() => Catalogos(
        tipos: ['Restaurante', 'Pensión', 'Salteñería', 'Chichería',
          'Cafetería', 'Puesto de mercado'],
        comidas: ['Plato fuerte', 'Sopa', 'Entrada o snack', 'Bebida', 'Postre'],
        dietas: ['Ninguna', 'Vegetariana', 'Vegana', 'Sin gluten'],
      );

  factory Catalogos.desdeMapa(Map<String, dynamic> m) => Catalogos(
        tipos: List<String>.from(m['tipos'] ?? []),
        comidas: List<String>.from(m['comidas'] ?? []),
        dietas: List<String>.from(m['dietas'] ?? []),
      );

  Map<String, dynamic> aMapa() =>
      {'tipos': tipos, 'comidas': comidas, 'dietas': dietas};
}

/// Texto que se muestra para el rango de precio.
const nombresPrecio = {1: 'Económico', 2: 'Medio', 3: 'Alto'};
