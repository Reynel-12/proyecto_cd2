import 'package:proyecto_cd2/controller/repository_categoria.dart';
import 'package:proyecto_cd2/model/categorias.dart';
import 'package:proyecto_cd2/view/categorias_form.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:proyecto_cd2/controller/repository_producto.dart';
import 'package:proyecto_cd2/model/app_logger.dart';
import 'package:proyecto_cd2/model/preferences.dart';
import 'package:proyecto_cd2/model/producto.dart';
import 'package:proyecto_cd2/view/widgets/loading.dart';
import 'package:proyecto_cd2/view/widgets/inventario_vacio.dart';

class CategoriaDetails extends StatefulWidget {
  final Categorias categoria;

  const CategoriaDetails({super.key, required this.categoria});

  @override
  State<CategoriaDetails> createState() => _CategoriaDetailsState();
}

class _CategoriaDetailsState extends State<CategoriaDetails> {
  final _productoRepository = ProductoRepository();
  final _categoriaRepository = RepositoryCategoria();
  final AppLogger _logger = AppLogger.instance;
  List<Producto> _productos = [];
  bool _isLoading = true;
  late Categorias _currentCategoria;

  @override
  void initState() {
    super.initState();
    _currentCategoria = widget.categoria;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final productos = await _productoRepository.getProductosByCategoria(
        _currentCategoria.idCategoria!,
      );
      // Refresh provider data in case it was edited
      final updatedProveedorList = await _categoriaRepository.getCategoriaById(
        _currentCategoria.idCategoria!,
      );

      if (mounted) {
        setState(() {
          _productos = productos;
          if (updatedProveedorList.isNotEmpty) {
            _currentCategoria = updatedProveedorList.first;
          }
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al cargar datos: $e')));
      }
      _logger.log.e('Error al cargar datos', error: e, stackTrace: stackTrace);
    }
  }

  void _navigateToEdit() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NuevaCategoria(
          isEdit: true,
          isEditNombre: true,
          isEditDescripcion: true,
          isEditEstado: true,
          codigo: _currentCategoria.idCategoria!,
          nombre: _currentCategoria.nombre!,
          descripcion: _currentCategoria.descripcion!,
          estado: _currentCategoria.estado!,
          fechaCreacion: _currentCategoria.fechaCreacion!,
          fechaActualizacion: _currentCategoria.fechaActualizacion!,
        ),
      ),
    ).then((value) {
      if (value == true) {
        _loadData();
      }
    });
  }

  void _confirmDelete() {
    // Obtenemos el tamaño de la pantalla
    final screenSize = MediaQuery.of(context).size;
    final bool isTablet = screenSize.width >= 600 && screenSize.width < 900;
    final bool isDesktop = screenSize.width >= 900;

    // Calculamos el ancho del awesomeDialog según el tamaño de pantalla
    final double dialogWidth = isDesktop
        ? screenSize.width * 0.3
        : (isTablet ? screenSize.width * 0.5 : screenSize.width * 0.8);
    AwesomeDialog(
      width: isDesktop ? (screenSize.width - dialogWidth) / 2 : null,
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.scale,
      title: 'Eliminar categoria',
      desc:
          '¿Está seguro que desea eliminar a ${_currentCategoria.nombre}? Esta acción no se puede deshacer.',
      btnCancelText: 'No, cancelar',
      btnOkText: 'Sí, eliminar',
      btnCancelOnPress: () {},
      btnOkOnPress: () async {
        try {
          await _categoriaRepository.deleteCategoria(
            _currentCategoria.idCategoria!,
          );
          if (mounted) {
            Navigator.pop(context, true); // Return true to refresh list
          }
        } catch (e, stackTrace) {
          _logger.log.e(
            'Error al eliminar categoria',
            error: e,
            stackTrace: stackTrace,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar categoria: $e')),
          );
        }
      },
      dialogBackgroundColor:
          Provider.of<TemaProveedor>(context, listen: false).esModoOscuro
          ? Color.fromRGBO(60, 60, 60, 1)
          : Color.fromRGBO(220, 220, 220, 1),
    ).show();
  }

  // Método para crear elementos del menú popup de manera más limpia
  PopupMenuItem _buildPopupMenuItem(String value, IconData icon, String text) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            color:
                Provider.of<TemaProveedor>(context, listen: false).esModoOscuro
                ? Colors.white
                : Colors.black,
            size: isMobile ? 20.0 : 22.0,
          ),
          SizedBox(width: isMobile ? 6.0 : 8.0),
          Text(text, style: TextStyle(fontSize: isMobile ? 14.0 : 16.0)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 600;
    final isDesktop = screenSize.width >= 900;
    final theme = Provider.of<TemaProveedor>(context);
    final isDark = theme.esModoOscuro;

    return Scaffold(
      backgroundColor: isDark
          ? Colors.black
          : const Color.fromRGBO(244, 243, 243, 1),
      appBar: AppBar(
        title: Text(
          'Detalles de la categoria',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: isDark
            ? Colors.black
            : const Color.fromRGBO(244, 243, 243, 1),
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context, true);
          },
          icon: Icon(Icons.arrow_back),
        ),
        actions: [
          _isLoading
              ? Container()
              : PopupMenuButton(
                  color: Provider.of<TemaProveedor>(context).esModoOscuro
                      ? const Color.fromRGBO(30, 30, 30, 1)
                      : const Color.fromRGBO(244, 243, 243, 1),
                  icon: Icon(
                    Icons.more_vert,
                    color: Provider.of<TemaProveedor>(context).esModoOscuro
                        ? Colors.white
                        : Colors.black,
                    size: isMobile ? 22.0 : 24.0,
                  ),
                  onSelected: (value) {
                    if (value == 'edit') _navigateToEdit();
                    if (value == 'delete') _confirmDelete();
                  },
                  itemBuilder: (context) => [
                    _buildPopupMenuItem('edit', Icons.edit, 'Editar categoria'),
                    _buildPopupMenuItem(
                      'delete',
                      Icons.delete,
                      'Eliminar categoria',
                    ),
                  ],
                ),
        ],
      ),
      body: _isLoading
          ? const CargandoInventario()
          : isDesktop
          ? _buildDesktopLayout(isDark)
          : _buildMobileLayout(isDark),
    );
  }

  Widget _buildMobileLayout(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(isDark),
          const SizedBox(height: 24),
          _buildInfoSection(isDark),
          const SizedBox(height: 24),
          Text(
            'Productos asociados',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          _buildProductsList(isDark),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 1,
            child: Column(
              children: [
                _buildHeader(isDark),
                const SizedBox(height: 24),
                _buildInfoSection(isDark),
              ],
            ),
          ),
          const SizedBox(width: 32),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Productos asociados',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(child: _buildProductsList(isDark)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.blueAccent,
            child: Text(
              _currentCategoria.nombre!.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                fontSize: 40,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _currentCategoria.nombre!,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _currentCategoria.estado == 'Activo'
                  ? Colors.green.withOpacity(0.2)
                  : Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _currentCategoria.estado ?? 'Desconocido',
              style: TextStyle(
                color: _currentCategoria.estado == 'Activo'
                    ? Colors.green
                    : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(bool isDark) {
    return Card(
      color: isDark ? const Color.fromRGBO(30, 30, 30, 1) : Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildInfoRow(
              Icons.description,
              'Descripción',
              _currentCategoria.descripcion ?? 'No registrada',
              isDark,
            ),
            const Divider(),
            _buildInfoRow(
              Icons.calendar_today,
              'Fecha de registro',
              DateFormat('dd/MM/yyyy HH:mm:ss').format(
                DateTime.parse(
                  _currentCategoria.fechaCreacion ??
                      DateTime.now().toIso8601String(),
                ),
              ),
              isDark,
            ),
            const Divider(),
            _buildInfoRow(
              Icons.calendar_today,
              'Fecha de actualización',
              DateFormat('dd/MM/yyyy HH:mm:ss').format(
                DateTime.parse(
                  _currentCategoria.fechaActualizacion ??
                      DateTime.now().toIso8601String(),
                ),
              ),
              isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blueAccent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList(bool isDark) {
    if (_productos.isEmpty) {
      return const Center(child: InventarioVacio());
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _productos.length,
      itemBuilder: (context, index) {
        final producto = _productos[index];
        return Card(
          color: isDark ? const Color.fromRGBO(30, 30, 30, 1) : Colors.white,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blueAccent.withOpacity(0.2),
              child: const Icon(
                Icons.inventory_2,
                color: Colors.blueAccent,
                size: 20,
              ),
            ),
            title: Text(
              producto.nombre,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              'Stock: ${producto.stock} ${producto.unidadMedida}',
              style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey),
            ),
            trailing: Text(
              'L. ${producto.precio.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        );
      },
    );
  }
}
