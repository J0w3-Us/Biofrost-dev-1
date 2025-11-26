import 'package:flutter/material.dart';
// No bloc dependencies in this simplified settings page

class SettingsPage extends StatelessWidget {
  const SettingsPage._();

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const SettingsPage._());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: <Widget>[
          const ListTile(
            title: Text('Temperature Units'),
            isThreeLine: true,
            subtitle: Text('Use metric measurements for temperature units.'),
            trailing: Icon(Icons.thermostat),
          ),
        ],
      ),
    );
  }
}
