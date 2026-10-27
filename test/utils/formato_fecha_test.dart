import 'package:flutter_test/flutter_test.dart';
import 'package:studybuddy_ia/utils/formato_fecha.dart';

void main() {
  group('formatearFecha', () {
    test('formatea día, mes abreviado y año', () {
      expect(formatearFecha(DateTime(2026, 10, 27)), '27 Oct 2026');
    });

    test('no rellena con ceros el día de un dígito', () {
      expect(formatearFecha(DateTime(2026, 1, 5)), '5 Ene 2026');
    });

    test('formatea el último mes del año', () {
      expect(formatearFecha(DateTime(2026, 12, 31)), '31 Dic 2026');
    });
  });
}
