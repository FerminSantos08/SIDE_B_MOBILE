import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../auth/auth.dart';
import '../../content/presentation/content_providers.dart';
import '../data/profile_repository.dart';
import 'address_book_screen.dart';

class ProfileSettingsScreen extends ConsumerStatefulWidget {
  const ProfileSettingsScreen({super.key, required this.user});
  final AuthUser user;
  @override
  ConsumerState<ProfileSettingsScreen> createState() =>
      _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends ConsumerState<ProfileSettingsScreen> {
  final _form = GlobalKey<FormState>();
  late final _alias = TextEditingController(text: widget.user.name);
  late final _bio = TextEditingController(text: widget.user.biography);
  bool _busy = false;
  String? _error, _success;
  @override
  void dispose() {
    _alias.dispose();
    _bio.dispose();
    super.dispose();
  }

  void _updated(AuthUser user) {
    ref.read(authProvider.notifier).updateProfile(user);
    ref.invalidate(postsProvider);
    ref.invalidate(commentsProvider);
  }

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
      _success = null;
    });
    try {
      final user = await ref
          .read(profileRepositoryProvider)
          .save(_alias.text, _bio.text);
      if (mounted) {
        _updated(user);
        setState(() => _success = 'Perfil actualizado.');
      }
    } catch (error) {
      if (mounted)
        setState(
          () => _error = error is ApiException
              ? error.message
              : 'No pudimos guardar tu perfil.',
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _photo() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
      _success = null;
    });
    try {
      final bytes = await const MethodChannel('side_b/profile')
          .invokeMethod<Uint8List>('pickAvatar');
      if (!mounted || bytes == null) return;
      final accepted = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Tu nueva foto'),
          content: SizedBox(
            width: 220,
            height: 220,
            child: Image.memory(
              bytes,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) =>
                  const Icon(Icons.broken_image_outlined),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('CANCELAR'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('USAR ESTA FOTO'),
            ),
          ],
        ),
      );
      if (!mounted || accepted != true) return;
      final user = await ref.read(profileRepositoryProvider).avatar(bytes);
      if (mounted) {
        _updated(user);
        setState(() => _success = 'Foto actualizada.');
      }
    } catch (error) {
      if (mounted)
        setState(
          () => _error = error is ApiException
              ? error.message
              : error is PlatformException
              ? (error.message ?? 'No pudimos seleccionar la foto.')
              : 'No pudimos actualizar la foto.',
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).asData?.value ?? widget.user;
    return Scaffold(
      appBar: AppBar(title: const Text('Configuración de cuenta.')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 52),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Center(
                        child: UserAvatar(
                          name: user.name,
                          url: user.avatarUrl,
                          radius: 44,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _busy ? null : _photo,
                        icon: const Icon(Icons.add_a_photo_outlined),
                        label: const Text('ACTUALIZAR FOTO'),
                      ),
                      const Text(
                        'JPG, PNG o WebP · Hasta 5 MB',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user.email,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (user.username.isNotEmpty) Text('@${user.username}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Datos personales',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 16),
                      Form(
                        key: _form,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _alias,
                              enabled: !_busy,
                              maxLength: 50,
                              decoration: const InputDecoration(
                                labelText: 'Alias',
                              ),
                              validator: (value) => (value ?? '').trim().isEmpty
                                  ? 'Escribe tu alias.'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _bio,
                              enabled: !_busy,
                              minLines: 3,
                              maxLines: 5,
                              maxLength: 300,
                              decoration: const InputDecoration(
                                labelText: 'Biografía',
                                alignLabelWithHint: true,
                              ),
                            ),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: _busy ? null : _save,
                              child: Text(
                                _busy ? 'GUARDANDO…' : 'GUARDAR PERFIL',
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            _error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      if (_success != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(_success!),
                        ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 36),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.location_on_outlined),
                title: const Text('Mis direcciones'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _busy
                    ? null
                    : () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const AddressBookScreen(),
                        ),
                      ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.lock_outline),
                title: const Text('Cambiar contraseña'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _busy
                    ? null
                    : () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const ChangePasswordScreen(),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});
  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController(),
      _next = TextEditingController(),
      _confirmation = TextEditingController();
  bool _busy = false, _visible = false;
  String? _error;
  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(profileRepositoryProvider)
          .password(_current.text, _next.text, _confirmation.text);
      if (!mounted) return;
      await ref.read(authProvider.notifier).logout();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contraseña actualizada. Inicia sesión con la nueva.'),
        ),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (error) {
      if (mounted)
        setState(
          () => _error = error is ApiException
              ? error.message
              : 'No pudimos cambiar tu contraseña.',
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Cambiar contraseña.')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 52),
          children: [
            const Text(
              'Confirma tu contraseña actual. Al cambiarla tendrás que iniciar sesión de nuevo en la app.',
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _field(
                        _current,
                        'Contraseña actual',
                        (value) => (value ?? '').isEmpty
                            ? 'Escribe tu contraseña actual.'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      _field(_next, 'Nueva contraseña', (value) {
                        if ((value ?? '').runes.length < 8)
                          return 'Usa al menos 8 caracteres.';
                        if (utf8.encode(value!).length > 72)
                          return 'La contraseña es demasiado larga.';
                        if (value == _current.text)
                          return 'Elige una contraseña diferente.';
                        return null;
                      }),
                      const SizedBox(height: 12),
                      _field(
                        _confirmation,
                        'Confirmar nueva contraseña',
                        (value) => value != _next.text
                            ? 'Las contraseñas no coinciden.'
                            : null,
                      ),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _visible,
                        onChanged: _busy
                            ? null
                            : (value) => setState(() => _visible = value!),
                        title: const Text('Mostrar contraseñas'),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _busy ? null : _save,
                        child: Text(
                          _busy ? 'ACTUALIZANDO…' : 'CAMBIAR CONTRASEÑA',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
    ),
  );
  Widget _field(
    TextEditingController controller,
    String label,
    String? Function(String?) validator,
  ) => TextFormField(
    controller: controller,
    enabled: !_busy,
    obscureText: !_visible,
    enableSuggestions: false,
    autocorrect: false,
    decoration: InputDecoration(labelText: label),
    validator: validator,
  );
}
