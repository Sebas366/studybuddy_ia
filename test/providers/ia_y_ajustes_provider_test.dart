import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studybuddy_ia/providers/ajustes_provider.dart';
import 'package:studybuddy_ia/providers/ia_provider.dart';
import 'package:studybuddy_ia/services/almacen_clave.dart';
import 'package:studybuddy_ia/services/notificador_pomodoro.dart';
import 'package:studybuddy_ia/services/proveedor_ia.dart';
import 'package:studybuddy_ia/services/servicio_ia.dart';

import '../support/repositorio_memoria.dart';
import '../support/servicio_ia_falso.dart';

/// Recordatorio de pruebas: anota lo que se le pide.
class RecordatorioFalso implements NotificadorRecordatorio {
  int permisosPedidos = 0;
  int cancelaciones = 0;
  final List<({int hora, int minuto})> programados = [];

  @override
  Future<void> pedirPermisos() async => permisosPedidos++;

  @override
  Future<void> programarDiario({
    required int hora,
    required int minuto,
    required String titulo,
    required String cuerpo,
  }) async {
    programados.add((hora: hora, minuto: minuto));
  }

  @override
  Future<void> cancelarDiario() async => cancelaciones++;
}

/// Almacén de clave que siempre falla, como si el sistema no dejara usarlo.
class AlmacenRoto implements AlmacenClave {
  @override
  Future<String?> leer() => throw StateError('sin almacén');

  @override
  Future<void> guardar(String clave) => throw StateError('sin almacén');

  @override
  Future<void> borrar() => throw StateError('sin almacén');
}

