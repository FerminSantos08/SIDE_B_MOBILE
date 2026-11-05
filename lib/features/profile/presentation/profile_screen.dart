import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/side_b_theme.dart';
import '../../auth/auth.dart';
import '../../creation/presentation/creation_hub_screen.dart';

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
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 112),
              child: user == null
                  ? const _VisitorProfile()
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
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Tu perfil.', style: Theme.of(context).textTheme.displaySmall),
      const SizedBox(height: 12),
      Text(
        'Guarda hallazgos, administra compras y participa en SIDE B.',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      const SizedBox(height: 24),
      FilledButton(
        style: FilledButton.styleFrom(backgroundColor: SideBColors.accent),
        onPressed: () => _open(context, false),
        child: const Text('INICIAR SESIÓN'),
      ),
      const SizedBox(height: 10),
      OutlinedButton(
        onPressed: () => _open(context, true),
        child: const Text('CREAR CUENTA'),
      ),
    ],
  );
  void _open(BuildContext context, bool register) => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => AuthScreen(register: register)));
}

class _MemberProfile extends ConsumerWidget {
  const _MemberProfile({required this.user});
  final AuthUser user;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ListView(
    children: [
      CircleAvatar(
        radius: 30,
        backgroundColor: SideBColors.olive,
        child: Text(
          user.name.substring(0, 1).toUpperCase(),
          style: const TextStyle(color: SideBColors.ivory, fontSize: 26),
        ),
      ),
      const SizedBox(height: 14),
      Text(user.name, style: Theme.of(context).textTheme.displaySmall),
      Text(user.email, style: Theme.of(context).textTheme.bodyMedium),
      const SizedBox(height: 24),
      if (user.canPublish)
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: SideBColors.accent),
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const CreationHubScreen())),
          child: const Text('CREAR PUBLICACIÓN'),
        ),
      ...[
        'Mis pedidos',
        'Lista de deseos',
        'Publicaciones guardadas',
        'Mi carrito',
        'Configuración de cuenta',
      ].map(
        (item) => ListTile(
          title: Text(item),
          trailing: const Icon(Icons.chevron_right),
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
        backgroundColor: SideBColors.ivory,
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
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _form,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Image.asset(
                          'lib/favicons/sideb.png',
                          width: 124,
                          height: 124,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.register
                            ? 'Crea tu espacio para guardar, comprar y participar en SIDE B.'
                            : 'Inicia sesión para recuperar tus guardados, compras y colección personal.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.register ? 'Crear cuenta.' : 'Iniciar sesión.',
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      const SizedBox(height: 24),
                      if (widget.register) ...[
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
                      if (widget.register) ...[
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
                        style: FilledButton.styleFrom(
                          backgroundColor: SideBColors.accent,
                        ),
                        onPressed: state.isLoading ? null : _submit,
                        child: Text(
                          state.isLoading
                              ? 'CARGANDO...'
                              : widget.register
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
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                    ],
                  ),
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
    controller: controller,
    obscureText: password && !_showPassword,
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
              onPressed: () => setState(() => _showPassword = !_showPassword),
            )
          : null,
    ),
    validator: validator,
  );
  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final auth = ref.read(authProvider.notifier);
    if (widget.register) {
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
