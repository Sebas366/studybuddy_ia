import 'package:flutter_test/flutter_test.dart';
import 'package:studybuddy_ia/data/catalogo_materia.dart';

void main() {
  group('CatalogoMateria', () {
    test('ofrece 6 degradados de 2 colores cada uno', () {
      expect(CatalogoMateria.degradados, hasLength(6));
      for (final degradado in CatalogoMateria.degradados) {
        expect(degradado, hasLength(2));
      }
    });

    test('ofrece 7 iconos e incluye la clave red', () {
      expect(CatalogoMateria.iconos, hasLength(7));
      expect(CatalogoMateria.iconos.containsKey('red'), isTrue);
    });

    test('degradadoPorIndice usa el primero si el índice está fuera de rango',
        () {
      expect(CatalogoMateria.degradadoPorIndice(99),
          CatalogoMateria.degradados.first);
      expect(CatalogoMateria.degradadoPorIndice(-1),
          CatalogoMateria.degradados.first);
    });

    test('degradadoPorIndice devuelve el degradado pedido', () {
      expect(CatalogoMateria.degradadoPorIndice(2),
          CatalogoMateria.degradados[2]);
    });

    test('iconoPorClave usa el icono por defecto si la clave no existe', () {
      expect(CatalogoMateria.iconoPorClave('no-existe'),
          CatalogoMateria.iconos['libro']);
      expect(CatalogoMateria.iconoPorDefecto, 'libro');
    });
  });
}
