import 'package:flutter/material.dart';
import 'package:proyecto_cd2/model/preferences.dart';
import 'package:provider/provider.dart';

class DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const DashboardCard({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double iconSize = constraints.maxWidth * 0.15;
        double fontSize = constraints.maxWidth * 0.05;

        iconSize = iconSize.clamp(24.0, 60.0);
        fontSize = fontSize.clamp(12.0, 24.0);

        return GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.0),
              color: Provider.of<TemaProveedor>(context).esModoOscuro
                  ? Color.fromRGBO(30, 30, 30, 1)
                  : Colors.white,
            ),
            margin: const EdgeInsets.all(4.0),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    switchInCurve: Curves.easeIn,
                    switchOutCurve: Curves.easeOut,
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(scale: animation, child: child);
                    },
                    child: Icon(
                      icon,
                      key: ValueKey<bool>(
                        Provider.of<TemaProveedor>(context).esModoOscuro,
                      ),
                      size: iconSize,
                      color: Provider.of<TemaProveedor>(context).esModoOscuro
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                      color: Provider.of<TemaProveedor>(context).esModoOscuro
                          ? Colors.white
                          : Colors.black,
                    ),
                    child: Text(title, textAlign: TextAlign.center),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class DashboardGrid extends StatelessWidget {
  final List<DashboardCardData> cards;

  const DashboardGrid({super.key, required this.cards});

  @override
  Widget build(BuildContext context) {
    // Obtenemos el tamaño de la pantalla
    final screenSize = MediaQuery.of(context).size;

    // Determinamos el número de columnas según el ancho de la pantalla
    int crossAxisCount;
    if (screenSize.width < 600) {
      // Móvil: 2 columnas
      crossAxisCount = 2;
    } else if (screenSize.width < 900) {
      // Tablet: 3 columnas
      crossAxisCount = 3;
    } else if (screenSize.width < 1200) {
      // Desktop pequeño: 4 columnas
      crossAxisCount = 4;
    } else {
      // Desktop grande: 5 columnas
      crossAxisCount = 5;
    }

    // Calculamos el aspect ratio para mantener proporciones adecuadas
    final double childAspectRatio = screenSize.width < 600 ? 1.0 : 1.2;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GridView.builder(
        physics: const BouncingScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio,
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
        ),
        itemCount: cards.length,
        itemBuilder: (context, index) {
          return DashboardCard(
            icon: cards[index].icon,
            title: cards[index].title,
            onTap: cards[index].onTap,
          );
        },
      ),
    );
  }
}

// Clase para almacenar los datos de cada tarjeta
class DashboardCardData {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  DashboardCardData({
    required this.icon,
    required this.title,
    required this.onTap,
  });
}
