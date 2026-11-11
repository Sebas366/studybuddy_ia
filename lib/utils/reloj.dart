/// Reloj de la app: devuelve la hora actual.
///
/// Se pasa por el árbol de providers para que las pruebas lo reemplacen por uno
/// simulado y puedan fijar el día sin esperar.
typedef Reloj = DateTime Function();
