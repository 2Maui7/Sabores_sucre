// Registro de un nuevo propietario.

import 'package:flutter/material.dart';

import '../servicios/firebase_servicio.dart';

class RegistroPantalla extends StatefulWidget {
  const RegistroPantalla({super.key});

  @override
  State<RegistroPantalla> createState() => _RegistroPantallaState();
}

class _RegistroPantallaState extends State<RegistroPantalla> {
  final _nombre = TextEditingController();
  final _correo = TextEditingController();
  final _clave = TextEditingController();
  bool _cargando = false;

  Future<void> _registrar() async {
    if (_nombre.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Escribe tu nombre.')));
      return;
    }
    setState(() => _cargando = true);
    try {
      await registrar(_nombre.text, _correo.text, _clave.text);
      // Vuelve con el rol; el inicio abre el panel del propietario.
      if (mounted) Navigator.pop(context, 'propietario');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(mensajeError(e))));
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta de propietario')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(
            controller: _nombre,
            decoration: const InputDecoration(labelText: 'Tu nombre'),
          ),
          TextField(
            controller: _correo,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Correo'),
          ),
          TextField(
            controller: _clave,
            obscureText: true,
            decoration: const InputDecoration(
                labelText: 'Contraseña', helperText: 'Mínimo 6 caracteres'),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _cargando ? null : _registrar,
            child: Text(_cargando ? 'Creando...' : 'Crear cuenta'),
          ),
        ],
      ),
    );
  }
}
