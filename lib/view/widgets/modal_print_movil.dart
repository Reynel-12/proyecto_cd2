import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:proyecto_cd2/model/preferences.dart';

class EnhancedConfirmationModalPrintMovil {
  static Future show({
    required BuildContext context,
    required String title,
    String? subtitle,
    String confirmText = 'Confirmar',
    String cancelText = 'Cancelar',
    IconData icon = Icons.print,
    Color? accentColor,
    bool isProcessing = false,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool enableHapticFeedback = true,
    bool showCloseButton = true,
  }) async {
    // Proporcionar retroalimentación táctil
    if (enableHapticFeedback) {
      HapticFeedback.mediumImpact();
    }

    // Color de acento predeterminado
    final Color primaryAccentColor = accentColor ?? Colors.blueAccent;

    return await showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (BuildContext context) {
        // Obtener el tema actual
        final isDarkMode = Provider.of<TemaProveedor>(context).esModoOscuro;

        // Obtener dimensiones de la pantalla
        final screenSize = MediaQuery.of(context).size;
        final bool isMobile = screenSize.width < 600;
        final bool isTablet = screenSize.width >= 600 && screenSize.width < 900;
        final bool isDesktop = screenSize.width >= 900;

        // Ajustar tamaños según el dispositivo
        final double modalWidth = isMobile
            ? screenSize.width * 0.9
            : (isTablet ? 450.0 : 500.0);
        final double? modalHeight = isMobile
            ? null // Auto height en móvil
            : (isTablet ? 320.0 : 360.0);
        final double modalPadding = isMobile ? 20.0 : 24.0;
        final double iconSize = isMobile ? 48.0 : (isDesktop ? 72.0 : 64.0);
        final double titleFontSize = isMobile
            ? 18.0
            : (isDesktop ? 24.0 : 22.0);
        final double subtitleFontSize = isMobile
            ? 14.0
            : (isDesktop ? 16.0 : 15.0);
        final double buttonHeight = isMobile ? 48.0 : (isDesktop ? 56.0 : 52.0);
        final double buttonFontSize = isMobile
            ? 15.0
            : (isDesktop ? 16.0 : 15.0);
        final double borderRadius = isMobile ? 16.0 : 20.0;

        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: modalWidth,
              height: modalHeight,
              constraints: BoxConstraints(
                maxWidth: 500,
                maxHeight: screenSize.height * 0.8,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(borderRadius),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Color.fromRGBO(40, 40, 50, 0.95)
                          : Color.fromRGBO(250, 250, 255, 0.95),
                      borderRadius: BorderRadius.circular(borderRadius),
                      border: Border.all(
                        color: isDarkMode
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.05),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Barra superior con botón de cerrar
                        if (showCloseButton)
                          Align(
                            alignment: Alignment.topRight,
                            child: Padding(
                              padding: EdgeInsets.only(top: 12, right: 12),
                              child: GestureDetector(
                                onTap: isProcessing
                                    ? null
                                    : () {
                                        if (onCancel != null)
                                          Navigator.of(context).pop(false);
                                      },
                                child: Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isDarkMode
                                        ? Colors.grey.withOpacity(0.2)
                                        : Colors.grey.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.close,
                                    size: 20,
                                    color: isProcessing
                                        ? (isDarkMode
                                              ? Colors.white.withOpacity(0.3)
                                              : Colors.black.withOpacity(0.3))
                                        : (isDarkMode
                                              ? Colors.white.withOpacity(0.8)
                                              : Colors.black54),
                                  ),
                                ),
                              ),
                            ),
                          ),

                        // Contenido principal
                        Flexible(
                          child: SingleChildScrollView(
                            physics: BouncingScrollPhysics(),
                            child: Padding(
                              padding: EdgeInsets.all(modalPadding),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(height: showCloseButton ? 0 : 16),

                                  // Icono animado
                                  TweenAnimationBuilder<double>(
                                    duration: Duration(milliseconds: 400),
                                    curve: Curves.easeOutBack,
                                    tween: Tween<double>(begin: 0.5, end: 1.0),
                                    builder: (context, value, child) {
                                      return Transform.scale(
                                        scale: value,
                                        child: Container(
                                          width: iconSize,
                                          height: iconSize,
                                          decoration: BoxDecoration(
                                            color: primaryAccentColor
                                                .withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            icon,
                                            size: iconSize * 0.6,
                                            color: primaryAccentColor,
                                          ),
                                        ),
                                      );
                                    },
                                  ),

                                  SizedBox(height: modalPadding * 0.8),

                                  // Título con animación
                                  TweenAnimationBuilder<double>(
                                    duration: Duration(milliseconds: 400),
                                    curve: Curves.easeOut,
                                    tween: Tween<double>(begin: 0.0, end: 1.0),
                                    builder: (context, value, child) {
                                      return Opacity(
                                        opacity: value,
                                        child: Transform.translate(
                                          offset: Offset(0, 20 * (1 - value)),
                                          child: Text(
                                            title,
                                            style: TextStyle(
                                              fontSize: titleFontSize,
                                              fontWeight: FontWeight.bold,
                                              color: isDarkMode
                                                  ? Colors.white
                                                  : Colors.black.withOpacity(
                                                      0.8,
                                                    ),
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      );
                                    },
                                  ),

                                  // Subtítulo (opcional)
                                  if (subtitle != null) ...[
                                    SizedBox(height: 8),
                                    TweenAnimationBuilder<double>(
                                      duration: Duration(milliseconds: 400),
                                      curve: Curves.easeOut,
                                      tween: Tween<double>(
                                        begin: 0.0,
                                        end: 1.0,
                                      ),
                                      builder: (context, value, child) {
                                        return Opacity(
                                          opacity: value,
                                          child: Transform.translate(
                                            offset: Offset(0, 20 * (1 - value)),
                                            child: Text(
                                              subtitle,
                                              style: TextStyle(
                                                fontSize: subtitleFontSize,
                                                color: isDarkMode
                                                    ? Colors.white.withOpacity(
                                                        0.7,
                                                      )
                                                    : Colors.black.withOpacity(
                                                        0.6,
                                                      ),
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],

                                  SizedBox(height: modalPadding),

                                  // Botones de acción
                                  TweenAnimationBuilder<double>(
                                    duration: Duration(milliseconds: 500),
                                    curve: Curves.easeOut,
                                    tween: Tween<double>(begin: 0.0, end: 1.0),
                                    builder: (context, value, child) {
                                      return Opacity(
                                        opacity: value,
                                        child: Transform.translate(
                                          offset: Offset(0, 20 * (1 - value)),
                                          child: isMobile
                                              ? _buildVerticalButtons(
                                                  context,
                                                  isDarkMode,
                                                  primaryAccentColor,
                                                  buttonHeight,
                                                  buttonFontSize,
                                                  cancelText,
                                                  confirmText,
                                                  isProcessing,
                                                  onCancel,
                                                  onConfirm,
                                                )
                                              : _buildHorizontalButtons(
                                                  context,
                                                  isDarkMode,
                                                  primaryAccentColor,
                                                  buttonHeight,
                                                  buttonFontSize,
                                                  cancelText,
                                                  confirmText,
                                                  isProcessing,
                                                  onCancel,
                                                  onConfirm,
                                                ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Botones en disposición vertical para móviles
  static Widget _buildVerticalButtons(
    BuildContext context,
    bool isDarkMode,
    Color primaryColor,
    double height,
    double fontSize,
    String cancelText,
    String confirmText,
    bool isProcessing,
    VoidCallback? onCancel,
    VoidCallback? onConfirm,
  ) {
    return Column(
      children: [
        // Botón de confirmar
        SizedBox(
          width: double.infinity,
          height: height,
          child: ElevatedButton(
            onPressed: isProcessing
                ? null
                : () {
                    if (onConfirm != null) onConfirm();
                    Navigator.of(context).pop(true);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(height / 4),
              ),
              padding: EdgeInsets.symmetric(vertical: 12),
              disabledBackgroundColor: primaryColor.withOpacity(0.6),
            ),
            child: isProcessing
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    confirmText,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),

        SizedBox(height: 12),

        // Botón de cancelar
        SizedBox(
          width: double.infinity,
          height: height,
          child: TextButton(
            onPressed: isProcessing
                ? null
                : () {
                    if (onCancel != null) onCancel();
                    Navigator.of(context).pop(false);
                  },
            style: TextButton.styleFrom(
              foregroundColor: isDarkMode ? Colors.white70 : Colors.black54,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(height / 4),
                side: BorderSide(
                  color: isDarkMode
                      ? Colors.white.withOpacity(0.2)
                      : Colors.black.withOpacity(0.1),
                  width: 1,
                ),
              ),
              padding: EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text(
              cancelText,
              style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ],
    );
  }

  // Botones en disposición horizontal para tablets y desktop
  static Widget _buildHorizontalButtons(
    BuildContext context,
    bool isDarkMode,
    Color primaryColor,
    double height,
    double fontSize,
    String cancelText,
    String confirmText,
    bool isProcessing,
    VoidCallback? onCancel,
    VoidCallback? onConfirm,
  ) {
    return Row(
      children: [
        // Botón de cancelar
        Expanded(
          child: SizedBox(
            height: height,
            child: TextButton(
              onPressed: isProcessing
                  ? null
                  : () {
                      if (onCancel != null) onCancel();
                      Navigator.of(context).pop(false);
                    },
              style: TextButton.styleFrom(
                foregroundColor: isDarkMode ? Colors.white70 : Colors.black54,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(height / 4),
                  side: BorderSide(
                    color: isDarkMode
                        ? Colors.white.withOpacity(0.2)
                        : Colors.black.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                cancelText,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),

        SizedBox(width: 16),

        // Botón de confirmar
        Expanded(
          child: SizedBox(
            height: height,
            child: ElevatedButton(
              onPressed: isProcessing
                  ? null
                  : () {
                      if (onConfirm != null) onConfirm();
                      Navigator.of(context).pop(true);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(height / 4),
                ),
                padding: EdgeInsets.symmetric(vertical: 12),
                disabledBackgroundColor: primaryColor.withOpacity(0.6),
              ),
              child: isProcessing
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      confirmText,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

// Ejemplo de uso:
void mostrarConfirmacionImprimir(
  BuildContext context,
  String nombre,
  String codigo,
  bool isProcessing,
  Function(String) finalizarVenta,
) {
  EnhancedConfirmationModalPrintMovil.show(
    context: context,
    title: '¿Deseas imprimir factura?',
    confirmText: 'Confirmar',
    cancelText: 'Cancelar',
    icon: Icons.credit_score,
    accentColor: Colors.blueAccent,
    isProcessing: isProcessing,
    onConfirm: () {
      if (!isProcessing) {
        finalizarVenta(codigo);
        Navigator.of(context).pop(true);
      }
    },
  );
}
