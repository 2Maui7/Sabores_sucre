// Portal web para propietarios (https://sabores-sucre.web.app).
// Desde una computadora, el dueño crea su cuenta y envía su local para que
// el administrador lo apruebe. Usa los mismos paneles que la app móvil;
// la consulta para visitantes queda solo en el celular (funciona sin internet).

import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(24),
            children: [
              Icon(Icons.restaurant_menu, size: 64, color: tema.colorScheme.primary),
              const SizedBox(height: 16),
              Text('Sabores de Sucre',
                  textAlign: TextAlign.center, style: tema.textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text('Portal para propietarios',
                  textAlign: TextAlign.center, style: tema.textTheme.titleMedium),
              const SizedBox(height: 24),
              const Text(
                '¿Tienes un local de comida tradicional en Sucre? Publica gratis tu '
                'menú, horarios, fotos y ubicación. Un administrador revisa tu '
                'solicitud y, cuando la aprueba, tu local aparece en la aplicación '
                'Sabores de Sucre para vecinos y turistas.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              const _Paso(numero: 1, texto: 'Crea tu cuenta de propietario.'),
              const _Paso(numero: 2, texto: 'Llena los datos de tu local, tu menú y marca la ubicación.'),
              const _Paso(numero: 3, texto: 'Envía la solicitud y espera la aprobación.'),
              const SizedBox(height: 24),
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
