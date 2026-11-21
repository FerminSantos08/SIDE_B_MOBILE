import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/side_b_theme.dart';
import '../../../core/theme/theme_mode_provider.dart';
import '../../../core/widgets/user_avatar.dart';

import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'profile_settings_screen.dart';
import 'address_book_screen.dart';
import '../../auth/auth.dart';
import '../../creation/presentation/creation_hub_screen.dart';
import '../../checkout/presentation/order_screens.dart';
import '../../content/presentation/cart_screen.dart';
import '../../library/presentation/saved_posts_screen.dart';
import '../../wishlist/wishlist.dart';
import '../../creation/presentation/editorial_management_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    return auth.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) =>
          _RecoveryError(onRetry: () => ref.invalidate(authProvider)),
      data: (user) => SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 52),
              child: user == null
                  ? const SingleChildScrollView(child: _VisitorProfile())
                  : _MemberProfile(user: user),
            ),
          ),
        ),
      ),
    );
  }
}

class _RecoveryError extends StatelessWidget {
  const _RecoveryError({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.cloud_off_outlined, size: 36),
        const SizedBox(height: 12),
        const Text('No pudimos recuperar tu sesión.'),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: onRetry, child: const Text('REINTENTAR')),
      ],
    ),
  );
}

class _VisitorProfile extends StatelessWidget {
  const _VisitorProfile();
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const _AccountHeading(section: 'Mi cuenta', title: 'Tu perfil.'),
      const SizedBox(height: 24),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: CircleAvatar(
                  backgroundColor: SideBColors.graphite,
                  foregroundColor: SideBColors.paper,
                  child: Icon(LucideIcons.userRound, size: 20),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Tu espacio en SIDE B',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Entra a tu cuenta para ver tus publicaciones guardadas y tus pedidos.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => _open(context, false),
                child: const Text('INICIAR SESIÓN'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => _open(context, true),
                child: const Text('CREAR CUENTA'),
              ),
            ],
          ),
        ),
      ),
    ],
  );
  void _open(BuildContext context, bool register) => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => AuthScreen(register: register)));
}

class _AccountHeading extends StatelessWidget {
  const _AccountHeading({required this.section, required this.title});

  final String section;
  final String title;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section.toUpperCase(),
          style: text.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
        const SizedBox(height: 8),
        Text(title, style: text.displaySmall),
      ],
    );
  }
}

