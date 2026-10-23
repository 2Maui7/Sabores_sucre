// Inicio de sesión para propietarios y el administrador.
// Los visitantes no necesitan cuenta.

import 'package:flutter/material.dart';

import '../servicios/firebase_servicio.dart';
import 'registro.dart';

class LoginPantalla extends StatefulWidget {
  const LoginPantalla({super.key});

  @override
  State<LoginPantalla> createState() => _LoginPantallaState();
}

class _LoginPantallaState extends State<LoginPantalla> {
  final _correo = TextEditingController();
  final _clave = TextEditingController();
  bool _cargando = false;

  void _mensaje(String texto) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));

  Future<void> _ingresar() async {
    setState(() => _cargando = true);
    try {
      final rol = await iniciarSesion(_correo.text, _clave.text);
      // Vuelve al inicio con el rol; el inicio abre el panel que corresponde.
      if (mounted) Navigator.pop(context, rol);
    } catch (e) {
      _mensaje(mensajeError(e));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _olvideClave() async {
    if (_correo.text.trim().isEmpty) {
      _mensaje('Escribe tu correo primero.');
      return;
    }
    try {
      await recuperarClave(_correo.text);
      _mensaje('Te enviamos un correo para cambiar tu contraseña.');
    } catch (e) {
      _mensaje(mensajeError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar sesión')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(
            controller: _correo,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Correo'),
          ),
          TextField(
            controller: _clave,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Contraseña'),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _cargando ? null : _ingresar,
            child: Text(_cargando ? 'Ingresando...' : 'Ingresar'),
          ),
          TextButton(
            onPressed: _olvideClave,
            child: const Text('¿Olvidaste tu contraseña?'),
          ),
          const Divider(height: 32),
          const Text('¿Tienes un local de comida?', textAlign: TextAlign.center),
          TextButton(
            onPressed: () async {
              // Si se registra, vuelve con el rol 'propietario'.
              final rol = await Navigator.push<String>(context,
                  MaterialPageRoute(builder: (_) => const RegistroPantalla()));
              if (rol != null && context.mounted) Navigator.pop(context, rol);
            },
            child: const Text('Crear cuenta de propietario'),
          ),
        ],
      ),
    );
  }
}
