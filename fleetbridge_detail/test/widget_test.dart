import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleetbridge_detail/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('shows vehicle supplied by native host', (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getVehicle') return {'name': '차량 1', 'model': 'Model 1'};
      return null;
    });
    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: VehicleDetail(id: 'vehicle-1'))));
    await tester.pumpAndSettle();
    expect(find.text('차량 1'), findsOneWidget);
    expect(find.text('Model 1'), findsOneWidget);
  });
  testWidgets('shows error when vehicle is missing', (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async => null);
    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: VehicleDetail(id: 'missing'))));
    await tester.pumpAndSettle();
    expect(find.text('차량 정보를 불러올 수 없습니다.'), findsOneWidget);
  });
  testWidgets('shows an error when native reports an invalid vehicle ID', (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(code: 'not_found');
    });
    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: VehicleDetail(id: 'invalid'))));
    await tester.pumpAndSettle();
    expect(find.text('차량 정보를 불러올 수 없습니다.'), findsOneWidget);
  });
  testWidgets('retries a request until the native handler is registered', (tester) async {
    var calls = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      calls++;
      if (calls == 1) throw MissingPluginException();
      return {'name': '차량 1', 'model': 'Model 1'};
    });
    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: VehicleDetail(id: 'vehicle-1'))));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 110));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.text('Model 1'), findsOneWidget);
  });
}
