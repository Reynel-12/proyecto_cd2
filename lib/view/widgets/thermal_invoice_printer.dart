import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:proyecto_cd2/model/preferences.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ThermalInvoicePrinter {
  static const double _marginLeft = 4.0;
  static const double _marginRight = 4.0;
  static const double _lineSpacing = 1.5;
  static const double _sectionSpacing = 6.0;

  final InvoiceData data;

  ThermalInvoicePrinter({required this.data});

  Future<Uint8List> generatePdf({required double paperWidthMm}) async {
    final pdf = pw.Document();
    final double paperWidthPt = paperWidthMm * 2.8346;

    final double contentWidth = paperWidthPt - _marginLeft - _marginRight;
    final content = _buildInvoiceContent(contentWidth);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(paperWidthPt, double.infinity, marginAll: 0),
        build: (context) {
          return pw.Container(
            padding: const pw.EdgeInsets.symmetric(
              horizontal: _marginLeft,
              vertical: 8,
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: content,
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  List<pw.Widget> _buildInvoiceContent(double maxWidth) {
    final List<pw.Widget> children = [];

    // === ENCABEZADO FISCAL ===
    children.add(_buildHeader(maxWidth));

    children.add(pw.SizedBox(height: _sectionSpacing));
    children.add(_divider(maxWidth));

    // === INFORMACIÓN DEL CLIENTE ===
    children.add(pw.SizedBox(height: _sectionSpacing));
    children.add(_buildCustomerInfo(maxWidth));

    // === DETALLES DE FACTURA ===
    children.add(pw.SizedBox(height: _sectionSpacing));
    children.add(_buildInvoiceDetails(maxWidth));

    // === INFORMACIÓN OPERATIVA (NO FISCAL) ===
    if (data.typeOrder.isNotEmpty) {
      children.add(pw.SizedBox(height: 4));
      children.add(_regularText("Tipo de pedido: ${data.typeOrder}", maxWidth));
    }

    children.add(pw.SizedBox(height: _sectionSpacing));
    children.add(_divider(maxWidth));

    // === ÍTEMS ===
    children.add(pw.SizedBox(height: _sectionSpacing));
    children.add(_buildItemsTable(maxWidth));

    // === TOTALES ===
    children.add(pw.SizedBox(height: _sectionSpacing));
    children.add(_buildTotals(maxWidth));

    // === TOTAL EN LETRAS ===
    if (data.totalInWords.isNotEmpty) {
      children.add(pw.SizedBox(height: 4));
      children.add(_regularText(data.totalInWords, maxWidth));
    }

    // === MONEDA ===
    children.add(pw.SizedBox(height: 4));
    children.add(_centerText("Moneda: Lempiras (HNL)", maxWidth));

    // === LEYENDA FISCAL ===
    children.add(pw.SizedBox(height: 6));
    children.add(
      _centerText("Documento válido para efectos fiscales", maxWidth),
    );

    // === NOTAS ===
    if (data.notes.isNotEmpty) {
      children.add(pw.SizedBox(height: 4));
      children.add(_centerText(data.notes, maxWidth));
    }

    children.add(pw.SizedBox(height: 20));
    return children;
  }

  /// ENCABEZADO FISCAL
  pw.Widget _buildHeader(double maxWidth) {
    return pw.Center(
      child: pw.Column(
        children: [
          pw.SizedBox(height: 6),
          _boldText(
            "FACTURA",
            maxWidth,
            align: pw.TextAlign.center,
            fontSize: 12,
          ),
          pw.SizedBox(height: 4),
          _boldText(data.businessName, maxWidth, align: pw.TextAlign.center),
          _regularText(
            "RTN: ${data.businessRtn}",
            maxWidth,
            align: pw.TextAlign.center,
          ),
          _regularText(
            data.businessAddress,
            maxWidth,
            align: pw.TextAlign.center,
          ),
          if (data.businessPhone.isNotEmpty)
            _regularText(
              "Tel: ${data.businessPhone}",
              maxWidth,
              align: pw.TextAlign.center,
            ),
          if (data.businessEmail.isNotEmpty)
            _regularText(
              "Correo electrónico: ${data.businessEmail}",
              maxWidth,
              align: pw.TextAlign.center,
            ),

          // === DATOS SAR ===
          if (data.cai.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            _boldText("CAI", maxWidth, align: pw.TextAlign.center),
            _regularText(data.cai, maxWidth, align: pw.TextAlign.center),
            _regularText(
              "Rango autorizado",
              maxWidth,
              align: pw.TextAlign.center,
            ),
            _regularText(
              data.rangoAutorizado,
              maxWidth,
              align: pw.TextAlign.center,
            ),
            _regularText(
              "Fecha límite: ${data.fechaLimite}",
              maxWidth,
              align: pw.TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  /// CLIENTE
  pw.Widget _buildCustomerInfo(double maxWidth) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          children: [
            _boldText("Cliente: ", maxWidth),
            _regularText(
              data.customerName.isEmpty
                  ? "Consumidor Final"
                  : data.customerName,
              maxWidth,
            ),
          ],
        ),
        if (data.rtnCliente.isNotEmpty)
          pw.Row(
            children: [
              _boldText("RTN: ", maxWidth),
              _regularText(data.rtnCliente, maxWidth),
            ],
          ),
        pw.Row(
          children: [
            _boldText("Método de pago: ", maxWidth),
            _regularText(data.metodoPago, maxWidth),
          ],
        ),
      ],
    );
  }

  /// DETALLES FACTURA
  pw.Widget _buildInvoiceDetails(double maxWidth) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _regularText("No. Factura: ${data.invoiceNumber}", maxWidth),
        _regularText("Fecha: ${data.date} ${data.hora}", maxWidth),
        if (data.cashier.isNotEmpty)
          _regularText("Cajero: ${data.cashier}", maxWidth),
      ],
    );
  }

  /// TOTALES
  pw.Widget _buildTotals(double maxWidth) {
    final currency = NumberFormat.currency(
      symbol: data.currencySymbol,
      decimalDigits: 2,
    );

    // Calcular desglose de impuestos
    double totalExento = 0.0;
    double totalGravado15 = 0.0;
    double isv15 = 0.0;
    double totalGravado18 = 0.0;
    double isv18 = 0.0;

    for (var item in data.items) {
      if (item.isvPercent == 0) {
        totalExento += item.total;
      } else if (item.isvPercent == 15) {
        double base = item.total / 1.15;
        totalGravado15 += base;
        isv15 += (item.total - base);
      } else if (item.isvPercent == 18) {
        double base = item.total / 1.18;
        totalGravado18 += base;
        isv18 += (item.total - base);
      } else {
        // Fallback para otros porcentajes, tratarlos como Gravado Genérico
        double factor = 1 + (item.isvPercent / 100);
        double base = item.total / factor;
        // Podríamos agregarlo a 15 o separarlo. Por ahora se asume 15/18 son los principales.
        // Si hay otro, lo sumamos al base 15 como default o creamos otro bucket.
        // Asumiremos que todo lo demás va a 15 por simplicidad si no es 18.
        totalGravado15 += base;
        isv15 += (item.total - base);
      }
    }

    // Fallback para facturas históricas sin desglose por ítem (Solo si hay ISV global pero no calculable)
    bool useLegacyMode =
        (totalGravado15 == 0 && totalGravado18 == 0 && data.isv > 0);

    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: maxWidth * 0.75, // Un poco más ancho para textos largos
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            _divider(maxWidth * 0.75),

            if (useLegacyMode) ...[
              _totalRow(
                "Subtotal:",
                currency.format(data.subtotal),
                maxWidth * 0.75,
              ),
              _totalRow("ISV:", currency.format(data.isv), maxWidth * 0.75),
            ] else ...[
              // Subtotal (Suma de bases + exento)
              _totalRow(
                "Subtotal:",
                currency.format(totalExento + totalGravado15 + totalGravado18),
                maxWidth * 0.75,
              ),

              if (totalExento > 0)
                _totalRow(
                  "Importe Exento:",
                  currency.format(totalExento),
                  maxWidth * 0.75,
                ),

              if (totalGravado15 > 0) ...[
                _totalRow(
                  "Importe Gravado 15%:",
                  currency.format(totalGravado15),
                  maxWidth * 0.75,
                ),
                _totalRow("ISV 15%:", currency.format(isv15), maxWidth * 0.75),
              ],

              if (totalGravado18 > 0) ...[
                _totalRow(
                  "Importe Gravado 18%:",
                  currency.format(totalGravado18),
                  maxWidth * 0.75,
                ),
                _totalRow("ISV 18%:", currency.format(isv18), maxWidth * 0.75),
              ],
            ],

            pw.SizedBox(height: 4),
            _divider(maxWidth * 0.75),
            pw.SizedBox(height: 4),

            _totalRow(
              "TOTAL A PAGAR:",
              currency.format(data.total),
              maxWidth * 0.75,
              fontWeight: pw.FontWeight.bold,
              fontSize: 12,
            ),

            pw.SizedBox(height: 4),
            _totalRow(
              "Recibido:",
              currency.format(data.recibido),
              maxWidth * 0.75,
            ),
            _totalRow(
              "Cambio:",
              currency.format(data.recibido - data.total),
              maxWidth * 0.75,
            ),
          ],
        ),
      ),
    );
  }

  // ===== WIDGETS AUXILIARES =====

  pw.Widget _regularText(
    String text,
    double maxWidth, {
    pw.TextAlign align = pw.TextAlign.left,
    double? fontSize,
  }) {
    return pw.Text(
      text,
      style: pw.TextStyle(fontSize: fontSize ?? 9, lineSpacing: _lineSpacing),
      textAlign: align,
    );
  }

  pw.Widget _boldText(
    String text,
    double maxWidth, {
    pw.TextAlign align = pw.TextAlign.left,
    double? fontSize,
  }) {
    return pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: fontSize ?? 10,
        fontWeight: pw.FontWeight.bold,
        lineSpacing: _lineSpacing,
      ),
      textAlign: align,
    );
  }

  pw.Widget _centerText(String text, double maxWidth) {
    return pw.Align(
      alignment: pw.Alignment.center,
      child: _regularText(text, maxWidth, align: pw.TextAlign.center),
    );
  }

  pw.Widget _divider(double width) {
    return pw.Container(width: width, height: 1, color: PdfColors.grey800);
  }

  /// Tabla de ítems (adaptativa)
  pw.Widget _buildItemsTable(double maxWidth) {
    final bool isNarrow = maxWidth < 180;

    if (isNarrow) {
      // === MODO 58mm: Lista vertical ===
      return pw.Column(
        children: data.items.map((item) {
          final desc = item.description.length > 20
              ? "${item.description.substring(0, 18)}.."
              : item.description;

          final isvText = item.isvPercent == 0
              ? "(E)"
              : "(${item.isvPercent.toStringAsFixed(0)}%)";

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _boldText("$desc $isvText", maxWidth, fontSize: 9),

              pw.Row(
                children: [
                  _regularText("${item.quantity}x", maxWidth * 0.2),
                  pw.Spacer(),
                  _regularText(
                    "${NumberFormat.currency(symbol: '', decimalDigits: 2).format(item.unitPrice)}",
                    maxWidth * 0.35,
                    align: pw.TextAlign.right,
                  ),
                  pw.Spacer(),
                  _boldText(
                    NumberFormat.currency(
                      symbol: '',
                      decimalDigits: 2,
                    ).format(item.total),
                    maxWidth * 0.35,
                    align: pw.TextAlign.right,
                  ),
                ],
              ),
              if (item.discount > 0)
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: _regularText(
                    "Desc: -${NumberFormat.currency(symbol: 'L. ', decimalDigits: 2).format(item.discount)}",
                    maxWidth,
                    fontSize: 8,
                  ),
                ),
              pw.SizedBox(height: 4),
            ],
          );
        }).toList(),
      );
    } else {
      // === MODO 80mm: Tabla alineada ===
      final headers = ["Descripción", "Cant", "P.Unit", "SubTotal"];
      final colWidths = {
        0: pw.FlexColumnWidth(3),
        1: pw.FlexColumnWidth(1),
        2: pw.FlexColumnWidth(1.2),
        3: pw.FlexColumnWidth(1.3),
      };

      return pw.Table(
        border: pw.TableBorder.all(style: pw.BorderStyle.none),
        columnWidths: colWidths,
        children: [
          // Encabezados
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey300),
            children: headers
                .map(
                  (h) => pw.Padding(
                    padding: const pw.EdgeInsets.all(3),
                    child: _boldText(h, 50, fontSize: 8),
                  ),
                )
                .toList(),
          ),
          // Filas
          ...data.items.map((item) {
            return pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(3),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _regularText(
                        "${item.description} ${item.isvPercent == 0 ? '(E)' : '(${item.isvPercent.toStringAsFixed(0)}%)'}",
                        100,
                      ),
                      if (item.discount > 0)
                        _regularText(
                          "Desc: -${NumberFormat.currency(symbol: 'L.', decimalDigits: 2).format(item.discount)}",
                          100,
                          fontSize: 7,
                        ),
                    ],
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(3),
                  child: _regularText(
                    item.quantity.toStringAsFixed(0),
                    30,
                    align: pw.TextAlign.center,
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(3),
                  child: _regularText(
                    NumberFormat.currency(
                      symbol: '',
                      decimalDigits: 2,
                    ).format(item.unitPrice),
                    40,
                    align: pw.TextAlign.right,
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(3),
                  child: _boldText(
                    NumberFormat.currency(
                      symbol: '',
                      decimalDigits: 2,
                    ).format(item.total),
                    40,
                    align: pw.TextAlign.right,
                  ),
                ),
              ],
            );
          }),
        ],
      );
    }
  }

  pw.Widget _totalRow(
    String label,
    String value,
    double width, {
    pw.FontWeight fontWeight = pw.FontWeight.normal,
    double fontSize = 9,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        _regularText(label, width * 0.6),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: fontSize, fontWeight: fontWeight),
          textAlign: pw.TextAlign.right,
        ),
      ],
    );
  }
}