class _MemberProfile extends ConsumerWidget {
  const _MemberProfile({required this.user});
  final AuthUser user;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ListView(
    children: [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TU ESPACIO / SIDE B',
                style: Theme.of(context).textTheme.labelMedium
                    ?.copyWith(color: Theme.of(context).colorScheme.secondary),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  UserAvatar(name: user.name, url: user.avatarUrl, radius: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          user.email,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          user.role.toUpperCase(),
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: SideBColors.olive),
                        ),
                      ],
                    ),
                  ),
                  IconButton.outlined(
                    tooltip: ref.watch(darkThemeProvider)
                        ? 'Activar tema claro'
                        : 'Activar tema oscuro',
                    onPressed: ref.read(darkThemeProvider.notifier).toggle,
                    icon: Icon(
                      ref.watch(darkThemeProvider)
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                    ),
                  ),
                ],
              ),
              if (user.biography.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  user.biography,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ],
          ),
        ),
      ),
      const SizedBox(height: 28),
      if (user.canPublish)
        FilledButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  const Scaffold(body: SafeArea(child: CreationHubScreen())),
            ),
          ),
          child: const Text('CREAR PUBLICACIÓN'),
        ),
      ...[
        if (user.canPublish) 'Mis publicaciones',
        'Mis pedidos',
        'Lista de deseos',
        'Publicaciones guardadas',
        'Mi carrito',
        'Mis direcciones',
        'Configuración de cuenta',
      ].map(
        (item) => ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          shape: Border(
            bottom: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          leading: Icon(
            switch (item) {
              'Mis publicaciones' => LucideIcons.newspaper,
              'Mis pedidos' => LucideIcons.package,
              'Lista de deseos' => LucideIcons.heart,
              'Publicaciones guardadas' => LucideIcons.bookmark,
              'Mi carrito' => LucideIcons.shoppingCart,
              'Mis direcciones' => LucideIcons.mapPin,
              _ => LucideIcons.settings2,
            },
            size: 20,
            color: SideBColors.olive,
          ),
          title: Text(item, style: Theme.of(context).textTheme.bodyLarge),
          trailing: Icon(
            LucideIcons.chevronRight,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          onTap: item == 'Mis pedidos'
              ? () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const OrdersScreen()),
                )
              : item == 'Mi carrito'
              ? () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const CartScreen()),
                )
              : item == 'Mis direcciones'
              ? () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AddressBookScreen(),
                  ),
                )
              : item == 'Configuración de cuenta'
              ? () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ProfileSettingsScreen(user: user),
                  ),
                )
              : item == 'Lista de deseos'
              ? () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const WishlistScreen(),
                  ),
                )
              : item == 'Publicaciones guardadas'
              ? () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const SavedPostsScreen(),
                  ),
                )
              : item == 'Mis publicaciones'
              ? () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const EditorialManagementScreen(),
                  ),
                )
              : null,
        ),
      ),
      const SizedBox(height: 16),
      OutlinedButton(
        onPressed: () => ref.read(authProvider.notifier).logout(),
        child: const Text('CERRAR SESIÓN'),
      ),
    ],
  );
}

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key, required this.register});
  final bool register;
  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  var _showPassword = false;
  late bool _register = widget.register;

  void _switchMode() {
    setState(() {
      _register = !_register;
      _showPassword = false;
      _password.clear();
      _confirmation.clear();
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authProvider);
    final error = state.hasError ? state.error.toString() : null;
    return Scaffold(
      appBar: AppBar(
        title: const Text('SIDE B'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Volver',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 52),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _AccountHeading(
                      section: 'Mi cuenta',
                      title: _register ? 'Crear cuenta.' : 'Iniciar sesión.',
                    ),
                    const SizedBox(height: 20),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: AutofillGroup(
                          child: Form(
                            key: _form,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (_register) ...[
                                  _field(
                                    _name,
                                    'Nombre',
                                    (v) => v == null || v.trim().length < 3
                                        ? 'Mínimo 3 caracteres.'
                                        : null,
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                _field(
                                  _email,
                                  'Correo',
                                  (v) => v == null || !v.contains('@')
                                      ? 'Correo inválido.'
                                      : null,
                                  email: true,
                                ),
                                const SizedBox(height: 12),
                                _field(
                                  _password,
                                  'Contraseña',
                                  (v) => v == null || v.length < 8
                                      ? 'Mínimo 8 caracteres.'
                                      : null,
                                  password: true,
                                ),
                                if (_register) ...[
                                  const SizedBox(height: 12),
                                  _field(
                                    _confirmation,
                                    'Confirmar contraseña',
                                    (v) => v != _password.text
                                        ? 'Las contraseñas no coinciden.'
                                        : null,
                                    password: true,
                                  ),
                                ],
                                const SizedBox(height: 22),
                                FilledButton(
                                  onPressed: state.isLoading ? null : _submit,
                                  child: Text(
                                    state.isLoading
                                        ? 'CARGANDO...'
                                        : _register
                                        ? 'CREAR CUENTA'
                                        : 'INICIAR SESIÓN',
                                  ),
                                ),
                                if (error != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: Text(
                                      error,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .error,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: state.isLoading ? null : _switchMode,
                      child: Text(
                        _register ? 'Ya tengo cuenta' : 'Crear una cuenta',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    String? Function(String?) validator, {
    bool email = false,
    bool password = false,
  }) => TextFormField(
    key: ValueKey(label),
    controller: controller,
    obscureText: password && !_showPassword,
    autofillHints: [
      if (email)
        AutofillHints.email
      else if (password)
        _register ? AutofillHints.newPassword : AutofillHints.password
      else
        AutofillHints.name,
    ],
    keyboardType: email ? TextInputType.emailAddress : TextInputType.text,
    decoration: InputDecoration(
      labelText: label,
      suffixIcon: password
          ? IconButton(
              icon: Icon(
                _showPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
              tooltip: _showPassword
                  ? 'Ocultar contraseña'
                  : 'Mostrar contraseña',
              onPressed: () => setState(() => _showPassword = !_showPassword),
            )
          : null,
    ),
    validator: validator,
  );
  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final auth = ref.read(authProvider.notifier);
    if (_register) {
      await auth.register(
        _name.text.trim(),
        _email.text.trim(),
        _password.text,
      );
    } else {
      await auth.login(_email.text.trim(), _password.text);
    }
    if (mounted && ref.read(authProvider).asData?.value != null)
      Navigator.of(context).pop();
  }
}
