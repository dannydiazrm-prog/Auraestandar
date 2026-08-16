import 'widgets/responsive.dart';
import 'widgets/page_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/nueva_venta.dart';
import 'screens/productos_screen.dart';
import 'screens/historial_ventas.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/login_screen.dart';
import 'screens/caja_screen.dart';
import 'services/firestore_service.dart';
import 'screens/clientes_screen.dart';
import 'screens/alertas_stock_screen.dart';
import 'screens/reporte_ventas_screen.dart';
import 'screens/reporte_inventario_screen.dart';
import 'screens/finanzas_screen.dart';
import 'screens/ajustes_screen.dart';
import 'screens/pedidos_screen.dart';
import 'screens/pedidos_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'services/personalizacion_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Esto arregla el Punto 1: Pantalla completa solo en Android
  if (ThemeData().platform == TargetPlatform.android) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool? _activada;

  @override
  void initState() {
    super.initState();
    _cargarEstado();
    PersonalizacionService.instance.cargar();
  }

  Future<void> _cargarEstado() async {
    final prefs = await SharedPreferences.getInstance();
    final activada = prefs.getBool('app_activada') ?? false;
    if (mounted) setState(() => _activada = activada);
  }

  void _marcarActivada() {
    setState(() => _activada = true);
  }

  void _marcarDesactivada() {
    setState(() => _activada = false);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: PersonalizacionService.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'Aura Estándar',
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('es'),
          ],
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: PersonalizacionService.instance.colorPrimario,
            ),
            useMaterial3: true,
          ),
          home: _activada == null
              ? const Scaffold(body: Center(child: CircularProgressIndicator()))
              : _activada == true
                  ? MainLayout(onCerrarSesion: _marcarDesactivada)
                  : LoginScreen(onActivado: _marcarActivada),
        );
      },
    );
  }
}

class MainLayout extends StatefulWidget {
  final VoidCallback onCerrarSesion;
  const MainLayout({super.key, required this.onCerrarSesion});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  String _paginaActual = 'Dashboard';
  bool _sidebarVisible = true;

  final Map<String, List<String>> _submenus = {
    'Ventas': ['Nueva Venta', 'Historial de Ventas', 'Pedidos', 'Caja', 'Clientes'],
    'Inventario': ['Productos', 'Alertas de Stock'],
    'Reportes': ['Ventas', 'Inventario'],
    'Finanzas': [],
    'Ajustes': [],
  };
  
  final Map<String, IconData> _iconos = {
    'Dashboard': Icons.dashboard,
    'Ventas': Icons.receipt,
    'Inventario': Icons.inventory,
    'Reportes': Icons.bar_chart,
    'Finanzas': Icons.account_balance_wallet,
    'Ajustes': Icons.settings,
  };

  void _toggleSidebar() => setState(() => _sidebarVisible = !_sidebarVisible);

