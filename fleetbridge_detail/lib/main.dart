import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

const channel = MethodChannel('fleetbridge/vehicle');
// The isolate can start before the host registers its handler. Retry only the
// missing-handler startup race, with a bounded wait; real errors are surfaced.
Future<Map<String, dynamic>?> fetchVehicle(String id) async {
  for (var attempt = 0; ; attempt++) {
    try {
      return await channel.invokeMapMethod<String, dynamic>('getVehicle', {'id': id});
    } on MissingPluginException {
      if (attempt >= 19) rethrow;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }
}

final vehicleProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  final data = await fetchVehicle(id);
  if (data == null || data['name'] is! String || data['model'] is! String) {
    throw StateError('차량 정보를 찾을 수 없습니다.');
  }
  return data;
}, retry: (retryCount, error) => null);

void main() => runApp(const ProviderScope(child: FleetApp()));

class FleetApp extends StatelessWidget {
  const FleetApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    home: VehicleDetail(id: Uri.parse(WidgetsBinding.instance.platformDispatcher.defaultRouteName).queryParameters['id'] ?? ''),
  );
}

class VehicleRevisionGate {
  VehicleRevisionGate(this.id);
  final String id;
  int _revision = -1;
  bool accept(Map data) {
    final revision = data['revision'];
    if (data['id'] != id || revision is! int || revision <= _revision) return false;
    _revision = revision;
    return true;
  }
}

class VehicleDetail extends ConsumerStatefulWidget {
  const VehicleDetail({super.key, required this.id});
  final String id;
  @override
  ConsumerState<VehicleDetail> createState() => _VehicleDetailState();
}

class _VehicleDetailState extends ConsumerState<VehicleDetail> {
  late final VehicleRevisionGate _revisionGate;
  Timer? _freshnessTimer;
  @override
  void initState() {
    super.initState();
    _revisionGate = VehicleRevisionGate(widget.id);
    _freshnessTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) setState(() {});
    });
    channel.setMethodCallHandler((call) async {
      if (call.method != 'vehicleUpdated' || call.arguments is! Map) return;
      final data = call.arguments as Map;
      if (_revisionGate.accept(data)) ref.invalidate(vehicleProvider(widget.id));
    });
  }
  @override
  void dispose() {
    _freshnessTimer?.cancel();
    channel.setMethodCallHandler(null);
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final id = widget.id;
    final state = ref.watch(vehicleProvider(id));
    return Scaffold(
      appBar: AppBar(title: const Text('차량 상세'), leading: IconButton(
        tooltip: '목록으로 돌아가기', icon: const Icon(Icons.arrow_back), onPressed: () => channel.invokeMethod<void>('close'),
      )),
      body: Center(child: state.when(
        loading: () => const CircularProgressIndicator(),
        error: (error, stack) => Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('차량 정보를 불러올 수 없습니다.'),
          TextButton(onPressed: () => ref.invalidate(vehicleProvider(id)), child: const Text('다시 시도')),
        ]),
        data: (vehicle) => VehicleDashboard(vehicle: vehicle, id: id),
      )),
    );
  }
}

class VehicleDashboard extends StatefulWidget {
  const VehicleDashboard({super.key, required this.vehicle, required this.id, this.mapTestMode = false});
  final Map<String, dynamic> vehicle;
  final String id;
  final bool mapTestMode;
  @override
  State<VehicleDashboard> createState() => _VehicleDashboardState();
}

