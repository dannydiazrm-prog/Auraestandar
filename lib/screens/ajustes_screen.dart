import '../widgets/responsive.dart';
import "../widgets/page_header.dart";
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';

class AjustesScreen extends StatefulWidget {
  const AjustesScreen({super.key});

  @override
  State<AjustesScreen> createState() => _AjustesScreenState();
}

class _AjustesScreenState extends State<AjustesScreen> {
  final FirestoreService _service = FirestoreService();
  final _formKey = GlobalKey<FormState>();

  final _nombreEmpresaCtrl = TextEditingController();
  final _rucCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _timbradoCtrl = TextEditingController();
  final _nroFacturaCtrl = TextEditingController();
  final _passActualCtrl = TextEditingController();
  final _passNuevaCtrl = TextEditingController();
  final _passConfirmarCtrl = TextEditingController();

  DateTime? _vencimientoTimbrado;
  bool _cargando = false;
  bool _guardando = false;
  bool _verPassActual = false;
  bool _verPassNueva = false;
  bool _verPassConfirmar = false;

  @override
  void initState() {
    super.initState();
    _cargarAjustes();
  }

  @override
  void dispose() {
    _nombreEmpresaCtrl.dispose();
    _rucCtrl.dispose();
    _direccionCtrl.dispose();
    _telefonoCtrl.dispose();
    _correoCtrl.dispose();
    _timbradoCtrl.dispose();
    _nroFacturaCtrl.dispose();
    _passActualCtrl.dispose();
    _passNuevaCtrl.dispose();
    _passConfirmarCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarAjustes() async {
    setState(() => _cargando = true);
    final data = await _service.getAjustes();
    setState(() {
      _nombreEmpresaCtrl.text = data['nombreEmpresa'] ?? '';
      _rucCtrl.text = data['ruc'] ?? '';
      _direccionCtrl.text = data['direccion'] ?? '';
      _telefonoCtrl.text = data['telefono'] ?? '';
      _correoCtrl.text = data['correo'] ?? '';
      _timbradoCtrl.text = data['timbrado'] ?? '';
      _nroFacturaCtrl.text = data['nroFactura'] ?? '';
      if (data['vencimientoTimbrado'] != null) {
        _vencimientoTimbrado = DateTime.parse(data['vencimientoTimbrado']);
      }
      _cargando = false;
    });
  }

  Future<void> _guardarAjustes() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    await _service.guardarAjustes({
      'nombreEmpresa': _nombreEmpresaCtrl.text.trim(),
      'ruc': _rucCtrl.text.trim(),
      'direccion': _direccionCtrl.text.trim(),
      'telefono': _telefonoCtrl.text.trim(),
      'correo': _correoCtrl.text.trim(),
      'timbrado': _timbradoCtrl.text.trim(),
      'nroFactura': _nroFacturaCtrl.text.trim(),
      'vencimientoTimbrado': _vencimientoTimbrado?.toIso8601String(),
    });
    setState(() => _guardando = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ajustes guardados correctamente'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _cambiarContrasena() async {
    if (_passNuevaCtrl.text != _passConfirmarCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Las contraseñas no coinciden'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_passNuevaCtrl.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La contraseña debe tener al menos 6 caracteres'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _passActualCtrl.text,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(_passNuevaCtrl.text);

      _passActualCtrl.clear();
      _passNuevaCtrl.clear();
      _passConfirmarCtrl.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contraseña actualizada correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contraseña actual incorrecta'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (fecha != null) {
      setState(() => _vencimientoTimbrado = fecha);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: Responsive.pagePadding(context),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                        pageHeader('AJUSTES', context),


            // Datos del negocio
            _seccion(
              titulo: 'Datos del Negocio',
              icono: Icons.business,
              children: [
                _campo(
                  controller: _nombreEmpresaCtrl,
                  label: 'Nombre de la empresa *',
                  icono: Icons.store,
                  maxLength: 50,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'El nombre es obligatorio';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _campo(
                  controller: _rucCtrl,
                  label: 'RUC',
                  icono: Icons.fingerprint,
                  maxLength: 20,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]')),
                  ],
                ),
                const SizedBox(height: 16),
                _campo(
                  controller: _direccionCtrl,
                  label: 'Dirección',
                  icono: Icons.location_on,
                  maxLength: 100,
                ),
                const SizedBox(height: 16),
                _campo(
                  controller: _telefonoCtrl,
                  label: 'Teléfono',
                  icono: Icons.phone,
                  maxLength: 20,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 16),
                _campo(
                  controller: _correoCtrl,
                  label: 'Correo del negocio',
                  icono: Icons.email,
                  maxLength: 50,
                  keyboardType: TextInputType.emailAddress,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Configuración de factura
            _seccion(
              titulo: 'Configuración de Factura',
              icono: Icons.receipt_long,
              subtitulo: 'Opcional - Para cuando implemente factura electrónica',
              children: [
                _campo(
                  controller: _timbradoCtrl,
                  label: 'Número de timbrado',
                  icono: Icons.numbers,
                  maxLength: 20,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _seleccionarFecha,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            color: Color(0xFF1E88E5)),
                        const SizedBox(width: 12),
                        Text(
                          _vencimientoTimbrado != null
                              ? 'Vencimiento: ${_vencimientoTimbrado!.day}/${_vencimientoTimbrado!.month}/${_vencimientoTimbrado!.year}'
                              : 'Fecha vencimiento timbrado',
                          style: TextStyle(
                            color: _vencimientoTimbrado != null
                                ? Colors.black
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _campo(
                  controller: _nroFacturaCtrl,
                  label: 'Número de factura inicial',
                  icono: Icons.tag,
                  maxLength: 20,
                  hintText: 'Ej: 001-001-0000001',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Botón guardar ajustes
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E88E5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _guardando ? null : _guardarAjustes,
                icon: const Icon(Icons.save, color: Colors.white),
                label: _guardando
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'GUARDAR AJUSTES',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),

            // Cambiar contraseña
            _seccion(
              titulo: 'Cambiar Contraseña',
              icono: Icons.lock,
              children: [
                _campoPass(
                  controller: _passActualCtrl,
                  label: 'Contraseña actual',
                  ver: _verPassActual,
                  onVer: () =>
                      setState(() => _verPassActual = !_verPassActual),
                ),
                const SizedBox(height: 16),
                _campoPass(
                  controller: _passNuevaCtrl,
                  label: 'Nueva contraseña',
                  ver: _verPassNueva,
                  onVer: () =>
                      setState(() => _verPassNueva = !_verPassNueva),
                ),
                const SizedBox(height: 16),
                _campoPass(
                  controller: _passConfirmarCtrl,
                  label: 'Confirmar nueva contraseña',
                  ver: _verPassConfirmar,
                  onVer: () => setState(
                      () => _verPassConfirmar = !_verPassConfirmar),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A2744),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _cambiarContrasena,
                    icon: const Icon(Icons.lock_reset, color: Colors.white),
                    label: const Text(
                      'CAMBIAR CONTRASEÑA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _seccion({
    required String titulo,
    required IconData icono,
    required List<Widget> children,
    String? subtitulo,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E88E5).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icono, color: const Color(0xFF1E88E5), size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A2744),
                      fontSize: 16,
                    ),
                  ),
                  if (subtitulo != null)
                    Text(
                      subtitulo,
                      style: const TextStyle(
                          color: Colors.orange, fontSize: 11),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _campo({
    required TextEditingController controller,
    required String label,
    required IconData icono,
    int? maxLength,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    String? hintText,
  }) {
    return TextFormField(
      controller: controller,
      maxLength: maxLength,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icono, color: const Color(0xFF1E88E5)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 2),
        ),
        counterStyle: const TextStyle(fontSize: 11),
      ),
    );
  }

  Widget _campoPass({
    required TextEditingController controller,
    required String label,
    required bool ver,
    required VoidCallback onVer,
  }) {
    return TextField(
      controller: controller,
      obscureText: !ver,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock, color: Color(0xFF1E88E5)),
        suffixIcon: IconButton(
          icon: Icon(
            ver ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey,
          ),
          onPressed: onVer,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 2),
        ),
      ),
    );
  }
}