void main() {
  group('IaProvider', () {
    test('sin clave guardada la IA queda sin conectar', () async {
      final provider = IaProvider(
        almacen: AlmacenClaveMemoria(),
        fabrica: (_, _) => ServicioIaFalso(),
      );
      await provider.cargar();

      expect(provider.tieneClave, isFalse);
      expect(provider.claveOculta, isNull);
      expect(
        () => provider.servicio,
        throwsA(
          isA<ErrorIa>().having((e) => e.tipo, 'tipo', TipoErrorIa.sinClave),
        ),
      );
    });

    test('una clave guardada deja el servicio listo al cargar', () async {
      String? claveUsada;
      ProveedorIa? proveedorUsado;
      final provider = IaProvider(
        almacen: AlmacenClaveMemoria('claude|sk-ant-api03-abcdefghijkl'),
        fabrica: (proveedor, clave) {
          proveedorUsado = proveedor;
          claveUsada = clave;
          return ServicioIaFalso();
        },
      );
      await provider.cargar();

      expect(provider.tieneClave, isTrue);
      expect(provider.proveedor, ProveedorIa.claude);
      expect(proveedorUsado, ProveedorIa.claude);
      expect(claveUsada, 'sk-ant-api03-abcdefghijkl');
      // En pantalla solo se ven el inicio y el final de la clave.
      expect(provider.claveOculta, 'sk-ant-…ijkl');
    });

    test('guardarClave recorta, guarda y notifica', () async {
      final almacen = AlmacenClaveMemoria();
      final provider = IaProvider(
        almacen: almacen,
        fabrica: (_, _) => ServicioIaFalso(),
      );
      await provider.cargar();
      var notificaciones = 0;
      provider.addListener(() => notificaciones++);

      await provider.guardarClave(ProveedorIa.gemini, '  AIzaNuevaClave123  ');

      expect(provider.tieneClave, isTrue);
      expect(provider.proveedor, ProveedorIa.gemini);
      // Se guarda con el proveedor delante para saber con cuál reconectar.
      expect(await almacen.leer(), 'gemini|AIzaNuevaClave123');
      expect(notificaciones, greaterThan(0));
    });

    test('una clave vacía lanza ArgumentError y no cambia nada', () async {
      final provider = IaProvider(
        almacen: AlmacenClaveMemoria(),
        fabrica: (_, _) => ServicioIaFalso(),
      );
      await provider.cargar();

      expect(
        () => provider.guardarClave(ProveedorIa.gemini, '   '),
        throwsArgumentError,
      );
      expect(provider.tieneClave, isFalse);
    });

    test('borrarClave deja la IA sin conectar y limpia el almacén', () async {
      final almacen = AlmacenClaveMemoria('claude|sk-ant-vieja-clave-123');
      final provider = IaProvider(
        almacen: almacen,
        fabrica: (_, _) => ServicioIaFalso(),
      );
      await provider.cargar();

      await provider.borrarClave();

      expect(provider.tieneClave, isFalse);
      expect(await almacen.leer(), isNull);
    });

    test('el proveedor guardado se respeta al reabrir', () async {
      final almacen = AlmacenClaveMemoria();
      final primero = IaProvider(
        almacen: almacen,
        fabrica: (_, _) => ServicioIaFalso(),
      );
      await primero.cargar();
      // Sin clave guardada se propone Gemini, que es el gratuito.
      expect(primero.proveedor, ProveedorIa.gemini);
      await primero.guardarClave(ProveedorIa.claude, 'sk-ant-una-clave-123');

      final reabierto = IaProvider(
        almacen: almacen,
        fabrica: (_, _) => ServicioIaFalso(),
      );
      await reabierto.cargar();

      expect(reabierto.proveedor, ProveedorIa.claude);
      expect(reabierto.claveOculta, 'sk-ant-…-123');
    });

    test('una clave suelta, sin proveedor, se reconoce por su forma', () async {
      final claude = IaProvider(
        almacen: AlmacenClaveMemoria('sk-ant-api03-abcdefghijkl'),
        fabrica: (_, _) => ServicioIaFalso(),
      );
      await claude.cargar();
      expect(claude.proveedor, ProveedorIa.claude);

      final gemini = IaProvider(
        almacen: AlmacenClaveMemoria('AIzaSyUnaClaveDeGemini'),
        fabrica: (_, _) => ServicioIaFalso(),
      );
      await gemini.cargar();
      expect(gemini.proveedor, ProveedorIa.gemini);
      expect(gemini.tieneClave, isTrue);
    });

    test('si el almacén falla, la clave sirve hasta cerrar la app', () async {
      final provider = IaProvider(
        almacen: AlmacenRoto(),
        fabrica: (_, _) => ServicioIaFalso(),
      );
      await provider.cargar();
      expect(provider.tieneClave, isFalse);

      await provider.guardarClave(ProveedorIa.claude, 'sk-ant-en-memoria-123');

      expect(provider.tieneClave, isTrue);
    });
  });

  group('AjustesProvider', () {
    late RepositorioMemoria repositorio;
    late RecordatorioFalso recordatorio;

    setUp(() {
      repositorio = RepositorioMemoria();
      recordatorio = RecordatorioFalso();
    });

    AjustesProvider crear() =>
        AjustesProvider(repositorio: repositorio, recordatorio: recordatorio);

    test('sin ajustes guardados usa los valores por defecto', () async {
      final ajustes = crear();
      await ajustes.cargar();

      expect(ajustes.nombre, 'Estudiante');
      expect(ajustes.carrera, '');
      expect(ajustes.modoTema, ThemeMode.system);
      expect(ajustes.recordatorioActivo, isFalse);
      expect(ajustes.horaRecordatorio, const TimeOfDay(hour: 18, minute: 0));
    });

    test('el perfil, el tema y el recordatorio siguen ahí al reabrir', () async {
      final ajustes = crear();
      await ajustes.cargar();
      await ajustes.cambiarPerfil(nombre: '  Edwin ', carrera: ' Ingeniería ');
      await ajustes.cambiarTema(ThemeMode.dark);
      await ajustes.cambiarRecordatorio(
        activo: true,
        hora: const TimeOfDay(hour: 7, minute: 5),
      );

      final reabierto = crear();
      await reabierto.cargar();

      expect(reabierto.nombre, 'Edwin');
      expect(reabierto.carrera, 'Ingeniería');
      expect(reabierto.modoTema, ThemeMode.dark);
      expect(reabierto.recordatorioActivo, isTrue);
      expect(reabierto.horaRecordatorio, const TimeOfDay(hour: 7, minute: 5));
    });

    test('un nombre vacío vuelve al nombre por defecto', () async {
      final ajustes = crear();
      await ajustes.cargar();
      await ajustes.cambiarPerfil(nombre: 'Edwin', carrera: '');

      await ajustes.cambiarPerfil(nombre: '   ', carrera: '');

      expect(ajustes.nombre, 'Estudiante');
      final reabierto = crear();
      await reabierto.cargar();
      expect(reabierto.nombre, 'Estudiante');
    });

    test('encender el recordatorio pide permiso y lo programa a su hora', () async {
      final ajustes = crear();
      await ajustes.cargar();

      await ajustes.cambiarRecordatorio(
        activo: true,
        hora: const TimeOfDay(hour: 20, minute: 15),
      );

      expect(recordatorio.permisosPedidos, 1);
      expect(recordatorio.programados.single, (hora: 20, minuto: 15));
    });

    test('apagar el recordatorio lo cancela', () async {
      final ajustes = crear();
      await ajustes.cargar();
      await ajustes.cambiarRecordatorio(activo: true);

      await ajustes.cambiarRecordatorio(activo: false);

      expect(ajustes.recordatorioActivo, isFalse);
      expect(recordatorio.cancelaciones, 1);
    });

    test('si guardar falla, el cambio igual se aplica en pantalla', () async {
      final ajustes = AjustesProvider(repositorio: _AjustesRotos());
      await ajustes.cargar();

      await ajustes.cambiarTema(ThemeMode.dark);

      expect(ajustes.modoTema, ThemeMode.dark);
    });
  });
}

/// Repositorio cuyos ajustes no se pueden leer ni guardar.
class _AjustesRotos extends RepositorioMemoria {
  @override
  Future<String?> obtenerAjuste(String clave) =>
      throw StateError('Fallo simulado de lectura');

  @override
  Future<void> guardarAjuste(String clave, String valor) =>
      throw StateError('Fallo simulado de escritura');
}
