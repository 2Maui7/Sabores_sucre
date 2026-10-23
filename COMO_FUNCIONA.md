# Cómo funciona Sabores de Sucre

## La idea en una frase

**Firebase es el original y SQLite es una fotocopia que vive en cada teléfono.**
Los propietarios y el administrador escriben en Firebase. Cada vez que el visitante abre la app, se saca una fotocopia nueva de los locales aprobados y se guarda en SQLite. Las pantallas del visitante leen siempre de esa fotocopia, por eso la app funciona sin internet.

```
  PROPIETARIO  ──escribe su local──►  ┌────────────────────┐
  ADMIN ──aprueba / suspende──────►   │  FIREBASE (nube)   │
                                      │  Authentication    │
                                      │  Firestore         │
                                      └─────────┬──────────┘
                                                │ al abrir la app o deslizar hacia abajo:
                                                │ "dame todos los locales aprobados"
                                                ▼
  VISITANTE ◄──lee, busca y filtra──  ┌────────────────────┐
                                      │  SQLite (teléfono) │
                                      │  4 tablas          │
                                      └────────────────────┘
```

## Las dos bases de datos

### Firebase (en la nube)
| Parte | Para qué sirve |
|---|---|
| **Authentication** | Las cuentas de propietarios y del admin, con correo y contraseña. El visitante no necesita cuenta. |
| **Firestore**: `usuarios/{uid}` | Ficha de cada cuenta: nombre, correo, `rol` (propietario o admin) y `activo`. |
| **Firestore**: `establecimientos/{uid}` | El local de cada propietario: datos, `estado`, `platos` y `fotos`, todo junto en un documento. El id del documento es el id del dueño, porque cada dueño tiene un solo local. |
| **Firestore**: `catalogos/general` | Las opciones de los filtros: tipos de local, tipos de comida y dietas. |

Las fotos se achican (unos 100 KB) y se guardan **como texto** dentro del documento del local. Así no hace falta otro servicio y todo se maneja con el plan gratuito de Firebase.

### SQLite (en el teléfono)
| Tabla | Contenido |
|---|---|
| `establecimientos` | Locales aprobados (nombre, tipo, dirección, horario, precio). |
| `platos` | El menú de cada local (`establecimiento_id`, nombre, precio, comida, dieta). |
| `fotos` | Las fotos de cada local. |
| `catalogos` | Las opciones de los filtros (`grupo` = tipo, comida o dieta). |

## Los tres recorridos

### 1. Visitante (sin cuenta)
1. Abre la app → `inicio.dart` llama a `sincronizar()` (`sincronizacion.dart`).
2. `sincronizar()`:
   - pide a Firebase los locales aprobados y los catálogos (`firebase_servicio.dart`);
   - borra la copia vieja de SQLite y guarda la nueva, todo en una sola transacción (`base_local.dart` → `guardarCopia`).
   - Si no hay internet, no toca nada y aparece "Sin conexión: mostrando los datos guardados".
3. La lista, el buscador y los filtros son **consultas SQL** sobre SQLite (`BaseLocal.listar`).
4. Al tocar un local se abre `detalle.dart`, que también lee de SQLite. "Cómo llegar" abre Google Maps con la dirección.

### 2. Propietario
1. Se registra en `registro.dart`. Se crea su cuenta en Authentication y su ficha en `usuarios`, con rol `propietario`.
2. En `panel_propietario.dart` llena los datos de su local, el menú y hasta 3 fotos.
3. Al enviarlo, el local se guarda en Firebase con estado **pendiente**. Todavía no aparece para los visitantes.
4. Si el admin lo rechaza, ve el motivo, corrige y lo vuelve a enviar.

### 3. Administrador
1. Inicia sesión y se abre `panel_admin.dart`.
2. **Pendientes**: aprueba o rechaza. Al aprobar, el local aparece en la app de todos en su siguiente sincronización.
3. **Aprobados / Suspendidos**: suspende o reactiva locales. Un local suspendido desaparece de los teléfonos en su siguiente sincronización, porque ya no está en la fotocopia.
4. **Propietarios**: suspende o reactiva cuentas. Suspender una cuenta también suspende su local.
5. **Catálogos**: agrega o quita opciones de los filtros.

