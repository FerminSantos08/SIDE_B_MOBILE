# SIDE B Mobile

Aplicación Flutter para la plataforma editorial y tienda musical SIDE B.

## Implementado

- Navegación inferior flotante adaptable a teléfonos y tabletas.
- Inicio y Editorial conectados a publicaciones reales.
- Artículos con estructura editorial, etiquetas, estado y rol de autor.
- Catálogo de Artistas, perfiles, álbumes y publicaciones relacionadas.
- Catálogo de Tienda y detalle de producto con galería, precio y stock.
- Acciones autenticadas de carrito y lista de deseos.
- Login, registro público Listener, token seguro, recuperación de sesión, logout y Perfil dinámico por rol.
- Icono, nombre y splash nativos de Android con identidad SIDE B.

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

- Pantallas completas para carrito, lista de deseos, pedidos y configuración de cuenta.
- Editor, borradores y administración de publicaciones por rol.
- Reacciones y guardados editoriales cuando existan endpoints.
- Pruebas unitarias inyectables para autenticación.
- Validación completa con `flutter analyze` en un entorno sin procesos Flutter/Dart bloqueados.
