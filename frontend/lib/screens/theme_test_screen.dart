import 'package:flutter/material.dart';

class ThemeTestScreen extends StatelessWidget {
  const ThemeTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Material 3 Theme Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text(
              'Material 3 Color Scheme',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            // Primary Colors
            _buildColorCard('Primary', colorScheme.primary, colorScheme.onPrimary),
            _buildColorCard('Primary Container', colorScheme.primaryContainer, colorScheme.onPrimaryContainer),
            
            // Secondary Colors
            _buildColorCard('Secondary (Orange)', colorScheme.secondary, colorScheme.onSecondary),
            _buildColorCard('Secondary Container', colorScheme.secondaryContainer, colorScheme.onSecondaryContainer),
            
            // Surface Colors
            _buildColorCard('Surface', colorScheme.surface, colorScheme.onSurface),
            _buildColorCard('Surface Variant', colorScheme.surfaceVariant, colorScheme.onSurfaceVariant),
            
            // Background
            _buildColorCard('Background', colorScheme.background, colorScheme.onBackground),
            
            const SizedBox(height: 20),
            
            // Interactive Elements Test
            const Text(
              'Interactive Elements',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            ElevatedButton(
              onPressed: () {},
              child: const Text('Primary Button'),
            ),
            const SizedBox(height: 8),
            
            OutlinedButton(
              onPressed: () {},
              child: const Text('Outlined Button'),
            ),
            const SizedBox(height: 8),
            
            TextButton(
              onPressed: () {},
              child: const Text('Text Button'),
            ),
            const SizedBox(height: 16),
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sample Card',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This card uses Material 3 theming with proper surface colors.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            SwitchListTile(
              title: const Text('Sample Switch'),
              subtitle: const Text('Uses secondary color (orange)'),
              value: true,
              onChanged: (value) {},
            ),
            
            const SizedBox(height: 16),
            
            Slider(
              value: 0.5,
              onChanged: (value) {},
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildColorCard(String name, Color color, Color onColor) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        color: color,
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: TextStyle(
                color: onColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '#${color.value.toRadixString(16).substring(2).toUpperCase()}',
              style: TextStyle(
                color: onColor,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