/// ---------------------------------------------------------------
/// MODELO DE DATOS
/// ---------------------------------------------------------------
class InvoiceData {
  final String businessName;
  final String businessRtn;
  final String businessAddress;
  final String businessPhone;
  final String businessEmail;
  final String typeOrder;
  final String invoiceNumber;
  final String date;
  final String hora;
  final String cashier;
  final String customerName;
  final String customerAddress;
  final List<InvoiceItem> items;
  final double total;
  final double recibido;
  final String metodoPago;
  final String currencySymbol;
  final String notes;
  // SAR Fields
  final String cai;
  final String rangoAutorizado;
  final String fechaLimite;
  final String rtnCliente;
  final double isv;
  final double subtotal;
  final String totalInWords;

  InvoiceData({
    required this.businessName,
    required this.businessRtn,
    this.businessAddress = '',
    this.businessPhone = '',
    this.businessEmail = '',
    required this.typeOrder,
    required this.invoiceNumber,
    required this.date,
    required this.hora,
    this.cashier = '',
    this.customerName = '',
    this.customerAddress = '',
    required this.items,
    required this.total,
    required this.recibido,
    required this.metodoPago,
    this.currencySymbol = 'L. ',
    this.notes = '',
    this.cai = '',
    this.rangoAutorizado = '',
    this.fechaLimite = '',
    this.rtnCliente = '',
    this.isv = 0.0,
    this.subtotal = 0.0,
    this.totalInWords = '',
  });
}

