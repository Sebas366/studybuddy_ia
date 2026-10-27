import 'package:flutter/material.dart';
import 'inicio_screen.dart';
import 'plan_estudio_screen.dart';
import 'estadisticas_screen.dart';
import 'perfil_screen.dart';

/// Estructura base de navegación principal (Shell) de la aplicación.
///
/// Aloja el [NavigationBar] inferior con 4 pestañas y preserva el estado de
/// cada pantalla mediante un [IndexedStack].
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  /// Índice de la pestaña activa en la barra de navegación.
  int _indiceSeleccionado = 0;

  /// Lista de pantallas que componen la navegación principal.
  final List<Widget> _pantallas = const [
    InicioScreen(),
    PlanEstudioScreen(),
    EstadisticasScreen(),
    PerfilScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack preserva el árbol de widgets y scroll de cada pestaña
      body: IndexedStack(
        index: _indiceSeleccionado,
        children: _pantallas,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indiceSeleccionado,
        onDestinationSelected: (nuevoIndice) {
          setState(() {
            _indiceSeleccionado = nuevoIndice;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: 'Plan',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights_rounded),
            label: 'Stats',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