class _VehicleDashboardState extends State<VehicleDashboard> {
  bool pending = false;
  String scenario = 'success';
  String? result;
  bool mapLoadFailed = false;
  Future<void> sendCommand() async {
    if (pending) return;
    setState(() { pending = true; result = null; });
    try {
      final value = await channel.invokeMethod<String>('setRefrigeration', {
        'id': widget.id, 'enabled': widget.vehicle['refrigerationOn'] != true, 'scenario': scenario,
      });
      if (mounted) setState(() => result = value);
    } catch (_) {
      if (mounted) setState(() => result = 'failure');
    } finally {
      if (mounted) setState(() => pending = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    final vehicle = widget.vehicle;
    final id = widget.id;
    final latitude = vehicle['latitude'];
    final longitude = vehicle['longitude'];
    final status = vehicle['status'];
    final lastUpdate = vehicle['updatedAt'];
    final last = lastUpdate is num ? DateTime.fromMillisecondsSinceEpoch(lastUpdate.toInt()) : null;
    final stale = last != null && DateTime.now().difference(last) > const Duration(seconds: 15);
    final labels = {'driving': '운행 중', 'idle': '대기', 'offline': '오프라인'};
    return ListView(padding: const EdgeInsets.all(20), children: [
      Text(vehicle['name'] as String, style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 4),
      Text(vehicle['model'] as String), Text(id),
      const SizedBox(height: 16),
      Wrap(spacing: 12, runSpacing: 8, children: [
        Chip(label: Text(labels[status] ?? '상태 미확인')),
        if (vehicle['battery'] != null) Chip(label: Text('배터리 ${vehicle['battery']}%')),
        if (status == 'offline') const Chip(label: Text('연결 끊김 (모의)'))
        else if (stale) const Chip(label: Text('갱신 지연')),
      ]),
      if (last != null) Text('마지막 갱신 ${last.toLocal()}'),
      const SizedBox(height: 16),
      if (latitude is num && longitude is num)
        SizedBox(height: 300, child: FlutterMap(
          options: MapOptions(initialCenter: LatLng(latitude.toDouble(), longitude.toDouble()), initialZoom: 13),
          children: [
            if (!widget.mapTestMode && Uri.parse(WidgetsBinding.instance.platformDispatcher.defaultRouteName).queryParameters['mapTestMode'] != '1')
              TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                tileProvider: NetworkTileProvider(headers: {
                  'User-Agent': 'FleetBridgePortfolio/1.0 (+https://github.com/CodingBot000/FleetBridge)',
                }),
                errorTileCallback: (tile, error, stackTrace) {
                  if (mounted && !mapLoadFailed) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && !mapLoadFailed) setState(() => mapLoadFailed = true);
                    });
                  }
                }),
            MarkerLayer(markers: [Marker(point: LatLng(latitude.toDouble(), longitude.toDouble()),
              child: const Icon(Icons.location_on, color: Colors.red, size: 36))]),
            SimpleAttributionWidget(source: const Text('OpenStreetMap contributors'),
              onTap: () => channel.invokeMethod<bool>('openMapAttribution')),
          ],
        )),
      if (mapLoadFailed) const Text('지도를 불러올 수 없습니다. 네트워크 연결을 확인해 주세요.'),
      const SizedBox(height: 20),
      Text('냉동기 원격 명령 (시뮬레이션)', style: Theme.of(context).textTheme.titleMedium),
      const Text('실제 차량에는 명령이 전송되지 않습니다.'),
      Text('현재: ${vehicle['refrigerationOn'] == true ? '켜짐' : '꺼짐'}'),
      DropdownButton<String>(value: scenario, onChanged: pending ? null : (value) {
        if (value != null) setState(() => scenario = value);
      }, items: const [
        DropdownMenuItem(value: 'success', child: Text('성공 시나리오')),
        DropdownMenuItem(value: 'failure', child: Text('실패 시나리오')),
        DropdownMenuItem(value: 'timeout', child: Text('시간 초과 시나리오')),
      ]),
      FilledButton(onPressed: pending || status == 'offline' ? null : sendCommand,
        child: Text(pending ? '처리 중…' : '냉동기 전환')),
      if (result != null) Text({'success': '명령 성공', 'failure': '명령 실패',
        'timeout': '응답 시간 초과', 'busy': '명령 처리 중'}[result] ?? '명령 실패'),
    ]);
  }
}
