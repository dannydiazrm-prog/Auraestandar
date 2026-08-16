import '../widgets/responsive.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pedido.dart';
import '../widgets/page_header.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PedidosScreen extends StatefulWidget {
  const PedidosScreen({super.key});

  @override
  State<PedidosScreen> createState() => _PedidosScreenState();
}

class _PedidosScreenState extends State<PedidosScreen> {
  @override
  void initState() {
    super.initState();
    _limpiarEntregados();
  }

  Future<void> _limpiarEntregados() async {
    final ayer = DateTime.now().subtract(const Duration(days: 1));
    final snap = await FirebaseFirestore.instance
        .collection('pedidos')
        .where('estado', isEqualTo: 'entregado')
        .get();
    for (final doc in snap.docs) {
      final fecha = DateTime.parse(doc['fechaCreacion']);
      if (fecha.isBefore(ayer)) {
        await doc.reference.delete();
      }
    }
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'en_proceso': return Colors.blue;
      case 'listo': return Colors.green;
      case 'entregado': return Colors.grey;
      default: return Colors.orange;
    }
  }

  String _textoEstado(String estado) {
    switch (estado) {
      case 'en_proceso': return 'En proceso';
      case 'listo': return 'Listo';
      case 'entregado': return 'Entregado';
      default: return 'Pendiente';
    }
  }

  void _abrirFormulario({Pedido? pedido}) {
    final clienteCtrl = TextEditingController(text: pedido?.clienteNombre ?? '');
    final adelantoCtrl = TextEditingController(text: pedido?.adelanto.toStringAsFixed(0) ?? '0');
    DateTime fechaEntrega = pedido?.fechaEntrega ?? DateTime.now().add(const Duration(days: 1));
    String estado = pedido?.estado ?? 'pendiente';
    List<Map<String, dynamic>> items = pedido?.items.map((i) => {
      'descripcion': i.descripcion,
      'cantidad': i.cantidad,
      'precio': i.precio,
      'descCtrl': TextEditingController(text: i.descripcion),
      'cantCtrl': TextEditingController(text: i.cantidad.toString()),
      'precioCtrl': TextEditingController(text: formatGs(i.precio)),
    }).toList() ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          double total = items.fold(0, (sum, item) {
            final cant = int.tryParse(item['cantCtrl'].text) ?? 0;
            final precio = double.tryParse(item['precioCtrl'].text) ?? 0;
            return sum + (cant * precio);
          });
          final adelanto = double.tryParse(adelantoCtrl.text) ?? 0;
          final saldo = total - adelanto;

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom.clamp(0.0, double.infinity) + 24),
            child: SingleChildScrollView(
              padding: Responsive.pagePadding(context),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pedido == null ? 'Nuevo Pedido' : 'Editar Pedido',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A2744))),
                  const SizedBox(height: 16),
                  TextField(
                    controller: clienteCtrl,
                    decoration: const InputDecoration(labelText: 'Cliente', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  const Text('Productos / Servicios', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A2744))),
                  const SizedBox(height: 8),
                  ...items.asMap().entries.map((entry) {
                    final i = entry.key;
                    final item = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F6FA),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: item['descCtrl'],
                                  decoration: const InputDecoration(labelText: 'Descripción', border: OutlineInputBorder(), isDense: true),
                                  onChanged: (_) => setModalState(() {}),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => setModalState(() => items.removeAt(i)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: item['cantCtrl'],
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'Cant.', border: OutlineInputBorder(), isDense: true),
                                  onChanged: (_) => setModalState(() {}),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: item['precioCtrl'],
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'Precio unit. (Gs.)', border: OutlineInputBorder(), isDense: true),
                                  onChanged: (_) => setModalState(() {}),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                  TextButton.icon(
                    onPressed: () => setModalState(() => items.add({
                      'descripcion': '',
                      'cantidad': 1,
                      'precio': 0.0,
                      'descCtrl': TextEditingController(),
                      'cantCtrl': TextEditingController(text: '1'),
                      'precioCtrl': TextEditingController(),
                    })),
                    icon: const Icon(Icons.add, color: Color(0xFF1E88E5)),
                    label: const Text('Agregar item', style: TextStyle(color: Color(0xFF1E88E5))),
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('Gs. ${formatGs(total)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E88E5))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: adelantoCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Adelanto recibido (Gs.)', border: OutlineInputBorder()),
                    onChanged: (_) => setModalState(() {}),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Saldo pendiente:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('Gs. ${formatGs(saldo)}',
                          style: TextStyle(fontWeight: FontWeight.bold, color: saldo > 0 ? Colors.orange : Colors.green)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Fecha de entrega: ', style: TextStyle(color: Colors.grey)),
                      TextButton(
                        onPressed: () async {
                          final fecha = await showDatePicker(
                            context: context,
                            initialDate: fechaEntrega,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (fecha != null) setModalState(() => fechaEntrega = fecha);
                        },
                        child: Text('${fechaEntrega.day}/${fechaEntrega.month}/${fechaEntrega.year}',
                            style: const TextStyle(color: Color(0xFF1E88E5), fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E88E5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () async {
                        if (clienteCtrl.text.isEmpty || items.isEmpty) return;
                        final itemsData = items.map((item) => {
                          'descripcion': item['descCtrl'].text,
                          'cantidad': int.tryParse(item['cantCtrl'].text) ?? 1,
                          'precio': double.tryParse(item['precioCtrl'].text) ?? 0,
                        }).toList();
                        final data = {
                          'clienteNombre': clienteCtrl.text,
                          'items': itemsData,
                          'adelanto': double.tryParse(adelantoCtrl.text) ?? 0,
                          'fechaEntrega': fechaEntrega.toIso8601String(),
                          'estado': estado,
                          'fechaCreacion': pedido?.fechaCreacion.toIso8601String() ?? DateTime.now().toIso8601String(),
                        };
                        if (pedido == null) {
                          await FirebaseFirestore.instance.collection('pedidos').add(data);
                          final nuevoPedido = Pedido(
                            id: '',
                            clienteNombre: clienteCtrl.text,
                            items: items.map((item) => ItemPedido(
                              descripcion: item['descCtrl'].text,
                              cantidad: int.tryParse(item['cantCtrl'].text) ?? 1,
                              precio: double.tryParse(item['precioCtrl'].text) ?? 0,
                            )).toList(),
                            adelanto: double.tryParse(adelantoCtrl.text) ?? 0,
                            fechaEntrega: fechaEntrega,
                            estado: 'pendiente',
                            fechaCreacion: DateTime.now(),
                          );
                          Navigator.pop(context);
                          await _imprimirPedido(nuevoPedido, 'ticket');
                        } else {
                          await FirebaseFirestore.instance.collection('pedidos').doc(pedido.id).update(data);
                          Navigator.pop(context);
                        }
                      },
                      child: Text(pedido == null ? 'Guardar Pedido' : 'Actualizar',
                          style: const TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }


  Future<void> _imprimirPedido(Pedido pedido, String formato) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(
              child: pw.Text(
                'Para ${pedido.clienteNombre}',
                style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Center(
              child: pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black, width: 2),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Text(
                  'ENTREGAR EL: ${pedido.fechaEntrega.day}/${pedido.fechaEntrega.month}/${pedido.fechaEntrega.year}',
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                ),
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text('DESCRIPCIÓN:', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Divider(),
            ...pedido.items.map((item) => pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 4),
              child: pw.Text('• ${item.cantidad}x ${item.descripcion}', style: const pw.TextStyle(fontSize: 13)),
            )),
            pw.Divider(),
            pw.SizedBox(height: 12),
            pw.Text('ESTADO DEL PEDIDO:', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            ...['Pendiente', 'En proceso', 'Listo', 'Entregado'].map((estado) => pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 5),
              child: pw.Row(
                children: [
                  pw.Container(
                    width: 16, height: 16,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.black, width: 1.5),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Text(estado, style: const pw.TextStyle(fontSize: 13)),
                ],
              ),
            )),
            pw.Divider(),
            pw.SizedBox(height: 16),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.black, width: 2.5),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                children: [
                  pw.Text(
                    'POR COBRAR: Gs. ${formatGs(pedido.saldo)}',
                    style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    'Total: Gs. ${formatGs(pedido.total)}   |   Adelanto: Gs. ${formatGs(pedido.adelanto)}',
                    style: const pw.TextStyle(fontSize: 10),
                    textAlign: pw.TextAlign.center,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text('NOTAS:', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.Container(
              width: double.infinity,
              height: 120,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400, width: 1),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }
  void _mostrarOpciones(Pedido pedido) {
    final estado = pedido.estado;
    Color colorEstado;
    String textoEstado;
    switch (estado) {
      case 'en_proceso': colorEstado = Colors.blue; textoEstado = 'En proceso'; break;
      case 'listo': colorEstado = Colors.green; textoEstado = 'Listo'; break;
      default: colorEstado = Colors.orange; textoEstado = 'Pendiente';
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 16),
        child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(pedido.clienteNombre, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A2744))),
            const SizedBox(height: 4),
            Text('Entrega: ${pedido.fechaEntrega.day}/${pedido.fechaEntrega.month}/${pedido.fechaEntrega.year}', style: const TextStyle(color: Colors.grey)),
            Text('Total: Gs. ${formatGs(pedido.total)} | Saldo: Gs. ${formatGs(pedido.saldo)}', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: colorEstado.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
              child: Text(textoEstado, style: TextStyle(color: colorEstado, fontWeight: FontWeight.bold)),
            ),
            const Divider(height: 24),
            ListTile(
              leading: const Icon(Icons.edit, color: Color(0xFF1E88E5)),
              title: const Text('Editar'),
              onTap: () { Navigator.pop(context); _abrirFormulario(pedido: pedido); },
            ),
            ListTile(
              leading: const Icon(Icons.print, color: Colors.purple),
              title: const Text('Ticket'),
              onTap: () { Navigator.pop(context); _imprimirPedido(pedido, 'ticket'); },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text('A4'),
              onTap: () { Navigator.pop(context); _imprimirPedido(pedido, 'a4'); },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Eliminar pedido', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Eliminar'),
                    content: Text('¿Eliminar este pedido?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: () async {
                          await FirebaseFirestore.instance.collection('pedidos').doc(pedido.id).delete();
                          Navigator.pop(context);
                        },
                        child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
              },
            ),
            const Text('Cambiar estado:', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A2744))),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _chipEstado(pedido.id, 'pendiente', 'Pendiente', Colors.orange, estado),
                _chipEstado(pedido.id, 'en_proceso', 'En proceso', Colors.blue, estado),
                _chipEstado(pedido.id, 'listo', 'Listo', Colors.green, estado),
                _chipEstadoEntregado(pedido.id, context),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _chipEstado(String id, String estado, String texto, Color color, String estadoActual) {
    final seleccionado = estadoActual == estado;
    return GestureDetector(
      onTap: () async {
        await FirebaseFirestore.instance.collection('pedidos').doc(id).update({'estado': estado});
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: seleccionado ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(texto, style: TextStyle(color: seleccionado ? Colors.white : color, fontWeight: FontWeight.bold, fontSize: 12)),
      ),
    );
  }

  Widget _chipEstadoEntregado(String id, BuildContext ctx) {
    return GestureDetector(
      onTap: () async {
        final confirmar = await showDialog<bool>(
          context: ctx,
          builder: (context) => AlertDialog(
            title: const Text('Marcar como entregado'),
            content: const Text('El pedido se eliminará al marcarlo como entregado. ¿Continuar?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirmar', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
        if (confirmar == true) {
          await FirebaseFirestore.instance.collection('pedidos').doc(id).delete();
          Navigator.pop(ctx);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
        child: const Text('Entregado', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: Responsive.pagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          pageHeader('PEDIDOS', context,
            trailing: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E88E5),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => _abrirFormulario(),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Nuevo Pedido', style: TextStyle(color: Colors.white)),
            ),
          ),
          const SizedBox(height: 24),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('pedidos')
                .orderBy('fechaEntrega')
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData || snap.data!.docs.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: const Center(child: Column(children: [
                    Icon(Icons.assignment_outlined, size: 60, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No hay pedidos aún', style: TextStyle(color: Colors.grey, fontSize: 16)),
                    SizedBox(height: 8),
                    Text('Toca "Nuevo Pedido" para agregar', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  ])),
                );
              }
              final pedidos = snap.data!.docs.map((doc) =>
                Pedido.fromMap(doc.id, doc.data() as Map<String, dynamic>)).toList();
              return Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: pedidos.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
                  itemBuilder: (context, index) {
                    final p = pedidos[index];
                    final vencido = p.fechaEntrega.isBefore(DateTime.now()) && p.estado != 'entregado';
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _colorEstado(p.estado).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.assignment, color: _colorEstado(p.estado), size: 22),
                      ),
                      title: Row(
                        children: [
                          Text(p.clienteNombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _colorEstado(p.estado).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(_textoEstado(p.estado), style: TextStyle(color: _colorEstado(p.estado), fontSize: 11)),
                          ),
                          if (vencido) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                              child: const Text('Vencido', style: TextStyle(color: Colors.red, fontSize: 11)),
                            ),
                          ],
                        ],
                      ),
                      subtitle: Text('${p.items.length} item(s) | Saldo: Gs. ${formatGs(p.saldo)}', style: const TextStyle(fontSize: 12)),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Gs. ${formatGs(p.total)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E88E5))),
                          Text('${p.fechaEntrega.day}/${p.fechaEntrega.month}/${p.fechaEntrega.year}',
                              style: TextStyle(fontSize: 11, color: vencido ? Colors.red : Colors.grey)),
                        ],
                      ),
                      onTap: () => _mostrarOpciones(p),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