  Widget _buildSidebar() {
    return Container(
      width: 230,
      color: const Color(0xFF1A2744),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: PersonalizacionService.instance.logoPath != null
                  ? Image.file(
                      File(PersonalizacionService.instance.logoPath!),
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 80,
                      height: 80,
                      color: Colors.white12,
                      child: const Icon(Icons.storefront, color: Colors.white70, size: 40),
                    ),
            ),
            const SizedBox(height: 10),
            Text(
              PersonalizacionService.instance.nombreComercio.toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const Text('Gestión e Inventario', style: TextStyle(color: Colors.white54, fontSize: 11)),
            const SizedBox(height: 20),
            _menuSimple('Dashboard'),
            ..._submenus.keys.map((nombre) =>
              _submenus[nombre]!.isEmpty
                ? _menuSimple(nombre)
                : _menuDesplegable(nombre),
            ),
            const SizedBox(height: 20),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              child: IconButton(
                icon: const Icon(Icons.logout, color: Colors.white70, size: 28),
                tooltip: 'Cerrar sesión',
                onPressed: () async {
                  final confirmar = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Cerrar sesión'),
                      content: const Text('¿Estás seguro que deseas cerrar sesión?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancelar'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Cerrar sesión', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                  if (confirmar == true) {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('app_activada', false);
                    widget.onCerrarSesion();
                  }
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }


   @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_paginaActual != 'Dashboard') {
          setState(() => _paginaActual = 'Dashboard');
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        drawer: isMobile ? Drawer(child: _buildSidebar()) : null,
       body: SafeArea(
        child: Row(
        children: [
            if (!isMobile && _sidebarVisible)
              _buildSidebar(),
            Expanded(
              child: Container(
                color: const Color(0xFFF4F6FA),
                child: Stack(
                  children: [
                    _buildPagina(),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Material(
                        color: Colors.transparent,
                        child: Builder(
                          builder: (context) => IconButton(
                            icon: const Icon(Icons.menu, color: Color(0xFF1A2744)),
                            onPressed: () {
                              if (MediaQuery.of(context).size.width < 600) {
                                Scaffold.of(context).openDrawer();
                              } else {
                                _toggleSidebar();
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
	  ),
    );
  }


  Widget _buildPagina() {
    switch (_paginaActual) {
      case 'Dashboard':
        return DashboardContent(
          onFacturar: () => setState(() => _paginaActual = 'Nueva Venta'),
onVerFinanzas: () => setState(() => _paginaActual = 'Finanzas'),
onVerStock: () => setState(() => _paginaActual = 'Alertas de Stock'),
onVerProductos: () => setState(() => _paginaActual = 'Productos'),
        );
      case 'Nueva Venta':
        return const NuevaVentaScreen();
      case 'Historial de Ventas':
        return const HistorialVentasScreen();
      case 'Caja':
        return const CajaScreen();
      case 'Productos':
        return const ProductosScreen();
      case 'Clientes':
        return const ClientesScreen();
      case 'Pedidos':
        return const PedidosScreen();
      case 'Alertas de Stock':
        return const AlertasStockScreen();
      case 'Ventas':
        return const ReporteVentasScreen();
      case 'Inventario':
        return const ReporteInventarioScreen();
      case 'Finanzas':
        return const FinanzasScreen();
      case 'Ajustes':
        return const AjustesScreen();
      default:
        return _paginaGenerica(_paginaActual);
    }
  }

  Widget _paginaGenerica(String titulo) {
    return Center(
      child: Text(
        titulo,
        style: const TextStyle(fontSize: 24, color: Color(0xFF1A2744)),
      ),
    );
  }


  
    Widget _menuSimple(String nombre) {
    final activo = _paginaActual == nombre;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(
        color: activo
            ? const Color(0xFF1E88E5).withOpacity(0.3)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(_iconos[nombre], color: Colors.white),
        title: Text(nombre, style: const TextStyle(color: Colors.white)),
        onTap: () {
          if (MediaQuery.of(context).size.width < 600) {
            Navigator.pop(context);
          }
          setState(() => _paginaActual = nombre);
        },
      ),
    );
  }

  Widget _menuDesplegable(String nombre) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        leading: Icon(_iconos[nombre], color: Colors.white),
        title: Text(nombre, style: const TextStyle(color: Colors.white)),
        iconColor: Colors.white,
        collapsedIconColor: Colors.white,
        childrenPadding: const EdgeInsets.only(left: 20),
        children: _submenus[nombre]!.map((sub) {
          final activo = _paginaActual == sub;
          return ListTile(
            leading: Icon(
              Icons.circle,
              size: 8,
              color: activo ? const Color(0xFF1E88E5) : Colors.white54,
            ),
            title: Text(
              sub,
              style: TextStyle(
                color: activo ? const Color(0xFF1E88E5) : Colors.white70,
                fontSize: 13,
              ),
            ),
            onTap: () {
              if (MediaQuery.of(context).size.width < 600) {
                Navigator.pop(context);
              }
              setState(() => _paginaActual = sub);
            },
          );
        }).toList(),
      ),
    );
  }

Widget pageHeader(String titulo, BuildContext context) {
    final now = DateTime.now();
    final fecha = '${now.day}/${now.month}/${now.year}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(56, 16, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 8),
              Text('Hoy: $fecha', style: const TextStyle(color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A2744),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
class DashboardContent extends StatefulWidget {
  final VoidCallback onFacturar;
  final VoidCallback onVerFinanzas;
  final VoidCallback onVerStock;
  final VoidCallback onVerProductos;
  const DashboardContent({super.key, required this.onFacturar, required this.onVerFinanzas, required this.onVerStock, required this.onVerProductos});

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  final FirestoreService _service = FirestoreService();
  double _ventasMes = 0;
  int _totalProductos = 0;
  int _stockBajo = 0;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarEstadisticas();
  }

  Future<void> _cargarEstadisticas() async {
    final ahora = DateTime.now();
    final inicioMes = DateTime(ahora.year, ahora.month, 1).toIso8601String();
    final finMes = DateTime(ahora.year, ahora.month + 1, 0, 23, 59, 59).toIso8601String();

    // Ventas del mes
    FirebaseFirestore.instance
        .collection('ventas')
        .where('fecha', isGreaterThanOrEqualTo: inicioMes)
        .where('fecha', isLessThanOrEqualTo: finMes)
        .snapshots()
        .listen((snap) {
      double total = 0;
      for (final v in snap.docs) {
        if (v.data()['estado'] != 'anulada') {
          total += (v.data()['total'] ?? 0).toDouble();
        }
      }
      setState(() => _ventasMes = total);
    });

    // Productos y stock bajo
    FirebaseFirestore.instance
        .collection('productos')
        .where('esServicio', isEqualTo: false)
        .snapshots()
        .listen((snap) {
      int stockBajo = 0;
      for (final p in snap.docs) {
        if ((p.data()['stock'] ?? 0) <= (p.data()['stockMinimo'] ?? 0)) {
          stockBajo++;
        }
      }
      setState(() {
        _totalProductos = snap.docs.length;
        _stockBajo = stockBajo;
        _cargando = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    final isMobile = MediaQuery.of(context).size.width < 700;
    return SingleChildScrollView(
      padding: Responsive.pagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          pageHeader('BIENVENIDO BN24py', context),
          isMobile
            ? Column(children: [
                _tarjeta('Ventas del Mes', _cargando ? '...' : 'Gs. ${formatGs(_ventasMes)}', Icons.trending_up, Colors.blue, onTap: widget.onVerFinanzas),
                const SizedBox(height: 8),
                _tarjeta('Stock Bajo', _cargando ? '...' : '$_stockBajo', Icons.warning, Colors.orange, onTap: widget.onVerStock),
                const SizedBox(height: 8),
                _tarjeta('Productos', _cargando ? '...' : '$_totalProductos', Icons.inventory, Colors.purple, onTap: widget.onVerProductos),
              ])
            : Row(children: [
                Expanded(child: _tarjeta('Ventas del Mes', _cargando ? '...' : 'Gs. ${formatGs(_ventasMes)}', Icons.trending_up, Colors.blue, onTap: widget.onVerFinanzas)),
                const SizedBox(width: 16),
                Expanded(child: _tarjeta('Stock Bajo', _cargando ? '...' : '$_stockBajo', Icons.warning, Colors.orange, onTap: widget.onVerStock)),
                const SizedBox(width: 16),
                Expanded(child: _tarjeta('Productos', _cargando ? '...' : '$_totalProductos', Icons.inventory, Colors.purple, onTap: widget.onVerProductos)),
              ]),
          const SizedBox(height: 24),
        isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _cardUltimasVentas(),
                const SizedBox(height: 16),
                _cardPedidos(),
                const SizedBox(height: 16),
                _cardFacturar(),
                const SizedBox(height: 16),
                _cardFrase(),
              ],
            )
          : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: Column(
                children: [
                  _cardUltimasVentas(),
                  const SizedBox(height: 16),
                  _cardPedidos(),
                ],
              )),
              const SizedBox(width: 16),
              Expanded(
            child: Column(
              children: [
                _cardFacturar(),
                const SizedBox(height: 16),
                _cardFrase(),
              ],
            ),
          ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tarjeta(String titulo, String valor, IconData icono, Color color, {VoidCallback? onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icono, color: color, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo, style: const TextStyle(color: Colors.grey, fontSize: 12), overflow: TextOverflow.ellipsis),
                    Text(valor, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tarjetaGrid(String titulo, String valor, IconData icono, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icono, color: color, size: 28),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(titulo, style: const TextStyle(color: Colors.grey, fontSize: 11)),
              Text(valor, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cardUltimasVentas() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Últimas Ventas',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF1A2744),
            ),
          ),
          const Divider(height: 24),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('ventas')
                .orderBy('fecha', descending: true)
                .limit(3)
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData || snap.data!.docs.isEmpty) {
                return const Text(
                  'Aún no hay ventas registradas.',
                  style: TextStyle(color: Colors.grey),
                );
              }
              return Column(
                children: snap.data!.docs.map((doc) {
                  final v = doc.data() as Map<String, dynamic>;
                  final fecha = DateTime.parse(v['fecha']);
                  final anulada = v['estado'] == 'anulada';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: anulada
                          ? Colors.red.withOpacity(0.05)
                          : const Color(0xFFF4F6FA),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: anulada
                            ? Colors.red.withOpacity(0.2)
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              v['clienteNombre'] ?? 'Cliente',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              '${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Gs. ${formatGs((v['total'] ?? 0).toDouble())}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: anulada
                                    ? Colors.red
                                    : const Color(0xFF1E88E5),
                              ),
                            ),
                            if (anulada)
                              const Text(
                                'ANULADA',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }


static const List<String> _frases = [
    'Lo difícil es empezar. Ya lo hiciste.',
    'Cada venta es un paso más hacia tu sueño.',
    'Los grandes negocios empezaron exactamente donde estás vos ahora.',
    'El esfuerzo de hoy es el éxito de mañana.',
    'Emprender es creer en vos misma antes que nadie más lo haga.',
    'No importa cuán despacio vayas, siempre y cuando no te detengas.',
    'Tu negocio es el reflejo de tu dedicación.',
    'Cada cliente satisfecho es tu mejor publicidad.',
    'Lo estás haciendo increíble, aunque a veces no lo parezca.',
    'El camino del emprendimiento es tuyo y de nadie más.',
  ];

Widget _cardPedidos() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.assignment, color: Color(0xFF1E88E5), size: 20),
              SizedBox(width: 8),
              Text('Pedidos activos', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A2744))),
            ],
          ),
          const Divider(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('pedidos')
                .orderBy('fechaEntrega')
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData || snap.data!.docs.isEmpty) {
                return const Text('Sin pedidos pendientes', style: TextStyle(color: Colors.grey, fontSize: 13));
              }
              final pedidos = snap.data!.docs
                  .where((doc) => (doc.data() as Map<String, dynamic>)['estado'] != 'entregado')
                  .take(3)
                  .toList();
              if (pedidos.isEmpty) {
                return const Text('Sin pedidos pendientes', style: TextStyle(color: Colors.grey, fontSize: 13));
              }
              return Column(
                children: pedidos.map((doc) {
                  final p = doc.data() as Map<String, dynamic>;
                  final fecha = DateTime.parse(p['fechaEntrega']);
                  final vencido = fecha.isBefore(DateTime.now());
                  final estado = p['estado'] ?? 'pendiente';
                  Color colorEstado;
                  String textoEstado;
                  switch (estado) {
                    case 'en_proceso': colorEstado = Colors.blue; textoEstado = 'En proceso'; break;
                    case 'listo': colorEstado = Colors.green; textoEstado = 'Listo'; break;
                    default: colorEstado = Colors.orange; textoEstado = 'Pendiente';
                  }
                  return GestureDetector(
                    onTap: () {
                    showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => Padding(
                          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 80),
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
                              Text(p['clienteNombre'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A2744))),
                              const SizedBox(height: 4),
                              Text('Entrega: ${fecha.day}/${fecha.month}/${fecha.year}', style: const TextStyle(color: Colors.grey)),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: colorEstado.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                                child: Text(textoEstado, style: TextStyle(color: colorEstado, fontWeight: FontWeight.bold)),
                              ),
                              const Divider(height: 24),
                              const Text('Cambiar estado:', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A2744))),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children: [
                                  _chipEstado(doc.id, 'pendiente', 'Pendiente', Colors.orange, estado),
                                  _chipEstado(doc.id, 'en_proceso', 'En proceso', Colors.blue, estado),
                                  _chipEstado(doc.id, 'listo', 'Listo', Colors.green, estado),
                                  _chipEstadoEntregado(doc.id, context),
                                ],
                              ),
                            ],
                          ),
                        ),
						),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorEstado.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: colorEstado.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p['clienteNombre'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), overflow: TextOverflow.ellipsis),
                                Text(textoEstado, style: TextStyle(fontSize: 11, color: colorEstado)),
                              ],
                            ),
                          ),
                          Text('${fecha.day}/${fecha.month}/${fecha.year}',
                              style: TextStyle(fontSize: 11, color: vencido ? Colors.red : Colors.grey)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
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
  
  Widget _cardFrase() {
    final frase = _frases[DateTime.now().day % _frases.length];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E88E5), Color(0xFF1A2744)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(Icons.format_quote, color: Colors.white54, size: 28),
          const SizedBox(height: 8),
          Text(
            frase,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
  Widget _cardFacturar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(Icons.receipt_long, size: 60, color: Color(0xFF1E88E5)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E88E5),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: widget.onFacturar,
              child: const Text('FACTURAR AHORA', style: TextStyle(color: Colors.white)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: const BorderSide(color: Color(0xFF1E88E5)),
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => Dialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      constraints: const BoxConstraints(maxHeight: 500),
                      child: Column(
                        children: [
                          const Text('Tutorial', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A2744))),
                          const Divider(height: 24),
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _TutorialSeccion('VENTAS', [
                                    ('Nueva Venta', 'Desde aqui realizas todas tus facturas. Selecciona el cliente, agrega los productos y confirma la venta. El sistema calcula el IVA y el vuelto automaticamente.'),
                                    ('Historial de Ventas', 'Consulta todas las ventas realizadas. Podes filtrar por fecha, reimprimir tickets y anular ventas si es necesario ingresando tu contrasena.'),
                                    ('Caja', 'Resumen del movimiento del dia. Muestra el total de ventas, cantidad de transacciones y el efectivo en caja.'),
                                    ('Clientes', 'Gestiona tu cartera de clientes. Podes agregar, editar o eliminar clientes.'),
                                    ('Pedidos', 'Administra los pedidos de tus clientes. Podes crear pedidos con fecha de entrega, registrar adelantos, cambiar el estado y generar un PDF interno para el taller.'),
                                  ]),
                                  const SizedBox(height: 16),
                                  _TutorialSeccion('INVENTARIO', [
                                    ('Productos', 'Administra tu catalogo de productos y servicios. Podes crear nuevos productos, editar precios, reponer stock o dar de baja unidades danadas o perdidas.'),
                                    ('Alertas de Stock', 'Visualiza todos los productos que estan por debajo del stock minimo configurado para que puedas reponerlos a tiempo.'),
                                  ]),
                                  const SizedBox(height: 16),
                                  _TutorialSeccion('REPORTES', [
                                    ('Ventas', 'Analiza tus ventas por periodo con graficos. Identifica tus mejores clientes y los productos mas vendidos.'),
                                    ('Inventario', 'Consulta el estado actual de tu inventario. Podes generar e imprimir un reporte PDF para toma de inventario fisico.'),
                                  ]),
                                  const SizedBox(height: 16),
                                  _TutorialSeccion('FINANZAS', [
                                    ('Finanzas', 'Segui la salud financiera de tu negocio. Registra ingresos, gastos y capital inyectado. El sistema calcula automaticamente tu ganancia o perdida del periodo.'),
                                  ]),
                                  const SizedBox(height: 16),
                                  _TutorialSeccion('AJUSTES', [
                                    ('Ajustes', 'Configura los datos de tu negocio, informacion de factura, timbrado y cambia tu contrasena de acceso.'),
                                  ]),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E88E5)),
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cerrar', style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              child: const Text('TUTORIAL', style: TextStyle(color: Color(0xFF1E88E5))),
            ),
          ),
        ],
      ),
    );
  }
}

class _TutorialSeccion extends StatelessWidget {
  final String titulo;
  final List<(String, String)> items;
  const _TutorialSeccion(this.titulo, this.items);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A2744))),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('• ${item.$1}', style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E88E5))),
              const SizedBox(height: 2),
              Text(item.$2, style: const TextStyle(color: Colors.grey, fontSize: 13)),
            ],
          ),
        )),
      ],
    );
  }
}