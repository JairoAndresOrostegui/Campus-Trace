import 'package:cloud_firestore/cloud_firestore.dart';

class ThemeConfig {
  final String nombre;
  final String logoUrl;
  final String colorFondo;
  final String colorTextoTitulo;
  final String colorLabel;
  final String fuenteGeneral;
  final String fuenteTitulos;

  ThemeConfig({
    required this.nombre,
    required this.logoUrl,
    required this.colorFondo,
    required this.colorTextoTitulo,
    required this.colorLabel,
    required this.fuenteGeneral,
    required this.fuenteTitulos,
  });

  factory ThemeConfig.fromMap(Map<String, dynamic> map) {
    return ThemeConfig(
      nombre: map['nombre'] ?? 'Universidad de Investigación y Desarrollo',
      logoUrl: map['logoUrl'] ?? '',
      colorFondo: map['colorFondo'] ?? '#FFFFFF',
      colorTextoTitulo: map['colorTextoTitulo'] ?? '#003A8C',
      colorLabel: map['colorLabel'] ?? '#2457A7',
      fuenteGeneral: map['fuenteGeneral'] ?? 'Urbanist',
      fuenteTitulos: map['fuenteTitulos'] ?? 'Paytone One',
    );
  }
}

class ThemeProvider {
  static ThemeConfig? config;

  static Future<void> cargarConfiguracion(String docId) async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('configuracion_estilos')
            .doc(docId)
            .get();

    if (snapshot.exists) {
      config = ThemeConfig.fromMap(snapshot.data()!);
    } else {
      throw Exception('No se encontró la configuración del colegio');
    }
  }
}
