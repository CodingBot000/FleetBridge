import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

class VehicleDetail extends ConsumerWidget {
  const VehicleDetail({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        data: (vehicle) => Column(mainAxisSize: MainAxisSize.min, children: [
          Text(vehicle['name'] as String), Text(vehicle['model'] as String), Text(id),
        ]),
      )),
    );
  }
}
