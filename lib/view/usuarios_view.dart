import 'package:diacritic/diacritic.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proyecto_cd2/controller/repository_user.dart';
import 'package:proyecto_cd2/model/app_logger.dart';
import 'package:proyecto_cd2/model/preferences.dart';
import 'package:proyecto_cd2/model/user.dart';
import 'package:proyecto_cd2/view/nuevo_usuario.dart';
import 'package:proyecto_cd2/view/perfil_usuario.dart';
import 'package:proyecto_cd2/view/widgets/loading.dart';
import 'package:proyecto_cd2/view/widgets/usuarios_vacios.dart';

class Usuarios extends StatefulWidget {
  const Usuarios({super.key});

  @override
  State<Usuarios> createState() => _UsuariosState();
}

class _UsuariosState extends State<Usuarios> {
  final repository = RepositoryUser();
  final AppLogger _logger = AppLogger.instance;
  TextEditingController searchController = TextEditingController();
  List<User> usuarioList = [];
  List<User> filteredUsuarios = [];
  late bool isLoading;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    searchController
        .dispose(); // Limpiar el controlador al salir de la pantalla
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _escucharDatos();
  }

  void _escucharDatos() {
    try {
      setState(() {
        isLoading = true;
      });
      repository.getAllUsers().then((value) {
        setState(() {
          usuarioList = value;
          usuarioList.sort((a, b) => a.nombre.compareTo(b.nombre));
          filteredUsuarios = usuarioList;
          isLoading = false;
        });
      });
    } catch (e, st) {
      _logger.log.e('Error al escuchar datos', error: e, stackTrace: st);
    }
  }

  // Función para eliminar acentos y caracteres especiales
  String _normalizeString(String str) {
    return removeDiacritics(str.trim().toLowerCase());
  }

  // Función mejorada para filtrar usuarios por nombre u otras propiedades
  void _filterClients(String query) {
    String normalizedQuery = _normalizeString(query);

    setState(() {
      if (normalizedQuery.isEmpty) {
        filteredUsuarios =
            usuarioList; // Mostrar todos los usuarios si no hay búsqueda
      } else {
        // Si no, filtramos por nombre o coincidencias parciales
        var usuarioPorNombre = usuarioList.where((product) {
          String userName = _normalizeString(product.nombre);
          return userName.contains(
            normalizedQuery,
          ); // Coincidencia parcial por nombre
        }).toList();
        if (usuarioPorNombre.isNotEmpty) {
          filteredUsuarios = usuarioPorNombre;
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
    final double cardElevation = isMobile ? 3.0 : 5.0;

    return Scaffold(
      backgroundColor: Provider.of<TemaProveedor>(context).esModoOscuro
          ? Colors.black
          : const Color.fromRGBO(244, 243, 243, 1),
      appBar: AppBar(
        title: Text(
          'Usuarios',
          style: TextStyle(
            color: Provider.of<TemaProveedor>(context).esModoOscuro
                ? Colors.white
                : Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: titleFontSize,
          ),
        ),
        iconTheme: IconThemeData(
          color: Provider.of<TemaProveedor>(context).esModoOscuro
              ? Colors.white
              : Colors.black,
        ),
        backgroundColor: Provider.of<TemaProveedor>(context).esModoOscuro
            ? Colors.black
            : const Color.fromRGBO(244, 243, 243, 1),
        centerTitle: true,
        actions: [
          isLoading
              ? Container()
              : IconButton(
                  icon: Icon(
                    Icons.add,
                    color: Provider.of<TemaProveedor>(context).esModoOscuro
                        ? Colors.white
                        : Colors.black,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => NuevoUsuario()),
                    ).then((value) {
                      if (value == true) {
                        _escucharDatos();
                      }
                    });
                  },
                ),
        ],
      ),
      body: isLoading
          ? CargandoInventario()
          : filteredUsuarios.isEmpty
          ? UsuariosVacios()
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor:
                            Provider.of<TemaProveedor>(context).esModoOscuro
                            ? const Color.fromRGBO(30, 30, 30, 1)
                            : Colors.white,
                        labelText: 'Buscar usuario',
                        labelStyle: TextStyle(
                          color:
                              Provider.of<TemaProveedor>(context).esModoOscuro
                              ? Colors.white
                              : Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: isMobile ? 14.0 : 16.0,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color:
                              Provider.of<TemaProveedor>(context).esModoOscuro
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
                                Provider.of<TemaProveedor>(context).esModoOscuro
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
                                Provider.of<TemaProveedor>(context).esModoOscuro
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
                                Provider.of<TemaProveedor>(context).esModoOscuro
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
                        color: Provider.of<TemaProveedor>(context).esModoOscuro
                            ? Colors.white
                            : Colors.black,
                      ),
                      onChanged: (value) {
                        _filterClients(
                          value,
                        ); // Llamar la función de filtro en cada cambio de texto
                      },
                    ),
                    SizedBox(height: isMobile ? 12.0 : 16.0),
                    // Lista de productos, ahora usando filteredProducts
                    Expanded(
                      child: isDesktop
                          ? _buildGridView(cardElevation)
                          : _buildListView(cardElevation),
                    ),
                  ],
                ),
              ),
            ),
      floatingActionButton: isLoading
          ? Container()
          : filteredUsuarios.isEmpty
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
      controller: _scrollController,
      itemCount: filteredUsuarios.length,
      itemBuilder: (context, index) {
        final clientes = filteredUsuarios[index];

        return cardClientes(
          clientes.id.toString(),
          clientes.nombre,
          clientes.apellido,
          elevation,
          clientes.correo,
          clientes.telefono,
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
            ? 2.5
            : isDesktopL
            ? 5
            : 3.5, // Proporción ancho/alto
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
      ),
      itemCount: filteredUsuarios.length,
      itemBuilder: (context, index) {
        final cliente = filteredUsuarios[index];

        return cardClientes(
          cliente.id.toString(),
          cliente.nombre,
          cliente.apellido,
          elevation,
          cliente.correo,
          cliente.telefono,
        );
      },
    );
  }

  Widget cardClientes(
    String uid,
    String nombre,
    String apellido,
    double elevation,
    String correo,
    String telefono,
  ) {
    // Obtenemos el tamaño de la pantalla
    final screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 600;
    final bool isTablet = screenSize.width >= 600 && screenSize.width < 900;

    // Ajustamos tamaños según el dispositivo
    final double titleFontSize = isMobile ? 16.0 : (isTablet ? 18.0 : 20.0);
    final double subtitleFontSize = isMobile ? 12.0 : (isTablet ? 13.0 : 14.0);
    final double iconSize = isMobile ? 24.0 : (isTablet ? 28.0 : 30.0);
    final double avatarRadius = isMobile ? 25.0 : (isTablet ? 28.0 : 30.0);
    final double cardPadding = isMobile ? 16.0 : (isTablet ? 18.0 : 20.0);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PerfilUsuario(docID: uid)),
        ).then((value) {
          if (value == true) {
            _escucharDatos();
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
          horizontal: isMobile ? 12.0 : 16.0,
        ),
        child: Ink(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: EdgeInsets.all(cardPadding),
            child: Row(
              children: [
                // Ícono de cliente o imagen avatar
                CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  radius: avatarRadius,
                  child: Icon(
                    Icons.person,
                    color: Colors.white,
                    size: iconSize,
                  ),
                ),
                SizedBox(width: isMobile ? 12.0 : 16.0),
                // Información del cliente
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$nombre $apellido',
                        style: TextStyle(
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.bold,
                          color:
                              Provider.of<TemaProveedor>(context).esModoOscuro
                              ? Colors.white
                              : Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: isMobile ? 2.0 : 4.0),
                      Text(
                        correo,
                        style: TextStyle(
                          fontSize: subtitleFontSize,
                          color:
                              Provider.of<TemaProveedor>(context).esModoOscuro
                              ? Color.fromRGBO(244, 243, 243, 1)
                              : Color.fromRGBO(30, 30, 30, 1),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: isMobile ? 2.0 : 4.0),
                      Text(
                        telefono,
                        style: TextStyle(
                          fontSize: subtitleFontSize,
                          color:
                              Provider.of<TemaProveedor>(context).esModoOscuro
                              ? Color.fromRGBO(244, 243, 243, 1)
                              : Color.fromRGBO(30, 30, 30, 1),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Flecha que indica más detalles
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.blueAccent, // Flecha con color suave
                  size: isMobile ? 16.0 : 20.0,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
