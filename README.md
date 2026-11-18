# SIDE B Mobile

Aplicación Flutter para la plataforma editorial y tienda musical SIDE B.

## Implementado

- Navegación inferior flotante adaptable a teléfonos y tabletas.
- Inicio y Editorial conectados a publicaciones reales.
- Artículos con estructura editorial, etiquetas, estado y rol de autor.
- Publicaciones guardadas compartidas con la web: marcador en artículos y biblioteca en Perfil.
- Administración editorial por rol: listado, filtros y edición de publicaciones con borradores, revisión, publicación, archivo y protección contra cambios concurrentes.
- Comentarios en artículos: lectura pública y publicación con sesión iniciada, máximo 500 caracteres, actualización y reintento sin perder el borrador.
- Reacciones con cápsula Lucide gestual: mantener, deslizar y soltar para elegir; cuatro tipos, contadores y selección persistente. Barra fija Reaccionar, Comentar y Compartir.
- Catálogo de Artistas, perfiles, álbumes y publicaciones relacionadas.
- Catálogo de Tienda y detalle de producto con galería, precio y stock.
- Carrito y lista de deseos compartida con la web, con corazón persistente y acceso desde Perfil.
- Portadas editoriales: selección, vista previa y guardado junto con el artículo.
- Configuración de perfil, foto, direcciones y cambio básico de contraseña con contraseña actual.
- Compra móvil: envío, resumen calculado por API, pago PayPal sandbox directo mediante FastAPI y aprobación en navegador (sin PHP para el pago móvil), retorno a la app e historial de pedidos compartido con la web. Ver `docs/checkout.md`.
- Login, registro público Listener, token seguro, recuperación de sesión, logout y Perfil dinámico por rol.
- Splash Android en marfil, compatible con modo claro y oscuro; icono y nombre con identidad SIDE B.
- Tipografía incluida en el APK, imágenes sin sombreado, galería adaptable y estados de carga/error/vacío consistentes.
- Barra flotante conservada; botón Atrás vuelve a Inicio y el teclado dispone del espacio de edición.

## Requisitos

- Flutter con Dart `^3.13.7`.
- API SIDE B disponible en la URL de `lib/core/config/api_config.dart`.
- Migración `wishlist_item` aplicada en MySQL para lista de deseos.
- `JWT_SECRET` de al menos 32 caracteres configurado en FastAPI.

## Ejecutar

```powershell
flutter pub get
flutter run
```

## Pendiente

- Pruebas unitarias inyectables para autenticación.
- Firma de distribución y URL pública HTTPS para producción; registrar el webhook PayPal cuando exista esa URL.


## Verificación del acabado

`flutter test --no-pub` ejecuta toda la suite, incluyendo navegación, tamaños de
320 a 900 px, texto ampliado, teclado, estados cortos y los flujos de cuenta,
portadas, biblioteca, deseos, comentarios, reacciones y checkout.
`flutter analyze --no-pub --no-fatal-infos` comprueba errores y advertencias;
el SDK actual informa además deprecaciones y recomendaciones de estilo.

El splash utiliza el mismo fondo marfil en los recursos Android normales,
nocturnos y Android 12+. Las fuentes Space Grotesk e Instrument Serif se incluyen
con sus licencias OFL en `assets/fonts`, sin descarga al abrir la aplicación.
