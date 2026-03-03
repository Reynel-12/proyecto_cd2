import 'package:proyecto_cd2/model/categorias.dart';
import 'package:proyecto_cd2/view/categoria_details.dart';
import 'package:proyecto_cd2/view/categorias_form.dart';
import 'package:proyecto_cd2/view/widgets/categoria_vacia.dart';
import 'package:diacritic/diacritic.dart';
import 'package:flutter/material.dart';
import 'package:proyecto_cd2/controller/repository_categoria.dart';
import 'package:proyecto_cd2/model/app_logger.dart';
import 'package:proyecto_cd2/model/preferences.dart';
import 'package:proyecto_cd2/view/widgets/loading.dart';
import 'package:provider/provider.dart';

class CategoriasView extends StatefulWidget {
  const CategoriasView({super.key});

  @override
  State<CategoriasView> createState() => _CategoriasViewState();
}

class _CategoriasViewState extends State<CategoriasView> {
  TextEditingController searchController = TextEditingController();

  final repositoryCategoria = RepositoryCategoria();
  List<Categorias> _categorias = [];
  List<Categorias> _categoriasFiltrados = [];
  bool isLoading = true;
  final ScrollController _scrollController = ScrollController();
  final AppLogger _logger = AppLogger.instance;

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
  }

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  void cargarDatos() {
    try {
      setState(() {
        isLoading = true;
      });
      _categorias.clear();
      _categoriasFiltrados.clear();
      repositoryCategoria.getCategorias().then((categorias) {
        setState(() {
          _categorias = categorias;
          _categoriasFiltrados = categorias;
          isLoading = false;
        });
      });
    } catch (e, stackTrace) {
      _logger.log.e(
        'Error al obtener categorias',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  // Función para eliminar acentos y caracteres especiales
  String _normalizeString(String str) {
    return removeDiacritics(str.trim().toLowerCase());
  }

  void _filterProducts(String query) {
    String normalizedQuery = _normalizeString(query);

    setState(() {
      if (normalizedQuery.isEmpty) {
        _categoriasFiltrados =
            _categorias; // Mostrar todos los productos si no hay búsqueda
      } else {
        // Si no, filtramos por nombre o coincidencias parciales
        var proveedoresPorNombre = _categorias.where((proveedor) {
          String productName = _normalizeString(proveedor.nombre!);
          return productName.contains(
            normalizedQuery,
          ); // Coincidencia parcial por nombre
        }).toList();
        if (proveedoresPorNombre.isNotEmpty) {
          _categoriasFiltrados = proveedoresPorNombre;
        }
      }
    });
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

    return isLoading
        ? CargandoInventario()
        : Scaffold(
            backgroundColor: Provider.of<TemaProveedor>(context).esModoOscuro
                ? Colors.black
                : const Color.fromRGBO(244, 243, 243, 1),
            appBar: AppBar(
              title: Text(
                'Categorias',
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
              actions: [
                isLoading
                    ? Container()
                    : IconButton(
                        icon: Icon(
                          Icons.add,
                          color:
                              Provider.of<TemaProveedor>(context).esModoOscuro
                              ? Colors.white
                              : Colors.black,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NuevaCategoria(),
                            ),
                          ).then((value) {
                            if (value == true) {
                              cargarDatos();
                            }
                          });
                        },
                      ),
              ],
            ),
            body: _categoriasFiltrados.isEmpty
                ? const CategoriaVacia()
                : Padding(
                    padding: EdgeInsets.all(contentPadding),
                    child: Column(
                      children: [
                        // Campo de búsqueda responsivo
                        TextField(
                          controller: searchController,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor:
                                Provider.of<TemaProveedor>(context).esModoOscuro
                                ? const Color.fromRGBO(30, 30, 30, 1)
                                : Colors.white,
                            labelText: 'Buscar categoría',
                            labelStyle: TextStyle(
                              color:
                                  Provider.of<TemaProveedor>(
                                    context,
                                  ).esModoOscuro
                                  ? Colors.white
                                  : Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: isMobile ? 14.0 : 16.0,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color:
                                  Provider.of<TemaProveedor>(
                                    context,
                                  ).esModoOscuro
                                  ? Colors.white
                                  : Colors.black,
                              size: isMobile ? 20.0 : 22.0,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                isMobile ? 10 : 12,
                              ),
                              borderSide: BorderSide(
                                color:
                                    Provider.of<TemaProveedor>(
                                      context,
                                    ).esModoOscuro
                                    ? Colors.white
                                    : Colors.black,
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                isMobile ? 10 : 12,
                              ),
                              borderSide: BorderSide(
                                color:
                                    Provider.of<TemaProveedor>(
                                      context,
                                    ).esModoOscuro
                                    ? Colors.white
                                    : Colors.black,
                                width: 2.0,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                isMobile ? 10 : 12,
                              ),
                              borderSide: BorderSide(
                                color:
                                    Provider.of<TemaProveedor>(
                                      context,
                                    ).esModoOscuro
                                    ? Colors.white
                                    : Colors.black,
                                width: 1.0,
                              ),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              vertical: isMobile ? 12.0 : 16.0,
                              horizontal: isMobile ? 12.0 : 16.0,
                            ),
                          ),
                          style: TextStyle(
                            fontSize: isMobile ? 14.0 : 16.0,
                            color:
                                Provider.of<TemaProveedor>(context).esModoOscuro
                                ? Colors.white
                                : Colors.black,
                          ),
                          onChanged: (value) {
                            _filterProducts(value);
                          },
                        ),
                        SizedBox(height: isMobile ? 12.0 : 16.0),

                        // Lista de proveedores
                        Expanded(
                          child: isDesktop
                              ? _buildGridView(cardElevation)
                              : _buildListView(cardElevation),
                        ),
                      ],
                    ),
                  ),
            floatingActionButton: isLoading
                ? Container()
                : _categoriasFiltrados.isEmpty
                ? Container()
                : FloatingActionButton(
                    backgroundColor: Colors.blueAccent,
                    onPressed: () {
                      _scrollController.animateTo(
                        0,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOut,
                      );
                    },
                    child: const Icon(Icons.arrow_upward, color: Colors.white),
                  ),
          );
  }

  // Vista de lista para móvil y tablet
  Widget _buildListView(double elevation) {
    return ListView.builder(
      itemCount: _categoriasFiltrados.length, // Ejemplo con 5 proveedores
      controller: _scrollController,
      itemBuilder: (context, index) {
        final categoria = _categoriasFiltrados[index];
        return _cardCategoria(
          categoria.idCategoria!,
          categoria.nombre!,
          categoria.descripcion!,
          categoria.estado!,
          categoria.fechaActualizacion!,
          categoria.fechaCreacion!,
          elevation,
        );
      },
    );
  }

  // Vista de cuadrícula para escritorio
  Widget _buildGridView(double elevation) {
    // Obtenemos el tamaño de la pantalla
    final screenSize = MediaQuery.of(context).size;
    final bool isDesktop = screenSize.width >= 900 && screenSize.width < 1100;
    final bool isDesktopL = screenSize.width >= 1100;

    return GridView.builder(
      controller: _scrollController,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // 2 columnas en escritorio
        childAspectRatio: isDesktop
            ? 3.0
            : isDesktopL
            ? 4.0
            : 3.5, // Proporción ancho/alto
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
      ),
      itemCount: _categoriasFiltrados.length, // Ejemplo con 5 proveedores
      itemBuilder: (context, index) {
        final categoria = _categoriasFiltrados[index];
        return _cardCategoria(
          categoria.idCategoria!,
          categoria.nombre!,
          categoria.descripcion!,
          categoria.estado!,
          categoria.fechaActualizacion!,
          categoria.fechaCreacion!,
          elevation,
        );
      },
    );
  }

  Widget _cardCategoria(
    int id,
    String nombre,
    String descripcion,
    String estado,
    String fechaRegistro,
    String fechaActualizacion,
    double elevation,
  ) {
    // Obtenemos el tamaño de la pantalla
    final screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 600;
    final bool isTablet = screenSize.width >= 600 && screenSize.width < 900;

    // Ajustamos tamaños según el dispositivo
    final double titleFontSize = isMobile ? 16.0 : (isTablet ? 18.0 : 20.0);
    final double infoFontSize = isMobile ? 14.0 : (isTablet ? 15.0 : 16.0);
    final double iconSize = isMobile ? 24.0 : (isTablet ? 28.0 : 30.0);
    final double avatarRadius = isMobile ? 25.0 : (isTablet ? 28.0 : 30.0);
    final double cardPadding = isMobile ? 16.0 : (isTablet ? 18.0 : 20.0);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CategoriaDetails(
              categoria: Categorias(
                idCategoria: id,
                nombre: nombre,
                descripcion: descripcion,
                estado: estado,
                fechaActualizacion: fechaActualizacion,
                fechaCreacion: fechaRegistro,
              ),
            ),
          ),
        ).then((value) {
          if (value == true) {
            cargarDatos();
          }
        });
      },
      child: Card(
        color: Provider.of<TemaProveedor>(context).esModoOscuro
            ? const Color.fromRGBO(30, 30, 30, 1)
            : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isMobile ? 16.0 : 20.0),
        ),
        elevation: elevation,
        margin: EdgeInsets.symmetric(
          vertical: isMobile ? 8.0 : 10.0,
          horizontal: 0,
        ), // Sin margen horizontal en grid/list interna
        child: Padding(
          padding: EdgeInsets.all(cardPadding),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icono o avatar del proveedor
              CircleAvatar(
                backgroundColor: Colors.blueAccent,
                radius: avatarRadius,
                child: Icon(Icons.person, size: iconSize, color: Colors.white),
              ),
              SizedBox(width: isMobile ? 12.0 : 16.0),
              // Información del proveedor
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      nombre,
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.bold,
                        color: Provider.of<TemaProveedor>(context).esModoOscuro
                            ? Colors.white
                            : Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.0),
                    Row(
                      children: [
                        Icon(
                          Icons.description,
                          size: infoFontSize,
                          color: Colors.grey,
                        ),
                        SizedBox(width: 4.0),
                        Expanded(
                          child: Text(
                            descripcion,
                            style: TextStyle(
                              fontSize: infoFontSize,
                              color:
                                  Provider.of<TemaProveedor>(context).esModoOscuro
                                  ? Colors.white70
                                  : Colors.black87,
                              overflow: TextOverflow.ellipsis,
                            ),
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Flecha que indica más detalles
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.blueAccent,
                size: isMobile ? 16.0 : 20.0,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
