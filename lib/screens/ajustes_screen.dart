import 'dart:io';
import '../widgets/responsive.dart';
import '../widgets/page_header.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/firestore_service.dart';
import '../services/personalizacion_service.dart';

class AjustesScreen extends StatefulWidget {
  const AjustesScreen({super.key});

  @override
  State<AjustesScreen> createState() => _AjustesScreenState();
}

class _AjustesScreenState extends State<AjustesScreen> {
  final _nombreComercioCtrl = TextEditingController();
  bool _guardandoMarca = false;

  @override
  void initState() {
    super.initState();
    _nombreComercioCtrl.text = PersonalizacionService.instance.nombreComercio;
  }

  @override
  void dispose() {
    _nombreComercioCtrl.dispose();
    super.dispose();
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

Future<void> _abrirWhatsapp() async {
    final uri = Uri.parse('https://wa.me/595983069263');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: Responsive.pagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          pageHeader('AJUSTES', context),
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
          _seccion(
            titulo: 'Acerca de',
            icono: Icons.info_outline,
            children: [
              const Text(
                'Versión 1.0.0',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 4),
              const Text(
                'Creado por JP LABS',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _abrirWhatsapp,
                  icon: const Icon(Icons.support_agent, size: 18),
                  label: const Text('Soporte'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _seccion({
    required String titulo,
    required IconData icono,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, color: PersonalizacionService.instance.colorPrimario, size: 20),
              const SizedBox(width: 10),
              Text(
                titulo,
                style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A2744), fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}