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
      const SnackBar(content: Text('Nombre actualizado exitosamente'), backgroundColor: Colors.green),
    );
  }

  Future<void> _seleccionarLogo() async {
    final picker = ImagePicker();
    final XFile? imagen = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (imagen == null) return;

    final directorio = await getApplicationDocumentsDirectory();
    final nuevoPath = '${directorio.path}/logo_negocio.png';
    await File(imagen.path).copy(nuevoPath);
    await PersonalizacionService.instance.guardarLogoPath(nuevoPath);

    if (!mounted) return;
    setState(() {});
  }

  Future<void> _abrirWhatsapp() async {
    final uri = Uri.parse('https://wa.me/595983069263');
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir WhatsApp. Verificá que la app esté instalada.'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al conectar con soporte'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _seleccionarColor() async {
    Color colorSeleccionado = PersonalizacionService.instance.colorPrimario;
    final resultado = await showModalBottomSheet<Color>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            const Text('Seleccionar color principal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            ColorPicker(
              pickerColor: colorSeleccionado,
              onColorChanged: (c) => colorSeleccionado = c,
              enableAlpha: false,
              labelTypes: const [],
              pickerAreaHeightPercent: 0.5,
              pickerAreaBorderRadius: BorderRadius.circular(12),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorSeleccionado,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(context, colorSeleccionado),
                child: const Text('APLICAR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
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
          pageHeader('Ajustes', context),
          const SizedBox(height: 8),
          _seccion(
            titulo: 'Identidad',
            icono: Icons.palette_outlined,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: _seleccionarLogo,
                    child: Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        color: PersonalizacionService.instance.colorPrimario.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: PersonalizacionService.instance.logoPath != null
                          ? ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.file(File(PersonalizacionService.instance.logoPath!), fit: BoxFit.cover))
                          : Icon(Icons.add_photo_alternate, color: PersonalizacionService.instance.colorPrimario, size: 32),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _seleccionarLogo,
                      icon: const Icon(Icons.image_outlined),
                      label: const Text('Cambiar logo'),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _nombreComercioCtrl,
                decoration: InputDecoration(
                  labelText: 'Nombre del comercio',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _guardandoMarca ? null : _guardarNombreComercio,
                  style: FilledButton.styleFrom(
                    backgroundColor: PersonalizacionService.instance.colorPrimario,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _guardandoMarca ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('GUARDAR CAMBIOS'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _seccion(
            titulo: 'Configuración de Estilo',
            icono: Icons.style_outlined,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(width: 48, height: 48, decoration: BoxDecoration(color: PersonalizacionService.instance.colorPrimario, shape: BoxShape.circle)),
                title: const Text('Color principal'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _seleccionarColor,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _seccion(
            titulo: 'Soporte y Acerca de',
            icono: Icons.help_outline,
            children: [
              const Text('Versión 1.0.0', style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _abrirWhatsapp,
                  icon: const Icon(Icons.support_agent),
                  label: const Text('Contactar soporte técnico'),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _seccion({required String titulo, required IconData icono, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade100)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icono, color: PersonalizacionService.instance.colorPrimario), const SizedBox(width: 12), Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }
}
