import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proyecto_cd2/model/preferences.dart';

class DescuentoProductoDialog extends StatefulWidget {
  final double precioOriginal;
  final double descuentoActual;

  const DescuentoProductoDialog({
    Key? key,
    required this.precioOriginal,
    this.descuentoActual = 0.0,
  }) : super(key: key);

  @override
  _DescuentoProductoDialogState createState() =>
      _DescuentoProductoDialogState();
}

class _DescuentoProductoDialogState extends State<DescuentoProductoDialog> {
  late TextEditingController _customController;
  late double _currentDiscount;

  @override
  void initState() {
    super.initState();
    _currentDiscount = widget.descuentoActual;
    _customController = TextEditingController(
      text: _currentDiscount > 0 ? _currentDiscount.toStringAsFixed(0) : '',
    );
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  void _applyPreset(double percent) {
    setState(() {
      _currentDiscount = percent;
      _customController.text = percent.toStringAsFixed(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<TemaProveedor>(context).esModoOscuro;
    final primaryColor = Colors.blueAccent;
    final backgroundColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    final double discountAmount =
        widget.precioOriginal * (_currentDiscount / 100);
    final double finalPrice = widget.precioOriginal - discountAmount;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: backgroundColor,
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 450),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Aplicar Descuento',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: textColor),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Cerrar',
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Opciones de Descuento (Presets)
            Text(
              'Seleccionar porcentaje:',
              style: TextStyle(fontSize: 16, color: textColor.withOpacity(0.8)),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [25, 50, 75, 100].map((percent) {
                final isSelected = _currentDiscount == percent;
                return ChoiceChip(
                  label: Text(
                    '$percent%',
                    style: TextStyle(
                      color: isSelected ? Colors.white : textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: primaryColor,
                  backgroundColor: isDarkMode
                      ? Colors.grey[800]
                      : Colors.grey[200],
                  onSelected: (_) => _applyPreset(percent.toDouble()),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: isSelected ? primaryColor : Colors.transparent,
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // Entrada personalizada
            TextField(
              controller: _customController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                labelText: 'Personalizado (%)',
                labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                suffixText: '%',
                suffixStyle: TextStyle(color: textColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: textColor.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryColor, width: 2),
                ),
              ),
              onChanged: (value) {
                final val = double.tryParse(value);
                setState(() {
                  if (val != null && val >= 0 && val <= 100) {
                    _currentDiscount = val;
                  } else {
                    _currentDiscount = 0;
                  }
                });
              },
            ),

            const SizedBox(height: 24),
            Divider(color: textColor.withOpacity(0.2)),
            const SizedBox(height: 16),

            // Vista previa de cálculos
            _buildInfoRow(
              'Precio Original:',
              'L. ${widget.precioOriginal.toStringAsFixed(2)}',
              textColor,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Descuento (${_currentDiscount.toStringAsFixed(0)}%):',
              '- L. ${discountAmount.toStringAsFixed(2)}',
              Colors.redAccent,
              isBold: true,
            ),
            const SizedBox(height: 8),
            Divider(color: textColor.withOpacity(0.1)),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Precio Final:',
              'L. ${finalPrice.toStringAsFixed(2)}',
              Colors.green,
              isBold: true,
              fontSize: 18,
            ),

            const SizedBox(height: 30),

            // Botones de Acción
            Row(
              children: [
                // Botón Limpiar/Eliminar
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context, 0.0),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Eliminar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Botón Aplicar
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context, _currentDiscount),
                    icon: const Icon(Icons.check),
                    label: const Text('Aplicar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    Color color, {
    bool isBold = false,
    double fontSize = 16,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: color.withOpacity(0.8),
            fontSize: 15,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
