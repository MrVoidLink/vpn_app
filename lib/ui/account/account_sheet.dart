import 'package:flutter/material.dart';
import 'dart:async';
import '../../services/user_service.dart';
import '../../services/token_service.dart';
import '../../services/device_id_store.dart';
import '../widgets/bottom_sheet_scaffold.dart';
import '../widgets/glass_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AccountSheet {
  static Future<void> show(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: isDark
          ? Colors.black.withValues(alpha: 0.54)
          : Colors.black.withValues(alpha: 0.20),
      builder: (_) => const _AccountSheetBody(),
    );
  }
}

class _AccountSheetBody extends StatefulWidget {
  const _AccountSheetBody();

  @override
  State<_AccountSheetBody> createState() => _AccountSheetBodyState();
}

class _AccountSheetBodyState extends State<_AccountSheetBody> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _summary = {};
  Map<String, dynamic>? _codeSummary;
  String _currentDeviceId = '';

  // ✅ برای ریل‌تایم لیست دستگاه‌های کُد
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _codeDevSub;
  String? _currentCodeId;
  List<String> _codeActiveDeviceIds = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _codeDevSub?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      _currentDeviceId = await DeviceIdStore.get();
      await _load();
      _attachCodeDevicesRealtime();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final s = await UserService.instance.getUserSummary();
      final cs = await TokenService.instance.getActiveCodeSummary();
      setState(() {
        _summary = s;
        _codeSummary = cs;
        _loading = false;
        _currentCodeId = (_codeSummary?['code'] ?? _summary['code'])?.toString();
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _attachCodeDevicesRealtime() {
    final codeId = (_codeSummary?['code'] ?? _summary['code'])?.toString();
    if (codeId == null || codeId.isEmpty) {
      _codeDevSub?.cancel();
      setState(() {
        _codeActiveDeviceIds = [];
        _currentCodeId = null;
      });
      return;
    }

    if (_currentCodeId != codeId) {
      _codeDevSub?.cancel();
      _currentCodeId = codeId;

      final col = FirebaseFirestore.instance
          .collection('codes')
          .doc(codeId)
          .collection('devices');

      _codeDevSub = col.snapshots().listen((snap) {
        if (!mounted) return;
        final ids = <String>[];
        for (final d in snap.docs) {
          final m = d.data();
          final status = (m['status'] ?? '').toString();
          final isActive = m['isActive'] == true;
          final consideredActive = (status == 'active') && (m['isActive'] != false);
          if (isActive || consideredActive) {
            ids.add(d.id);
          }
        }
        setState(() => _codeActiveDeviceIds = ids);
      });
    }
  }

  // فقط همین دستگاه اجازه Unlink دارد (برای completeness اگر از این Sheet خواستی)
  Future<void> _confirmAndRelease({
    required String codeId,
    required String deviceId,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('آزاد کردن دستگاه'),
        content: const Text('این دستگاه از کُد فعلی جدا می‌شود و ظرفیت آزاد می‌شود. ادامه می‌دهید؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('انصراف')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('آزاد کن')),
        ],
      ),
    ) ?? false;

    if (!ok) return;

    try {
      setState(() => _loading = true);
      await TokenService.instance.releaseDevice(codeId: codeId, deviceId: deviceId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('دستگاه آزاد شد')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا: $e')));
      }
    } finally {
      await _load();
      _attachCodeDevicesRealtime();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomSheetScaffold(
      title: 'حساب کاربری',
      subtitle: 'Loopa VPN',
      leading: const Icon(Icons.person_outline),
      actions: const [Icon(Icons.copy_all_outlined, size: 20)],
      onRefresh: () async { await _load(); _attachCodeDevicesRealtime(); },
      isLoading: _loading,
      errorText: _error,
      empty: !_loading && (_summary.isEmpty),
      childrenBuilder: (ctx) {
        final uid = UserService.instance.uid;
        final plan = _summary['plan']?.toString() ?? '—';
        final expiryMs = _summary['expiry'] as int?;
        final status = (_summary['status'] ?? '—').toString();

        final usedFromCode = _codeSummary?['usedDevices'] as int?;
        final maxFromCode  = _codeSummary?['maxDevices'] as int?;
        final remFromCode  = _codeSummary?['remaining'] as int?;
        final codeStr      = _codeSummary?['code']?.toString() ?? _summary['code']?.toString();

        final used = usedFromCode ?? (_summary['usedDevices'] ?? 0) as int;
        final max  = maxFromCode ?? _summary['maxDevices'];
        final remaining = remFromCode ?? _summary['remaining'];

        final capStr = _capacityText(used: used, max: max, remaining: remaining);
        final capColor = (remaining is int && remaining <= 0)
            ? Colors.red
            : Theme.of(context).colorScheme.onSurface;

        final userDevices = List<Map<String, dynamic>>.from(_summary['devices'] ?? const []);

        // ✅ منبع لیست دستگاه‌های کُد: اول از ریل‌تایم؛ اگر خالی بود، از خلاصه
        List<Map<String, dynamic>> codeDevices;
        if (_codeActiveDeviceIds.isNotEmpty) {
          codeDevices = _codeActiveDeviceIds.map((id) => {'id': id}).toList();
        } else {
          codeDevices = List<Map<String, dynamic>>.from(_codeSummary?['devices'] ?? _summary['codeDevices'] ?? const []);
        }

        final planMap = _asMap(_summary['plan']);
        final String planStatus = (planMap['status'] ?? _summary['status'] ?? '').toString();
        final String planTypeFromMap =
        (planMap['type'] ?? _summary['planType'] ?? _summary['plan'] ?? '').toString();
        final bool hasActiveSub =
            planStatus == 'active' && planTypeFromMap != 'free' && (codeStr?.isNotEmpty ?? false);

        return [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _kv('UID', uid),
                _kv('Plan', plan),
                _kv('وضعیت', status),
                if (hasActiveSub) ...[
                  _kv('انقضا', _fmtDate(expiryMs)),
                  _kv('ظرفیت', capStr, valueColor: capColor),
                  _kv('کُد فعال', codeStr ?? '—'),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          if (hasActiveSub) ...[
            Text('دستگاه‌های من', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (userDevices.isEmpty)
              _emptyCard(context, 'دستگاهی ثبت نشده است')
            else
              ...userDevices.map((d) => _userDeviceTile(context, d, codeStr)).toList(),

            const SizedBox(height: 12),
            Text('دستگاه‌های روی این کُد', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (codeDevices.isEmpty)
              _emptyCard(context, 'اطلاعاتی از دستگاه‌های این کُد موجود نیست')
            else
              ...codeDevices.map((d) => _codeDeviceTile(context, d)).toList(), // فقط نمایش
            const SizedBox(height: 8),
          ],
        ];
      },
    );
  }

  // ---------- helpers ----------
  Map<String, dynamic> _asMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    return {};
  }

  Widget _emptyCard(BuildContext context, String text) => GlassCard(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
    ),
  );

  // فقط همین دستگاه اجازه Unlink دارد
  Widget _userDeviceTile(BuildContext context, Map<String, dynamic> d, String? codeStr) {
    final theme = Theme.of(context);
    final isThis = d['id'] == _currentDeviceId;
    final isActive = d['isActive'] == true;
    final name = d['name']?.toString() ?? '—';
    final code = d['code']?.toString();
    final deviceId = (d['id']?.toString() ?? d['deviceId']?.toString() ?? '');

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Icon(
            isActive ? Icons.verified_rounded : Icons.devices_other_rounded,
            size: 20,
            color: isActive ? Colors.green : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (isThis) _chip('این دستگاه', theme.colorScheme.primary),
                    _chip(isActive ? 'فعال' : 'غیرفعال',
                        isActive ? Colors.green : theme.colorScheme.outline),
                    if (code != null) _chip('کُد: $code', Colors.purple),
                  ],
                ),
              ],
            ),
          ),
          if (isThis && isActive && (codeStr != null) && codeStr.isNotEmpty && deviceId.isNotEmpty)
            TextButton.icon(
              onPressed: () => _confirmAndRelease(codeId: codeStr, deviceId: deviceId),
              icon: const Icon(Icons.link_off),
              label: const Text('Unlink'),
            ),
        ],
      ),
    );
  }

  // فقط نمایش؛ Unlink ندارد
  Widget _codeDeviceTile(BuildContext context, Map<String, dynamic> d) {
    final theme = Theme.of(context);
    final id = d['id']?.toString() ?? '—';
    final isThis = id == _currentDeviceId;

    String shortId = id;
    if (id.length > 10) {
      shortId = '${id.substring(0, 6)}…${id.substring(id.length - 4)}';
    }

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Icon(
              isThis ? Icons.verified_rounded : Icons.devices_other_rounded,
              size: 20,
              color: isThis ? Colors.green : theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              shortId,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _kv(String k, String v, {Color? valueColor}) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text(k, style: t.bodyMedium)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              v,
              style: t.bodyMedium?.copyWith(color: valueColor, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _capacityText({required int used, required dynamic max, required dynamic remaining}) {
    if (max == null) return '$used / نامشخص';
    final rem = (remaining is int) ? remaining : (max - used);
    final safeRem = rem < 0 ? 0 : rem;
    return '$used / $max  (باقی‌مانده: $safeRem)';
  }

  String _fmtDate(int? msEpoch) {
    if (msEpoch == null) return '—';
    try {
      final dt = DateTime.fromMillisecondsSinceEpoch(msEpoch);
      return '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return '—';
    }
  }
}
