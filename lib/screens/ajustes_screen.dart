import 'dart:io';
import '../widgets/responsive.dart';
import '../widgets/page_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../services/firestore_service.dart';
import '../services/personalizacion_service.dart';

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
  final _nombreComercioCtrl = TextEditingController();

  DateTime? _vencimientoTimbrado;
  bool _cargando = false;
  bool _guardando = false;
  bool _guardandoMarca = false;

  @override
  void initState() {
    super.initState();
    _cargarAjustes();
    _nombreComercioCtrl.text = PersonalizacionService.instance.nombreComercio;
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
    _nombreComercioCtrl.dispose();
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
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ajustes guardados correctamente'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _guardarNombreComercio() async {
    final nombre = _nombreComercioCtrl.text.trim();
    if (nombre.isEmpty) return;
    setState(() => _guardandoMarca = true);
    await PersonalizacionService.instance.guardarNombre(nombre);
    setState(() => _guardandoMarca = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Nombre del comercio actualizado'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _seleccionarLogo() async {
    final picker = ImagePicker();
    final XFile? imagen = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (imagen == null) return;

    final directorio = await getApplicationDocumentsDirectory();
    final nuevoPath = '${directorio.path}/logo_negocio.png';
    await File(imagen.path).copy(nuevoPath);
    await PersonalizacionService.instance.guardarLogoPath(nuevoPath);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Logo actualizado'),
        backgroundColor: Colors.green,
      ),
    );
    setState(() {});
  }

  Future<void> _seleccionarColor() async {
    Color colorSeleccionado = PersonalizacionService.instance.colorPrimario;

    final resultado = await showModalBottomSheet<Color>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Elegí el color principal',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A2744)),
              ),
              const SizedBox(height: 20),
              ColorPicker(
                pickerColor: colorSeleccionado,
                onColorChanged: (c) => colorSeleccionado = c,
                enableAlpha: false,
                displayThumbColor: true,
                labelTypes: const [],
                pickerAreaHeightPercent: 0.55,
                pickerAreaBorderRadius: BorderRadius.circular(16),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorSeleccionado,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.pop(context, colorSeleccionado),
                  child: const Text('APLICAR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (resultado != null) {
      await PersonalizacionService.instance.guardarColor(resultado);
      if (mounted) setState(() {});
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          pageHeader('AJUSTES', context),

          // Personalización de marca
          _seccion(
            titulo: 'Personalización',
            icono: Icons.palette,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: _seleccionarLogo,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: PersonalizacionService.instance.logoPath != null
                          ? Image.file(
                              File(PersonalizacionService.instance.logoPath!),
                              width: 72,
                              height: 72,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 72,
                              height: 72,
                              color: PersonalizacionService.instance.colorPrimario.withOpacity(0.1),
                              child: Icon(Icons.storefront, color: PersonalizacionService.instance.colorPrimario, size: 32),
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _seleccionarLogo,
                      icon: const Icon(Icons.image),
                      label: const Text('Cambiar logo'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nombreComercioCtrl,
                maxLength: 40,
                decoration: InputDecoration(
                  labelText: 'Nombre del comercio',
                  prefixIcon: const Icon(Icons.store),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: PersonalizacionService.instance.colorPrimario, width: 2),
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PersonalizacionService.instance.colorPrimario,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _guardandoMarca ? null : _guardarNombreComercio,
                  child: _guardandoMarca
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('GUARDAR NOMBRE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
              const Divider(height: 1),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: PersonalizacionService.instance.colorPrimario,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade300, width: 2),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _seleccionarColor,
                      icon: const Icon(Icons.color_lens),
                      label: const Text('Cambiar color principal'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                            const Icon(Icons.calendar_today, color: Color(0xFF1E88E5)),
                            const SizedBox(width: 12),
                            Text(
                              _vencimientoTimbrado != null
                                  ? 'Vencimiento: ${_vencimientoTimbrado!.day}/${_vencimientoTimbrado!.month}/${_vencimientoTimbrado!.year}'
                                  : 'Fecha vencimiento timbrado',
                              style: TextStyle(
                                color: _vencimientoTimbrado != null ? Colors.black : Colors.grey,
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
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E88E5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _guardando ? null : _guardarAjustes,
                    icon: const Icon(Icons.save, color: Colors.white),
                    label: _guardando
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'GUARDAR AJUSTES',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
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
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A2744), fontSize: 16),
                  ),
                  if (subtitulo != null)
                    Text(subtitulo, style: const TextStyle(color: Colors.orange, fontSize: 11)),
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
}