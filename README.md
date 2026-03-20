# Proyecto CD2 - Sistema Inteligente de Ventas e Inventario

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)
![SQLite](https://img.shields.io/badge/sqlite-%2307405e.svg?style=for-the-badge&logo=sqlite&logoColor=white)
![Python](https://img.shields.io/badge/python-3670A0?style=for-the-badge&logo=python&logoColor=ffdd54)

Proyecto CD2 es un sistema integral de **Punto de Venta (POS) e Inventario** desarrollado con Flutter (Desktop/Mobile). Destaca por la integración de una API en Python que utiliza Machine Learning para realizar predicciones de **Inventario Óptimo**, mejorando la toma de decisiones en el abastecimiento de productos.

## 🚀 Características Principales

* **📦 Gestión de Inventario Inteligente:** Integración con API de Machine Learning (Python) para calcular el "Inventario Óptimo" basado en historial de ventas, stock actual y métricas de error (MAE).
* **🔐 Roles y Permisos Granulares:** Sistema de seguridad basado en permisos modulares. Los administradores pueden otorgar o denegar acceso a módulos específicos (Ventas, Inventario, Usuarios, etc.) para cada perfil.
* **📊 Exportación para Inteligencia de Negocios (BI):** Generación y exportación de datos (Ventas, Proveedores, Productos) en formato CSV, listos para procesos ETL y análisis en dashboards de herramientas como Power BI.

## 🛠️ Tecnologías Utilizadas

* **Frontend:** Flutter & Dart
* **Gestión de Estado:** Provider
* **Base de Datos Local:** SQLite (`sqflite` / `sqflite_common_ffi` para Desktop)
* **Backend de Predicciones (Local API):** Python (Flask/FastAPI, Scikit-learn, Pandas)
* **Otras Librerías:** `http`, `shared_preferences`, `csv`, `awesome_dialog`.

## 📋 Requisitos Previos

Asegúrate de tener instalado lo siguiente en tu entorno de desarrollo:

1. [Flutter SDK](https://docs.flutter.dev/get-started/install) (versión 3.10.1 o superior recomendada).
2. [Dart SDK](https://dart.dev/get-dart) (se incluye con Flutter).
3. [Python 3.8+](https://www.python.org/downloads/) (Requerido para ejecutar la API local de Machine Learning).
4. Un IDE como [VS Code](https://code.visualstudio.com/) o [Android Studio](https://developer.android.com/studio).

## ⚙️ Instalación y Ejecución

Sigue estos pasos para ejecutar el proyecto en tu máquina local:

### 1. Clonar el repositorio

```bash
git clone https://github.com/tu-usuario/proyecto_cd2.git
cd proyecto_cd2
```

### 2. Instalar dependencias de Flutter

Ejecuta el siguiente comando para descargar los paquetes necesarios especificados en `pubspec.yaml`:

```bash
flutter pub get
```

### 3. Configurar y Ejecutar la API de Python (Inventario Óptimo)

El sistema requiere que la API de Machine Learning esté corriendo localmente para calcular el inventario óptimo. _(Asegúrate de revisar la documentación específica dentro de la carpeta de la API, usualmente llamada `api` o `python_api`)_.

```bash
# Navega a la carpeta de la API
# cd ruta/a/tu/api_python

# Instala los requerimientos de Python
pip install -r requirements.txt

# Ejecuta el servidor local de la API (Ejemplo si es api.py)
python api.py
```

### 4. Ejecutar la Aplicación Flutter

Una vez que la API de Python esté corriendo, abre otra terminal en la raíz del proyecto Flutter y ejecuta:

```bash
# Para ejecutar en Windows (o tu emulador predeterminado):
flutter run -d windows
```

## 📁 Estructura del Proyecto

El código fuente sigue un patrón de arquitectura MVC/MVVM aproximado, organizado principalmente en la carpeta `lib/`:

* `lib/view/`: Contiene todas las pantallas y la interfaz de usuario (ej. `principal.dart`, `ventasView.dart`, `inventario_optimo.dart`).
* `lib/model/`: Define las estructuras de datos y entidades del negocio (ej. `inventario_optimo.dart`, cajas, ventas, usuarios).
* `lib/controller/` (o repositories): Contiene la lógica de negocio, consultas a SQLite, y llamadas HTTP a la API de Python (ej. `repository_inventario_optimo.dart`).
