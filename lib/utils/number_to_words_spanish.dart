class NumberToWordsSpanish {
  static const List<String> _unidades = [
    '',
    'UN',
    'DOS',
    'TRES',
    'CUATRO',
    'CINCO',
    'SEIS',
    'SIETE',
    'OCHO',
    'NUEVE',
  ];
  static const List<String> _decenas = [
    'DIEZ',
    'ONCE',
    'DOCE',
    'TRECE',
    'CATORCE',
    'QUINCE',
    'DIECISEIS',
    'DIECISIETE',
    'DIECIOCHO',
    'DIECINUEVE',
  ];
  static const List<String> _decenasPuras = [
    '',
    'DIEZ',
    'VEINTE',
    'TREINTA',
    'CUARENTA',
    'CINCUENTA',
    'SESENTA',
    'SETENTA',
    'OCHENTA',
    'NOVENTA',
  ];
  static const List<String> _centenas = [
    '',
    'CIENTO',
    'DOSCIENTOS',
    'TRESCIENTOS',
    'CUATROCIENTOS',
    'QUINIENTOS',
    'SEISCIENTOS',
    'SETECIENTOS',
    'OCHOCIENTOS',
    'NOVECIENTOS',
  ];

  static String convert(double number) {
    if (number == 0) return 'CERO LEMPIRAS CON 00 CENTAVOS';

    int entero = number.floor();
    int centavos = ((number - entero) * 100).round();

    String resultado = _convertirGrupo(entero);

    // Ajuste para "UN" -> "UN" (ya está) pero si es 1 solo, a veces se dice "UNO"
    // En facturas se usa "UN LEMPIRA" o "UN MILLON"

    String moneda = entero == 1 ? 'LEMPIRA' : 'LEMPIRAS';
    String centavosStr = centavos.toString().padLeft(2, '0');

    return 'SON: $resultado $moneda CON $centavosStr CENTAVOS';
  }

  static String _convertirGrupo(int n) {
    if (n == 0) return '';
    if (n < 10) return _unidades[n];
    if (n < 20) return _decenas[n - 10];
    if (n < 30) {
      if (n == 20) return 'VEINTE';
      return 'VEINTI${_unidades[n - 20]}';
    }
    if (n < 100) {
      int d = n ~/ 10;
      int u = n % 10;
      if (u == 0) return _decenasPuras[d];
      return '${_decenasPuras[d]} Y ${_unidades[u]}';
    }
    if (n < 1000) {
      if (n == 100) return 'CIEN';
      int c = n ~/ 100;
      int resto = n % 100;
      if (resto == 0) return _centenas[c];
      return '${_centenas[c]} ${_convertirGrupo(resto)}';
    }
    if (n < 1000000) {
      int miles = n ~/ 1000;
      int resto = n % 1000;
      String milesStr = '';
      if (miles == 1) {
        milesStr = 'MIL';
      } else {
        milesStr = '${_convertirGrupo(miles)} MIL';
      }
      if (resto == 0) return milesStr;
      return '$milesStr ${_convertirGrupo(resto)}';
    }
    if (n < 1000000000) {
      int millones = n ~/ 1000000;
      int resto = n % 1000000;
      String millonesStr = '';
      if (millones == 1) {
        millonesStr = 'UN MILLON';
      } else {
        millonesStr = '${_convertirGrupo(millones)} MILLONES';
      }
      if (resto == 0) return millonesStr;
      return '$millonesStr ${_convertirGrupo(resto)}';
    }
    return 'NUMERO DEMASIADO GRANDE';
  }
}
