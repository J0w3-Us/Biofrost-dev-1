import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hell_counter_app/core/theme/theme_cubit.dart';
import 'package:hell_counter_app/src/feactures/auth/aplications/auth_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _backgroundEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadBackgroundPref().then((v) {
      setState(() => _backgroundEnabled = v);
    });
  }

  Future<bool> _loadBackgroundPref() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('timer_background_enabled') ?? true;
    } catch (_) {
      return true;
    }
  }

  Future<void> _saveBackgroundPref(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('timer_background_enabled', value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Apariencia',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            BlocBuilder<ThemeCubit, ThemeState>(
              builder: (context, state) {
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.palette),
                    title: const Text('Tema'),
                    subtitle: Text(
                      'Actual: ${context.read<ThemeCubit>().currentThemeName}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showThemeDialog(context),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            // Nueva opción: Animación de fondo del timer
            Card(
              child: SwitchListTile(
                title: const Text('Animación de fondo (Timer)'),
                subtitle: const Text(
                  'Activar/desactivar animación del temporizador',
                ),
                value: _backgroundEnabled,
                secondary: const Icon(Icons.water),
                onChanged: (value) async {
                  await _saveBackgroundPref(value);
                  setState(() => _backgroundEnabled = value);
                },
              ),
            ),
            const Text(
              'Cuenta',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Perfil'),
                subtitle: const Text('test@gmail.com'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Función en desarrollo')),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Cerrar Sesión',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () => _showLogoutDialog(context),
              ),
            ),
            const Spacer(),
            Center(
              child: Text(
                'Hello Counter App v1.0.0',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Seleccionar Tema'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('Sistema'),
              subtitle: const Text('Usar configuración del dispositivo'),
              value: ThemeMode.system,
              groupValue: context.read<ThemeCubit>().state.themeMode,
              onChanged: (value) {
                if (value != null) {
                  context.read<ThemeCubit>().setTheme(value);
                  Navigator.of(dialogContext).pop();
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Claro'),
              subtitle: const Text('Tema claro'),
              value: ThemeMode.light,
              groupValue: context.read<ThemeCubit>().state.themeMode,
              onChanged: (value) {
                if (value != null) {
                  context.read<ThemeCubit>().setTheme(value);
                  Navigator.of(dialogContext).pop();
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Oscuro'),
              subtitle: const Text('Tema oscuro'),
              value: ThemeMode.dark,
              groupValue: context.read<ThemeCubit>().state.themeMode,
              onChanged: (value) {
                if (value != null) {
                  context.read<ThemeCubit>().setTheme(value);
                  Navigator.of(dialogContext).pop();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<AuthCubit>().logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }
}
