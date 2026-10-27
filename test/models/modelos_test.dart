import 'package:flutter_test/flutter_test.dart';
import 'package:studybuddy_ia/data/datos_demo.dart';
import 'package:studybuddy_ia/models/apunte.dart';
import 'package:studybuddy_ia/models/materia.dart';

void main() {
  group('Materia.subtituloPorConteo', () {
    test('describe cero, uno y varios apuntes', () {
      expect(Materia.subtituloPorConteo(0), 'Sin apuntes');
      expect(Materia.subtituloPorConteo(1), '1 apunte');
      expect(Materia.subtituloPorConteo(3), '3 apuntes');
    });
  });

  group('DatosDemo', () {
    test('todas las materias de demostración están marcadas como demo', () {
      expect(DatosDemo.materias, isNotEmpty);
      expect(DatosDemo.materias.every((materia) => materia.esDemo), isTrue);
    });
  });

  group('Apunte', () {
    test('se puede crear sin campos de IA', () {
      const apunte = Apunte(
        id: 'a',
        titulo: 't',
        materiaId: 'm',
        fecha: '1 Ene 2026',
        contenido: 'x',
      );

      expect(apunte.ideasClave, isEmpty);
      expect(apunte.resumenCorto, '');
      expect(apunte.resumenMedio, '');
      expect(apunte.resumenDetallado, '');
    });
  });
}
