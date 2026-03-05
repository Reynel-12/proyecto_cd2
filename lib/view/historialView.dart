import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:proyecto_cd2/controller/repository_venta.dart';
import 'package:proyecto_cd2/model/app_logger.dart';
import 'package:proyecto_cd2/model/preferences.dart';
import 'package:provider/provider.dart';
import 'package:proyecto_cd2/model/venta.dart';
import 'package:table_calendar/table_calendar.dart';

class Historial extends StatefulWidget {
  const Historial({super.key});

  @override
  State<Historial> createState() => _HistorialState();
}

class _HistorialState extends State<Historial> {
  DateTime hoy = DateTime.now();
  // final repositorySarConfig = SarService();
  final repositoryVenta = VentaRepository();
  final AppLogger _logger = AppLogger.instance;
  List<VentaCompleta> ventas = [];

  @override
  void initState() {
    super.initState();
    _cargarVentas();
  }

  void _cargarVentas() async {
    try {
      final ventas = await repositoryVenta.getVentasAgrupadas();
      setState(() {
        this.ventas = ventas;
      });
    } catch (e, st) {
      _logger.log.e('Error cargando ventas', error: e, stackTrace: st);
    }
  }

  void _DiaSeleccionado(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      hoy = selectedDay;
    });
  }

  List<VentaCompleta> get _ventasDelDia {
    return ventas.where((venta) {
      DateTime fechaVenta = DateTime.parse(venta.fecha);
      return isSameDay(fechaVenta, hoy);
    }).toList();
  }

  StreamSubscription? _ventasSubscription;

  @override
  void dispose() {
    // Cancelar la suscripción cuando el widget se destruye
    _ventasSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Obtenemos el tamaño de la pantalla
    final screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 600;
    final bool isTablet = screenSize.width >= 600 && screenSize.width < 900;
    final bool isDesktop = screenSize.width >= 900;

    // Ajustamos tamaños según el dispositivo
    final double titleFontSize = isMobile ? 18.0 : (isTablet ? 20.0 : 22.0);
    final double contentPadding = isMobile ? 12.0 : (isTablet ? 16.0 : 24.0);
    final double cardElevation = isMobile ? 3.0 : 5.0;

    // final isConnected = Provider.of<InternetProvider>(context).isConnected;

    return Scaffold(
      backgroundColor: Provider.of<TemaProveedor>(context).esModoOscuro
          ? Colors.black
          : const Color.fromRGBO(244, 243, 243, 1),
      appBar: AppBar(
        title: Text(
          'Historial de ventas',
          style: TextStyle(
            color: Provider.of<TemaProveedor>(context).esModoOscuro
                ? Colors.white
                : Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: titleFontSize,
          ),
        ),
        centerTitle: true,
        backgroundColor: Provider.of<TemaProveedor>(context).esModoOscuro
            ? Colors.black
            : const Color.fromRGBO(244, 243, 243, 1),
        iconTheme: IconThemeData(
          color: Provider.of<TemaProveedor>(context).esModoOscuro
              ? Colors.white
              : Colors.black,
        ),
      ),
      body: isDesktop
          ? _buildDesktopLayout(contentPadding, cardElevation)
          : _buildMobileTabletLayout(contentPadding, cardElevation),
    );
  }

  // Layout para móvil y tablet (diseño vertical)
  Widget _buildMobileTabletLayout(double padding, double elevation) {
    return Padding(
      padding: EdgeInsets.all(padding),
      child: ListView(
        children: [
          Column(
            children: [
              _buildCalendario(elevation),
              SizedBox(height: padding),
              _buildResumenVentasDelDia(elevation),
              SizedBox(height: padding),
              const Text(
                'Ventas:',
                style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: padding / 2),
              _buildListaVentasDelDia(elevation),
            ],
          ),
        ],
      ),
    );
  }

  // Layout para escritorio (diseño horizontal)
  Widget _buildDesktopLayout(double padding, double elevation) {
    return Padding(
      padding: EdgeInsets.all(padding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Columna izquierda con calendario y resumen
          Expanded(
            flex: 2,
            child: Column(
              children: [
                _buildCalendario(elevation),
                SizedBox(height: padding),
                _buildResumenVentasDelDia(elevation),
              ],
            ),
          ),

          SizedBox(width: padding),

          // Columna derecha con lista de ventas
          Expanded(
            flex: 3,
            child: Card(
              color: Provider.of<TemaProveedor>(context).esModoOscuro
                  ? const Color.fromRGBO(30, 30, 30, 1)
                  : Colors.white,
              elevation: elevation,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: EdgeInsets.all(padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Ventas del día',
                          style: TextStyle(
                            fontSize: 22.0,
                            fontWeight: FontWeight.bold,
                            color:
                                Provider.of<TemaProveedor>(context).esModoOscuro
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                        Text(
                          '${hoy.day}/${hoy.month}/${hoy.year}',
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.w500,
                            color:
                                Provider.of<TemaProveedor>(context).esModoOscuro
                                ? Colors.white.withOpacity(0.7)
                                : Colors.black.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: padding),
                    Expanded(child: _buildListaVentasDelDia(elevation)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Calendario responsivo
  Widget _buildCalendario(double elevation) {
    // Obtenemos el tamaño de la pantalla
    final screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 600;
    final bool isTablet = screenSize.width >= 600 && screenSize.width < 900;

    // Ajustamos tamaños según el dispositivo
    final double rowHeight = isMobile ? 40.0 : (isTablet ? 45.0 : 50.0);
    final double iconSize = isMobile ? 24.0 : (isTablet ? 26.0 : 28.0);
    final double titleFontSize = isMobile ? 16.0 : (isTablet ? 18.0 : 20.0);

    return Container(
      padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Provider.of<TemaProveedor>(context).esModoOscuro
            ? const Color.fromRGBO(30, 30, 30, 1)
            : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TableCalendar(
        rowHeight: rowHeight,
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.w600,
            color: Provider.of<TemaProveedor>(context).esModoOscuro
                ? Colors.white
                : Colors.black,
          ),
          leftChevronIcon: Icon(
            Icons.chevron_left,
            color: Provider.of<TemaProveedor>(context).esModoOscuro
                ? Colors.white
                : Colors.black,
            size: iconSize,
          ),
          rightChevronIcon: Icon(
            Icons.chevron_right,
            color: Provider.of<TemaProveedor>(context).esModoOscuro
                ? Colors.white
                : Colors.black,
            size: iconSize,
          ),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: TextStyle(
            color: Provider.of<TemaProveedor>(context).esModoOscuro
                ? Colors.white
                : Colors.black,
            fontWeight: FontWeight.w500,
            fontSize: isMobile ? 12.0 : 14.0,
          ),
          weekendStyle: TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.w500,
            fontSize: isMobile ? 12.0 : 14.0,
          ),
        ),
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: Colors.blueAccent.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          selectedDecoration: const BoxDecoration(
            color: Colors.blueAccent,
            shape: BoxShape.circle,
          ),
          markerDecoration: const BoxDecoration(
            color: Colors.redAccent,
            shape: BoxShape.circle,
          ),
          outsideDaysVisible: false,
          defaultTextStyle: TextStyle(
            color: Provider.of<TemaProveedor>(context).esModoOscuro
                ? Colors.white
                : Colors.black,
            fontWeight: FontWeight.w400,
            fontSize: isMobile ? 12.0 : 14.0,
          ),
          weekendTextStyle: TextStyle(
            color: Colors.redAccent,
            fontSize: isMobile ? 12.0 : 14.0,
          ),
        ),
        selectedDayPredicate: (day) => isSameDay(day, hoy),
        focusedDay: hoy,
        firstDay: DateTime.utc(2010, 10, 16),
        lastDay: DateTime.utc(2030, 3, 14),
        onDaySelected: _DiaSeleccionado,
        eventLoader: (day) {
          return ventas.where((venta) {
            DateTime fechaVenta = DateTime.parse(venta.fecha);
            return isSameDay(fechaVenta, day);
          }).toList();
        },
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, day, events) {
            if (events.isNotEmpty) {
              return Positioned(
                bottom: 5, // Ajuste moderno
                right: 5,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: Colors.redAccent, // Marcador en rojo elegante
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${events.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            }
            return null;
          },
        ),
      ),
    );
  }

  // Resumen de ventas responsivo
  Widget _buildResumenVentasDelDia(double elevation) {
    // Obtenemos el tamaño de la pantalla
    final screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 600;
    final bool isTablet = screenSize.width >= 600 && screenSize.width < 900;

    // Ajustamos tamaños según el dispositivo
    final double fontSize = isMobile ? 14.0 : (isTablet ? 15.0 : 16.0);
    final double iconSize = isMobile ? 20.0 : (isTablet ? 22.0 : 24.0);

    final ventasHoy = _ventasDelDia;
    double totalDelDia = ventasHoy.fold(0.0, (sum, item) => sum + item.total);
    double promedioVenta = ventasHoy.isEmpty
        ? 0.0
        : totalDelDia / ventasHoy.length;

    return Container(
      padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
      decoration: BoxDecoration(
        color: Provider.of<TemaProveedor>(context).esModoOscuro
            ? const Color.fromRGBO(30, 30, 30, 1)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.summarize, color: Colors.blueAccent, size: iconSize),
              SizedBox(width: 8),
              Text(
                'Resumen del día',
                style: TextStyle(
                  fontSize: fontSize + 2,
                  fontWeight: FontWeight.bold,
                  color: Provider.of<TemaProveedor>(context).esModoOscuro
                      ? Colors.white
                      : Colors.black,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildResumenItem(
            'Total de ventas',
            '${ventasHoy.length}',
            fontSize,
            iconSize,
            Icons.receipt_long,
          ),
          SizedBox(height: isMobile ? 8.0 : 12.0),
          _buildResumenItem(
            'Total del día',
            'L. ${totalDelDia.toStringAsFixed(2)}',
            fontSize,
            iconSize,
            Icons.attach_money,
          ),
          SizedBox(height: isMobile ? 8.0 : 12.0),
          _buildResumenItem(
            'Promedio por venta',
            'L. ${promedioVenta.toStringAsFixed(2)}',
            fontSize,
            iconSize,
            Icons.trending_up,
          ),
        ],
      ),
    );
  }

  // Item de resumen responsivo
  Widget _buildResumenItem(
    String label,
    String value,
    double fontSize,
    double iconSize,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          color: Provider.of<TemaProveedor>(context).esModoOscuro
              ? Colors.white.withOpacity(0.7)
              : Colors.black.withOpacity(0.7),
          size: iconSize,
        ),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
              color: Provider.of<TemaProveedor>(context).esModoOscuro
                  ? Colors.white
                  : Colors.black,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Provider.of<TemaProveedor>(context).esModoOscuro
                ? Colors.white
                : Colors.black,
          ),
        ),
      ],
    );
  }

  // Lista de ventas responsiva
  Widget _buildListaVentasDelDia(double elevation) {
    // Obtenemos el tamaño de la pantalla
    final screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 600;
    final bool isTablet = screenSize.width >= 600 && screenSize.width < 900;
    final bool isDesktop = screenSize.width >= 900;

    // Ajustamos tamaños según el dispositivo
    final double titleFontSize = isMobile ? 16.0 : (isTablet ? 17.0 : 18.0);
    final double subtitleFontSize = isMobile ? 12.0 : (isTablet ? 13.0 : 14.0);
    final double iconSize = isMobile ? 20.0 : (isTablet ? 22.0 : 24.0);
    final double cardPadding = isMobile ? 10.0 : (isTablet ? 12.0 : 16.0);

    final ventasHoy = _ventasDelDia;

    if (ventasHoy.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Text(
            'No hay ventas registradas para este día.',
            style: TextStyle(
              fontSize: subtitleFontSize,
              color: Provider.of<TemaProveedor>(context).esModoOscuro
                  ? Colors.white70
                  : Colors.black54,
            ),
          ),
        ),
      );
    }

    // Si hay ventas, mostrar las tarjetas de ventas
    return ListView.builder(
      shrinkWrap: true,
      physics: isDesktop ? null : const NeverScrollableScrollPhysics(),
      itemCount: ventasHoy.length,
      itemBuilder: (context, index) {
        final venta = ventasHoy[index];
        DateTime fechaVenta = DateTime.parse(venta.fecha);
        String fecha =
            "${fechaVenta.day.toString().padLeft(2, '0')}/${fechaVenta.month.toString().padLeft(2, '0')}/${fechaVenta.year}";
        String hora =
            "${fechaVenta.hour.toString().padLeft(2, '0')}:${fechaVenta.minute.toString().padLeft(2, '0')}";

        return _buildVentaCard(
          venta.id,
          venta.total,
          venta.montoPagado,
          venta.cambio,
          venta.detalles.length,
          fecha,
          hora,
          titleFontSize,
          subtitleFontSize,
          iconSize,
          cardPadding,
          elevation,
          venta.numeroFactura,
          venta.detalles,
          venta,
        );
      },
    );
  }

  // Tarjeta de venta responsiva
  Widget _buildVentaCard(
    int ventaId,
    double total,
    double montoPagado,
    double cambio,
    int elementos,
    String fecha,
    String hora,
    double titleFontSize,
    double subtitleFontSize,
    double iconSize,
    double cardPadding,
    double elevation,
    String numeroFactura,
    List<DetalleItem> detalles,
    VentaCompleta venta,
  ) {
    final screenSize = MediaQuery.of(context).size;
    final bool isDesktop = screenSize.width >= 900;
    return Card(
      color: Provider.of<TemaProveedor>(context).esModoOscuro
          ? isDesktop
                ? Colors.black
                : const Color.fromRGBO(30, 30, 30, 1)
          : isDesktop
          ? const Color.fromRGBO(244, 243, 243, 1)
          : Colors.white,
      elevation: elevation,
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(
            vertical: cardPadding / 2,
            horizontal: cardPadding,
          ),
          leading: CircleAvatar(
            backgroundColor: Colors.blueAccent.withOpacity(0.2),
            child: Icon(
              Icons.shopping_cart,
              color: Colors.blueAccent,
              size: iconSize,
            ),
          ),
          title: Text(
            '#$numeroFactura',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: titleFontSize,
              color: Provider.of<TemaProveedor>(context).esModoOscuro
                  ? Colors.white
                  : Colors.black,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildVentaInfoRow(
                  'Método de pago:',
                  venta.metodoPago,
                  subtitleFontSize,
                  Icons.payment,
                ),
                SizedBox(height: 4),
                _buildVentaInfoRow(
                  'Total:',
                  'L. ${total.toStringAsFixed(2)}',
                  subtitleFontSize,
                  Icons.attach_money,
                ),
                SizedBox(height: 4),
                _buildVentaInfoRow(
                  'Elementos:',
                  '$elementos',
                  subtitleFontSize,
                  Icons.shopping_bag_outlined,
                ),
                SizedBox(height: 4),
                _buildVentaInfoRow(
                  'Hora:',
                  hora,
                  subtitleFontSize,
                  Icons.access_time,
                ),
              ],
            ),
          ),
          children: [
            Divider(
              height: 1,
              thickness: 1,
              color: Provider.of<TemaProveedor>(context).esModoOscuro
                  ? Color.fromRGBO(220, 220, 220, 1).withOpacity(0.2)
                  : Color.fromRGBO(60, 60, 60, 1).withOpacity(0.2),
            ),
            Column(
              children: detalles.map((detalle) {
                return _buildProductoItem(
                  detalle.producto,
                  detalle.unidadMedida,
                  detalle.cantidad,
                  detalle.precio,
                  detalle.isv,
                  detalle.subtotal,
                  detalle.descuento,
                  subtitleFontSize,
                  iconSize,
                  cardPadding,
                );
              }).toList(),
            ),
            Padding(
              padding: EdgeInsets.all(cardPadding),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recibido: L. $montoPagado',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: subtitleFontSize + 1,
                      color: Provider.of<TemaProveedor>(context).esModoOscuro
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                  Text(
                    'Cambio: L. $cambio',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: subtitleFontSize + 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Fila de información de venta
  Widget _buildVentaInfoRow(
    String label,
    String value,
    double fontSize,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: fontSize + 2,
          color: Provider.of<TemaProveedor>(context).esModoOscuro
              ? Colors.white.withOpacity(0.7)
              : Colors.black.withOpacity(0.7),
        ),
        SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            color: Provider.of<TemaProveedor>(context).esModoOscuro
                ? Colors.white.withOpacity(0.7)
                : Colors.black.withOpacity(0.7),
          ),
        ),
        SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
            color: Provider.of<TemaProveedor>(context).esModoOscuro
                ? Colors.white
                : Colors.black,
          ),
        ),
      ],
    );
  }

  // Item de producto en la venta
  Widget _buildProductoItem(
    String nombre,
    String unidad,
    int cantidad,
    double precio,
    double isv,
    double subtotal,
    double descuento,
    double fontSize,
    double iconSize,
    double padding,
  ) {
    return ListTile(
      leading: Icon(
        Icons.shopping_bag,
        color: Colors.blueAccent,
        size: iconSize,
      ),
      title: Text(
        '$nombre - $unidad',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: fontSize + 1,
          color: Provider.of<TemaProveedor>(context).esModoOscuro
              ? Colors.white
              : Colors.black,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 4),
          Text(
            'Cantidad: $cantidad',
            style: TextStyle(
              color: Provider.of<TemaProveedor>(context).esModoOscuro
                  ? Color.fromRGBO(220, 220, 220, 1)
                  : Color.fromRGBO(60, 60, 60, 1),
              fontSize: fontSize,
            ),
          ),
          Text(
            'Precio: L. ${precio.toStringAsFixed(2)}',
            style: TextStyle(
              color: Provider.of<TemaProveedor>(context).esModoOscuro
                  ? Color.fromRGBO(220, 220, 220, 1)
                  : Color.fromRGBO(60, 60, 60, 1),
              fontSize: fontSize,
            ),
          ),
          Text(
            'ISV: $isv%',
            style: TextStyle(
              color: Provider.of<TemaProveedor>(context).esModoOscuro
                  ? Color.fromRGBO(220, 220, 220, 1)
                  : Color.fromRGBO(60, 60, 60, 1),
              fontSize: fontSize,
            ),
          ),
          Text(
            'Descuento: L. ${descuento.toStringAsFixed(2)}',
            style: TextStyle(
              color: Provider.of<TemaProveedor>(context).esModoOscuro
                  ? Color.fromRGBO(220, 220, 220, 1)
                  : Color.fromRGBO(60, 60, 60, 1),
              fontSize: fontSize,
            ),
          ),
          Text(
            'SubTotal: L. ${(subtotal.toStringAsFixed(2))}',
            style: TextStyle(
              color: Provider.of<TemaProveedor>(context).esModoOscuro
                  ? Color.fromRGBO(220, 220, 220, 1)
                  : Color.fromRGBO(60, 60, 60, 1),
              fontSize: fontSize,
            ),
          ),
        ],
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: padding,
        vertical: padding / 2,
      ),
    );
  }
}
