import 'package:flutter_test/flutter_test.dart';
import 'package:studybuddy_ia/utils/semestres.dart';

void main() {
  group('semestreActual', () {
    test('de enero a junio es el semestre 1', () {
      expect(semestreActual(DateTime(2026, 1, 1)), '2026-1');
      expect(semestreActual(DateTime(2026, 6, 30)), '2026-1');
      expect(semestreActual(DateTime(2027, 2, 10)), '2027-1');
    });

    test('de julio a diciembre es el semestre 2', () {
      expect(semestreActual(DateTime(2026, 7, 1)), '2026-2');
      expect(semestreActual(DateTime(2026, 12, 31)), '2026-2');
    });
  });

  group('validarSemestre', () {
    const mensajeVacio = 'Escribe el semestre.';

    test('rechaza nulo, vacío y solo espacios', () {
      expect(validarSemestre(null), mensajeVacio);
      expect(validarSemestre(''), mensajeVacio);
      expect(validarSemestre('   '), mensajeVacio);
    });

    test('acepta un semestre normal y uno de exactamente 20 caracteres', () {
      expect(validarSemestre('2026-2'), isNull);
      expect(validarSemestre('X' * 20), isNull);
    });

    test('rechaza más de 20 caracteres', () {
      expect(validarSemestre('X' * 21),
          'El semestre no puede pasar de 20 caracteres.');
    });

    test('ignora los espacios sobrantes', () {
      expect(validarSemestre(' 2026-2 '), isNull);
    });
  });
}
