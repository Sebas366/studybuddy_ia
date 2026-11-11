import 'package:flutter_test/flutter_test.dart';
import 'package:studybuddy_ia/data/materia_ejemplo.dart';
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

  group('MateriaEjemplo', () {
    test('trae apuntes con título y texto para probar la IA', () {
      expect(MateriaEjemplo.nombre, isNotEmpty);
      expect(MateriaEjemplo.apuntes, isNotEmpty);
      for (final apunte in MateriaEjemplo.apuntes) {
        expect(apunte.titulo.trim(), isNotEmpty);
        expect(apunte.contenido.trim(), isNotEmpty);
      }
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
      expect(apunte.tieneResumen, isFalse);
    });

    test('tiene resumen cuando la IA ya lo generó', () {
      const apunte = Apunte(
        id: 'a',
        titulo: 't',
        materiaId: 'm',
        fecha: '1 Ene 2026',
        contenido: 'x',
        resumenMedio: 'Un resumen.',
      );

      expect(apunte.tieneResumen, isTrue);
    });
  });
}