## Ubicación del local
Cada local guarda su **latitud y longitud** (el punto exacto en el mapa), además de la dirección escrita.
- **El propietario la marca** en "Mi local" → "Ubicación en el mapa", de dos maneras:
  1. **"Usar mi ubicación actual"**: estando en su local, el GPS del teléfono la toma sola (`servicios/ubicacion.dart`).
  2. **"Elegir en el mapa"**: toca el lugar en un mapa de OpenStreetMap, que es gratis y no necesita clave (`pantallas/mapa.dart`).
- Las coordenadas se guardan en Firebase dentro del documento del local, y en SQLite en las columnas `latitud` y `longitud`.
- **El visitante** ve un mapa pequeño en el detalle. **"Cómo llegar"** abre Google Maps con la ruta desde donde está hasta ese punto exacto.
- Los mapas necesitan internet para dibujar las calles. Sin conexión, el resto del detalle se sigue viendo.

## La seguridad (`firestore.rules`)
Las reglas se revisan **en el servidor de Firebase**, así que nadie puede saltárselas aunque modifique la app:
- Cualquiera puede leer los locales **aprobados** y los catálogos.
- Un propietario solo puede crear y editar **su propio** local, y **no puede cambiar su estado**: no puede aprobarse a sí mismo.
- Nadie puede registrarse como admin.
- Solo el admin cambia estados, suspende cuentas y edita catálogos.

## Mapa de archivos
| Archivo | Qué hace |
|---|---|
| `lib/main.dart` | Conecta la app con Firebase y abre la pantalla de inicio. |
| `lib/modelos.dart` | Las clases `Establecimiento`, `Plato` y `Catalogos`. |
| `lib/servicios/firebase_servicio.dart` | **Todo** lo que se hace con Firebase. |
| `lib/servicios/base_local.dart` | **Todo** lo que se hace con SQLite. |
| `lib/servicios/sincronizacion.dart` | La "fotocopia": de Firebase a SQLite. |
| `lib/servicios/ubicacion.dart` | El GPS: obtener la ubicación actual. |
| `lib/pantallas/mapa.dart` | Los mapas: el pequeño del detalle y el de elegir ubicación. |
| `lib/pantallas/*.dart` | Las pantallas: inicio, detalle, filtros, login, registro, panel del propietario y panel del admin. |
| `firestore.rules` | Las reglas de seguridad. |

## Tareas de configuración

**Crear el administrador.** Por seguridad, nadie puede registrarse como admin desde la app:
1. Regístrate en la app como si fueras propietario.
2. En la [consola de Firebase](https://console.firebase.google.com/project/sabores-sucre/firestore), abre `usuarios` → tu documento → cambia `rol` de `propietario` a `admin`.
3. Cierra sesión y vuelve a entrar: se abre el panel de administración.

**Ver la base SQLite en DBeaver.** Con el emulador encendido, haz doble clic en `tool\copiar_bd.bat`. Se crea `sabores_sucre.db` en esta carpeta. En DBeaver, crea una conexión SQLite que apunte a ese archivo; para ver el diagrama, haz clic derecho → Ver diagrama.

**Volver a publicar las reglas** después de cambiarlas:
```
firebase deploy --only firestore:rules
```

## Preguntas típicas de la defensa
- **¿Por qué dos bases de datos?** Firebase es la fuente compartida: todos escriben ahí y las reglas la protegen. SQLite es la copia de cada teléfono, que hace la app rápida y le permite funcionar sin señal.
- **¿Por qué se copia todo cada vez?** Para un piloto de decenas de locales es rápido y es lo más simple y seguro: lo que desaparece de Firebase (suspendido) desaparece también del teléfono.
- **¿Cómo se evita que un dueño se apruebe solo?** Con las reglas de Firestore, que se revisan en el servidor.
