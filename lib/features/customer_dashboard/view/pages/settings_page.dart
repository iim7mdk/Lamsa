import 'package:flutter/material.dart';
import 'package:lamsa/core/app.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            Card(
              child: SwitchListTile(
                value: themeController.isDark,
                onChanged: (value) {
                  themeController.changeTheme(value);
                },
                secondary: Icon(
                  themeController.isDark
                      ? Icons.dark_mode
                      : Icons.light_mode,
                ),
                title: const Text(
                  'الوضع الداكن',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  themeController.isDark
                      ? 'الثيم الحالي: Dark'
                      : 'الثيم الحالي: Light',
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}