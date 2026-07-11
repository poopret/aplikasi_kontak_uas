import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aplikasi_kontak_uas/main.dart';

class FakeKontakStore implements KontakStore {
  final List<Map<String, String>> _data = [];
  int _nextId = 1;

  @override
  Future<List<Map<String, String>>> getKontak() async => List.from(_data);

  @override
  Future<void> addKontak(String nama, String nomor) async {
    _data.insert(0, {'id': '${_nextId++}', 'nama': nama, 'nomor': nomor});
  }

  @override
  Future<void> deleteKontak(int id) async {
    _data.removeWhere((k) => k['id'] == id.toString());
  }
}

void main() {
  testWidgets('Kontak baru muncul di list setelah ditambahkan', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: HalamanKontak(store: FakeKontakStore()),
    ));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Budi');
    await tester.enterText(find.byType(TextField).last, '081234567890');
    await tester.tap(find.text('TAMBAH KONTAK'));
    await tester.pumpAndSettle();

    expect(find.text('Budi'), findsOneWidget);
  });
}