class InvoiceItem {
  final String description;
  final int quantity;
  final double unitPrice;
  final double discount;
  final double total;
  final double isvPercent;

  InvoiceItem({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    this.discount = 0.0,
    this.isvPercent = 0.0,
  }) : total = (quantity * unitPrice) - discount;
}

class ThermalInvoicePreview extends StatelessWidget {
  final InvoiceData data;
  final double paperWidthMm;

  const ThermalInvoicePreview({
    Key? key,
    required this.data,
    this.paperWidthMm = 80,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Factura',
          style: TextStyle(
            color: Provider.of<TemaProveedor>(context).esModoOscuro
                ? Colors.white
                : Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Provider.of<TemaProveedor>(context).esModoOscuro
            ? Colors.black
            : const Color.fromRGBO(244, 243, 243, 1),
        iconTheme: IconThemeData(
          color: Provider.of<TemaProveedor>(context).esModoOscuro
              ? Colors.white
              : Colors.black,
        ),
      ),
      body: FutureBuilder<Uint8List>(
        future: ThermalInvoicePrinter(
          data: data,
        ).generatePdf(paperWidthMm: paperWidthMm),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          return PdfPreview(
            build: (format) => snapshot.data!,
            allowPrinting: true,
            allowSharing: true,
            canChangeOrientation: false,
            canChangePageFormat: false,
            initialPageFormat: PdfPageFormat(
              paperWidthMm * 2.8346,
              1000,
              marginAll: 0,
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.print),
        onPressed: () async {
          final pdf = await ThermalInvoicePrinter(
            data: data,
          ).generatePdf(paperWidthMm: paperWidthMm);
          await Printing.layoutPdf(
            onLayout: (format) => pdf,
            name: 'factura_${data.invoiceNumber}.pdf',
          );
        },
      ),
    );
  }
}
