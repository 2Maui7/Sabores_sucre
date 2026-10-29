// Portal web de Sabores de Sucre (https://sabores-sucre.web.app).
// Promociona la app: permite descargarla (Android), explica cómo usarla y
// deja que el dueño cree su cuenta y envíe su local desde una computadora.
// Usa los mismos paneles que la app móvil; la consulta para visitantes queda
// solo en el celular (funciona sin internet).

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../servicios/firebase_servicio.dart';
import 'login.dart';
import 'panel_admin.dart';
import 'panel_propietario.dart';
import 'registro.dart';

class PortalWebPantalla extends StatelessWidget {
  const PortalWebPantalla({super.key});

  /// Abre el registro o el login; si vuelve con un rol, abre su panel.
  Future<void> _entrar(BuildContext context, Widget pantalla) async {
    final rol = await Navigator.push<String>(
        context, MaterialPageRoute(builder: (_) => pantalla));
    if (rol == null || !context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            rol == 'admin' ? const PanelAdmin() : const PanelPropietario(),
      ),
    );
  }

  /// Descarga el APK de la última versión publicada en GitHub Releases
  /// (Firebase Hosting no admite ejecutables en el plan gratuito).
  void _descargarApk() {
    launchUrl(Uri.parse(
        'https://github.com/2Maui7/sabores-sucre-descargas/releases/latest/download/sabores_sucre.apk'));
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.restaurant_menu,
                        size: 64, color: tema.colorScheme.primary),
                    const SizedBox(height: 16),
                    Text('Sabores de Sucre',
                        textAlign: TextAlign.center,
                        style: tema.textTheme.headlineMedium),
                    const SizedBox(height: 8),
                    Text('Comida tradicional de Sucre en tu celular',
                        textAlign: TextAlign.center,
                        style: tema.textTheme.titleMedium),
                    const SizedBox(height: 16),
                    const Text(
                      'Encuentra dónde comer platos típicos en Sucre: menús, '
                      'precios, horarios, fotos y cómo llegar. Y si tienes un '
                      'local, publícalo gratis.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      icon: const Icon(Icons.download),
                      label: const Text('Descargar la app (Android)'),
                      onPressed: _descargarApk,
                    ),

                    // ---------- Descarga ----------
                    const _Titulo('Descarga la app (Android)'),
                    const Text(
                      'La app se instala desde un archivo (APK), sin pasar por '
                      'la tienda. Hazlo desde el celular:',
                    ),
                    const _Paso(numero: 1, texto: 'Toca "Descargar la app" y espera a que termine la descarga.'),
                    const _Paso(numero: 2, texto: 'Abre el archivo descargado (sabores_sucre.apk) desde las notificaciones o la carpeta Descargas.'),
                    const _Paso(numero: 3, texto: 'Si el celular lo pide, permite "instalar apps de orígenes desconocidos" para tu navegador o gestor de archivos.'),
                    const _Paso(numero: 4, texto: 'Toca "Instalar" y luego "Abrir".'),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.android),
                      label: const Text('Descargar sabores_sucre.apk'),
                      onPressed: _descargarApk,
                    ),

                    // ---------- Guía de uso ----------
                    const _Titulo('Cómo usar la app'),
                    const _Bloque(
                      icono: Icons.travel_explore,
                      titulo: 'Si buscas dónde comer',
                      puntos: [
                        'Al abrir la app ves el listado de locales aprobados.',
                        'Escribe en el buscador el nombre de un plato o de un local.',
                        'Usa los filtros para elegir por tipo de local, comida, precio o dieta.',
                        'Toca un local para ver su menú, fotos, horarios y el mapa; con "Cómo llegar" abres la ruta.',
                        'Funciona sin internet con lo último que se descargó. Desliza hacia abajo el listado para actualizar.',
                      ],
                    ),
                    const SizedBox(height: 12),
                    const _Bloque(
                      icono: Icons.storefront,
                      titulo: 'Si tienes un local',
                      puntos: [
                        'Crea tu cuenta de propietario.',
                        'En "Mi local" llena los datos, marca la ubicación con el GPS o en el mapa, arma tu menú y sube hasta 3 fotos.',
                        'Envía la solicitud y espera la aprobación del administrador.',
                        'Si la rechazan o suspenden tu local, verás el motivo: corrige lo indicado y vuelve a enviarla.',
                      ],
                    ),

                    // ---------- Propietarios desde la web ----------
                    const _Titulo('Portal para propietarios'),
                    const Text(
                      '¿Tienes un local de comida tradicional en Sucre? Publica gratis tu '
                      'menú, horarios, fotos y ubicación. Un administrador revisa tu '
                      'solicitud y, cuando la aprueba, tu local aparece en la aplicación '
                      'Sabores de Sucre para vecinos y turistas. También puedes hacerlo '
                      'desde aquí, en la computadora.',
                    ),
                    const SizedBox(height: 8),
                    const _Paso(numero: 1, texto: 'Crea tu cuenta de propietario.'),
                    const _Paso(numero: 2, texto: 'Llena los datos de tu local, tu menú y marca la ubicación.'),
                    const _Paso(numero: 3, texto: 'Envía la solicitud y espera la aprobación.'),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      icon: const Icon(Icons.storefront),
                      label: const Text('Solicitar el alta de mi local'),
                      onPressed: () => _entrar(context, const RegistroPantalla()),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      child: const Text('Ya tengo cuenta'),
                      onPressed: () async {
                        // Si ya hay sesión abierta, va directo a su panel.
                        final perfil = await leerPerfil();
                        if (!context.mounted) return;
                        if (perfil == null) {
                          await _entrar(context, const LoginPantalla());
                        } else {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => perfil['rol'] == 'admin'
                                  ? const PanelAdmin()
                                  : const PanelPropietario(),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Titulo extends StatelessWidget {
  const _Titulo(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 32, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Divider(),
          const SizedBox(height: 16),
          Text(texto,
              style: tema.textTheme.titleLarge
                  ?.copyWith(color: tema.colorScheme.primary)),
        ],
      ),
    );
  }
}

class _Paso extends StatelessWidget {
  const _Paso({required this.numero, required this.texto});

  final int numero;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(child: Text('$numero')),
      title: Text(texto),
    );
  }
}

/// Tarjeta con un título y una lista corta de indicaciones.
class _Bloque extends StatelessWidget {
  const _Bloque(
      {required this.icono, required this.titulo, required this.puntos});

  final IconData icono;
  final String titulo;
  final List<String> puntos;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icono, color: tema.colorScheme.primary),
                const SizedBox(width: 8),
                Text(titulo, style: tema.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 8),
            for (final p in puntos)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('•  '),
                    Expanded(child: Text(p)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
