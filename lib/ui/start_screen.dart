import 'package:flutter/material.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your VPN')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Spacer(),
            Text(
              'Welcome to Your VPN',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Start using free servers or enter your token to activate premium.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () =>
                    Navigator.of(context).pushReplacementNamed('/main'),
                child: const Text('Start using free'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed('/main');
                  // TODO: در Main روی Token Input فوکوس بده
                },
                child: const Text('I’ve got a token'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
