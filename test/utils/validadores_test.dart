import 'package:flutter_test/flutter_test.dart';
import 'package:studybuddy_ia/utils/validadores.dart';

void main() {
  group('validarNombreMateria', () {
    const mensajeVacio = 'Escribe el nombre de la materia.';

    test('rechaza nulo, vacío y solo espacios', () {
      expect(validarNombreMateria(null), mensajeVacio);
      expect(validarNombreMateria(''), mensajeVacio);
      expect(validarNombreMateria('   '), mensajeVacio);
    });

    test('acepta exactamente 60 caracteres', () {
      expect(validarNombreMateria('A' * 60), isNull);
    });

    test('rechaza 61 caracteres', () {
      expect(validarNombreMateria('A' * 61),
          'El nombre no puede pasar de 60 caracteres.');
    });

    test('ignora los espacios sobrantes al medir y al validar', () {
      expect(validarNombreMateria(' Redes '), isNull);
    });
  });

  group('validarTituloApunte', () {
    test('rechaza vacío', () {
      expect(validarTituloApunte(''), 'Escribe el título del apunte.');
    });

    test('rechaza 121 caracteres', () {
      expect(validarTituloApunte('T' * 121),
          'El título no puede pasar de 120 caracteres.');
    });

    test('acepta un título normal', () {
      expect(validarTituloApunte('DHCP'), isNull);
    });
  });

  group('validarTextoApunte', () {
    test('rechaza solo espacios', () {
      expect(validarTextoApunte('  '), 'Escribe el texto del apunte.');
    });

    test('acepta texto', () {
      expect(validarTextoApunte('texto'), isNull);
    });
  });
}
