import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerView extends StatefulWidget {
  @override
  State<BarcodeScannerView> createState() => _BarcodeScannerViewState();
}

class _BarcodeScannerViewState extends State<BarcodeScannerView> {
  // 1. Controlador opcional (útil para encender el flash o cambiar la cámara)
  final MobileScannerController scannerController = MobileScannerController(
    // Configuración recomendada para mejor rendimiento y compatibilidad
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
    formats: [
      BarcodeFormat.all,
    ], // O selecciona solo los formatos que necesites
  );

  String _scanResult = 'Esperando código de barras...';
  bool _isProcessing = false;

  @override
  void dispose() {
    scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Obtenemos el tamaño de la pantalla
    final screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 600;
    final bool isTablet = screenSize.width >= 600 && screenSize.width < 900;

    // Ajustamos tamaños según el dispositivo
    final double titleFontSize = isMobile ? 18.0 : (isTablet ? 20.0 : 22.0);
    return Scaffold(
      appBar: AppBar(
        title: Text('Escáner', style: TextStyle(fontSize: titleFontSize)),
        actions: [
          // Control para el Flash (linterna)
          IconButton(
            color: Colors.white,
            icon: Icon(Icons.flash_on, color: Colors.white),
            iconSize: 32.0,
            onPressed: () => scannerController.toggleTorch(),
          ),
          // Control para cambiar de cámara (frontal/trasera)
          IconButton(
            color: Colors.white,
            icon: const Icon(Icons.flip_camera_ios),
            iconSize: 32.0,
            onPressed: () => scannerController.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 2. Widget de escaneo, que toma toda la pantalla
          MobileScanner(
            controller: scannerController,
            onDetect: (capture) async {
              // Prevenir el procesamiento múltiple
              if (_isProcessing) return;
              _isProcessing = true;

              final List<Barcode> barcodes = capture.barcodes;

              if (barcodes.isNotEmpty) {
                // Solo procesar el primer código detectado
                final String? rawValue = barcodes.first.rawValue;

                // Detener el escáner (opcional, pero recomendado)
                await scannerController.stop();

                setState(() {
                  _scanResult = 'Código Detectado: $rawValue';
                });

                // Aquí puedes navegar a otra pantalla o manejar el resultado
                Navigator.pop(context, rawValue);
              }
              // Reiniciar el procesamiento después de un pequeño retraso para evitar
              // que se detecten códigos repetidos demasiado rápido.
              await Future.delayed(const Duration(seconds: 1));
              _isProcessing = false;
            },
          ),

          // 3. Overlay con el resultado
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              color: Colors.black54,
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _scanResult,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
