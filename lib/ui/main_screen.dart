import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

// تم را alias می‌کنیم تا تداخل اسم‌ها (BrandTheme/AppTheme/...) رخ ندهد
import '../theme/app_theme.dart' as design;

import 'settings/settings_sheet.dart';
import 'account/account_sheet.dart';
import 'widgets/banner_carousel.dart';
import 'widgets/glass_card.dart';
import 'widgets/glow_blob.dart';
import 'widgets/aurora_connect_button.dart' as acb;

// سرویس‌ها
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
  acb.ConnectState _state = acb.ConnectState.disconnected;
  bool _activating = false;

  @override
  void initState() {
    super.initState();
    _bootstrapUser(); // ساخت/آپدیت user و ثبت device در اولین اجرا
  }

  @override
  void dispose() {
    _tokenCtrl.dispose();
    super.dispose();
  }

  Future<void> _bootstrapUser() async {
    try {
      final di = DeviceInfoPlugin();
      final pkg = await PackageInfo.fromPlatform();
      final platform = Platform.isAndroid ? 'android' : 'ios';
      final model = Platform.isAndroid
          ? (await di.androidInfo).model
          : (await di.iosInfo).utsname.machine;

      final langCode = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
      final language = (langCode.isNotEmpty ? langCode : 'en');

      await UserService.instance.ensureGuestUser(
        language: language,
        appVersion: pkg.version,
        platform: platform,
        deviceModel: model ?? 'unknown',
      );

      await UserService.instance.registerCurrentDevice();
    } catch (e) {
      // ignore: avoid_print
      print('bootstrap user/device failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme; // رنگ‌های تم
    // استفاده از نوع از طریق alias برای رفع تداخل
    final brand = Theme.of(context).extension<design.BrandTheme>();

    // گرادیانت پس‌زمینه‌ی تیره (مشکی/طوسی)
    final bg = brand?.backgroundGradient ??
        const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F1220), Color(0xFF0A0D18)],
        );

    // عنوان با گرادیانت بنفش عمیق — بدون Cyan
    final titleGrad = design.AppGradients.deepPurple;

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
              ListTile(leading: Icon(Icons.person_outline), title: Text('Account')),
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
          // هر دو Glow بنفش؛ Cyan حذف شد
          const GlowBlob(
            offset: Offset(-140, -120),
            size: 280,
            color: design.AppColors.primaryDark,
            opacity: 0.20,
          ),
          const GlowBlob(
            offset: Offset(160, 220),
            size: 260,
            color: design.AppColors.primary,
            opacity: 0.18,
          ),

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
                        child: acb.AuroraConnectButton(
                          size: 190,
                          state: _state,
                          onTap: _handleConnectTap,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _PingDot(
                            color: _state == acb.ConnectState.connected
                                ? design.AppColors.success // سبز موفقیت تم
                                : cs.outline,             // طوسی/خاکستری تم
                            label: _state == acb.ConnectState.connected
                                ? 'Ping 24ms'
                                : 'Disconnected',
                          ),
                          const SizedBox(width: 12),
                          const _PingDot(
                            color: design.AppColors.warning, // زرد هشدار تم
                            label: 'Load 42%',
                          ),
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
                            RegExp(r'[A-Za-z0-9-]'),
                          ),
                        ],
                        scrollPadding:
                        EdgeInsets.only(bottom: bottomForKeyboard + 120),
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
      // NavigationBar پیش‌فرض متریال ممکنه ته‌مایه آبی بده؛ اینجا تم محلی می‌زنیم
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: Colors.transparent,
            indicatorColor: cs.primary.withValues(alpha: 0.15), // بنفش کم‌رنگ
            iconTheme: MaterialStateProperty.all(
              IconThemeData(color: cs.onSurface.withValues(alpha: 0.9)),
            ),
            labelTextStyle: MaterialStateProperty.all(
              TextStyle(color: cs.onSurface.withValues(alpha: 0.9)),
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (i) {
            final prev = _tab;
            setState(() => _tab = i);

            if (i == 0) {
              AccountSheet.show(context).whenComplete(() {
                if (!mounted) return;
                setState(() => _tab = prev);
              });
              return;
            }
            if (i == 2) {
              SettingsSheet.show(context).whenComplete(() {
                if (!mounted) return;
                setState(() => _tab = prev);
              });
              return;
            }
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
      ),
    );
  }

  // دمو اتصال
  void _handleConnectTap() async {
    if (_state == acb.ConnectState.disconnected) {
      setState(() => _state = acb.ConnectState.connecting);
      await Future.delayed(const Duration(milliseconds: 1500));
      if (!mounted) return;
      setState(() => _state = acb.ConnectState.connected);
    } else {
      setState(() => _state = acb.ConnectState.disconnected);
    }
  }

  // فعال‌سازی توکن
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

    FocusScope.of(context).unfocus();
    await SystemChannels.textInput.invokeMethod('TextInput.hide');

    setState(() => _activating = true);
    try {
      await TokenService.instance.applyToken(token);
      _tokenCtrl.clear();

      final summary = await UserService.instance.getUserSummary();
      final plan = (summary['plan'] ?? 'premium').toString();
      final remaining = summary['remaining'];
      final msg = (remaining is int)
          ? 'Token activated. Plan: $plan | Remaining devices: $remaining'
          : 'Token activated. Plan: $plan';

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Activation error: $e')),
      );
    } finally {
      if (mounted) setState(() => _activating = false);
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
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: cs.onSurface)),
      ],
    );
  }
}
