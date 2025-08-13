import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../theme/app_theme.dart';
import 'settings/settings_sheet.dart';
import 'widgets/banner_carousel.dart';
import 'widgets/glass_card.dart';
import 'widgets/glow_blob.dart';
import 'widgets/aurora_connect_button.dart';

// سرویس‌ها
import '../services/device_identity_channel.dart';
import '../services/token_service.dart';
import '../services/user_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _tokenCtrl = TextEditingController();

  int _tab = 0;
  ConnectState _state = ConnectState.disconnected;
  bool _activating = false;

  @override
  void dispose() {
    _tokenCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brand = Theme.of(context).extension<BrandTheme>();
    final bg = brand?.backgroundGradient ??
        const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F1220), Color(0xFF0A0D18)],
        );
    final titleGrad = brand?.primaryGradient ??
        const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [kNeonPurple, kNeonCyan],
        );

    final mq = MediaQuery.of(context);
    final bottomForNav = mq.padding.bottom + kBottomNavigationBarHeight + 24;
    final bottomForKeyboard = mq.viewInsets.bottom + 16;
    final listBottomPadding =
    bottomForKeyboard > 16 ? bottomForKeyboard : bottomForNav;

    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: const [
              DrawerHeader(
                child: Text(
                  'loopa vpn',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
              ),
              ListTile(leading: Icon(Icons.home_outlined), title: Text('Home')),
              ListTile(leading: Icon(Icons.dns_outlined), title: Text('Servers')),
              ListTile(
                  leading: Icon(Icons.person_outline), title: Text('Account')),
            ],
          ),
        ),
      ),
      extendBody: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.grid_view_rounded),
          tooltip: 'Menu',
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: ShaderMask(
          shaderCallback: (r) => titleGrad.createShader(r),
          child: const Text(
            'loopa vpn',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            tooltip: 'Notifications',
            onPressed: () {/* TODO */},
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(decoration: BoxDecoration(gradient: bg)),
          ),
          const GlowBlob(
              offset: Offset(-140, -120),
              size: 280,
              color: kNeonPurple,
              opacity: 0.20),
          const GlowBlob(
              offset: Offset(160, 220),
              size: 260,
              color: kNeonCyan,
              opacity: 0.18),

          SafeArea(
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, 16, 16, listBottomPadding),
              children: [
                const BannerCarousel(),
                const SizedBox(height: 16),

                // Connection
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Connection',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      Center(
                        child: AuroraConnectButton(
                          size: 190,
                          state: _state,
                          onTap: _handleConnectTap,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _PingDot(
                            color: _state == ConnectState.connected
                                ? Colors.green
                                : Colors.grey,
                            label: _state == ConnectState.connected
                                ? 'Ping 24ms'
                                : 'Disconnected',
                          ),
                          const SizedBox(width: 12),
                          const _PingDot(color: Colors.orange, label: 'Load 42%'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () {/* TODO: server picker */},
                        icon: const Icon(Icons.dns_outlined),
                        label: const Text('Choose Server'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Token
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Token',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _tokenCtrl,
                        keyboardType: TextInputType.visiblePassword,
                        textInputAction: TextInputAction.done,
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters: [
                          _UpperCaseFormatter(),
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[A-Za-z0-9-]')),
                        ],
                        scrollPadding: EdgeInsets.only(
                            bottom: bottomForKeyboard + 120),
                        decoration: const InputDecoration(
                          labelText: 'Enter token',
                          hintText: 'e.g. ABCD-1234 or LONG-KEY-1234-XYZ',
                        ),
                        onSubmitted: (_) => _onActivate(),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _activating ? null : _onActivate,
                        child: _activating
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                            : const Text('Activate'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) {
          if (i == 2) {
            SettingsSheet.show(context);
            return;
          }
          setState(() => _tab = i);
        },
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

  // دمو اتصال
  void _handleConnectTap() async {
    if (_state == ConnectState.disconnected) {
      setState(() => _state = ConnectState.connecting);
      await Future.delayed(const Duration(milliseconds: 1500));
      if (!mounted) return;
      setState(() => _state = ConnectState.connected);
    } else if (_state == ConnectState.connected) {
      setState(() => _state = ConnectState.disconnected);
    } else {
      setState(() => _state = ConnectState.disconnected);
    }
  }

  // فعال‌سازی توکن + ارسال به /api/apply-token
  Future<void> _onActivate() async {
    final token = _tokenCtrl.text.trim();
    final isValid =
        token.isNotEmpty && RegExp(r'^[A-Za-z0-9-]+$').hasMatch(token);
    if (!isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid token. Use letters, numbers, and - only.'),
        ),
      );
      return;
    }

    setState(() => _activating = true);
    try {
      // 1) uid گرفتن
      final uid = UserService.instance.uid;
      if (uid.isEmpty) {
        throw Exception('No UID. Make sure ensureGuestUser() ran.');
      }

      // 2) DeviceClaim از نیتیو
      final claim = await getDeviceClaim();
      final deviceId = (claim['deviceId'] as String?) ?? '';

      // 3) deviceInfo
      final di = DeviceInfoPlugin();
      final pkg = await PackageInfo.fromPlatform();
      final platform = Platform.isAndroid ? 'android' : 'ios';
      final model = Platform.isAndroid
          ? (await di.androidInfo).model ?? 'Android'
          : (await di.iosInfo).utsname.machine ?? 'iPhone';
      final deviceInfo = {
        'platform': platform,
        'model': model,
        'appVersion': pkg.version,
      };

      // 4) کال API
      final result = await TokenService.instance.applyToken(
        uid: uid,
        codeId: token,
        deviceId: deviceId,
        deviceInfo: deviceInfo,
      );

      if (!mounted) return;

      if (result.ok) {
        final data = result.data!;
        debugPrint('apply-token OK => ${jsonEncode(data)}');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Activated: ${data['mode']} • expires=${data['expiresAt']}',
            ),
          ),
        );

        // TODO: آپدیت UserService/حالت UI با داده‌های برگشتی (plan, expiresAt, ...)
      } else {
        debugPrint('apply-token FAIL => ${result.error}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.error ?? 'Activation failed')),
        );
      }
    } catch (e) {
      debugPrint('Activation error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Activation error: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _activating = false);
    }
  }
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final up = newValue.text.toUpperCase();
    return newValue.copyWith(
      text: up,
      selection: TextSelection.collapsed(offset: up.length),
      composing: TextRange.empty,
    );
  }
}

class _PingDot extends StatelessWidget {
  final Color color;
  final String label;
  const _PingDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}
