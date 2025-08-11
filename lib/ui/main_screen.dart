import 'package:flutter/material.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _tab = 0; // 0: Account, 1: Support, 2: Settings

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.grid_view_rounded),
          onPressed: () {
            // TODO: open side menu / drawer
          },
        ),
        title: const Text('Your VPN'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () {
              // TODO: open notification center
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner
          Card(
            child: ListTile(
              title: const Text('Banner / Promo'),
              subtitle: const Text(
                'Announcements, promos, upgrade to premium...',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: deeplink
              },
            ),
          ),
          const SizedBox(height: 12),

          // Connection & Servers
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Connection & Servers',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      // TODO: connect/disconnect
                    },
                    child: const Text('Connect'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () {
                      // TODO: open server picker (bottom sheet with Free/Premium tabs)
                    },
                    child: const Text('Choose Server'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Token Input
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  const TextField(
                    decoration: InputDecoration(labelText: 'Enter token'),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: activate token via API
                      },
                      child: const Text('Activate'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.person_outline), label: 'Account'),
          NavigationDestination(
              icon: Icon(Icons.support_agent_outlined), label: 'Support'),
          NavigationDestination(
              icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
      ),
    );
  }
}
