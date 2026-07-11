import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

void main() => runApp(const KontakApp());

abstract class KontakStore {
  Future<List<Map<String, String>>> getKontak();
  Future<void> addKontak(String nama, String nomor);
  Future<void> deleteKontak(int id);
}

class SqliteKontakStore implements KontakStore {
  Database? _database;

  Future<Database> get _db async {
    if (_database != null) return _database!;

    final dir = await getDatabasesPath();
    _database = await openDatabase(
      '$dir/kontak.db',
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE kontak('
          'id INTEGER PRIMARY KEY AUTOINCREMENT, '
          'nama TEXT NOT NULL, '
          'nomor TEXT NOT NULL'
          ')',
        );
      },
    );
    return _database!;
  }

  @override
  Future<List<Map<String, String>>> getKontak() async {
    final db = await _db;
    final rows = await db.query('kontak', orderBy: 'id DESC');
    return rows.map((row) => {
      'id': row['id'].toString(),
      'nama': row['nama']! as String,
      'nomor': row['nomor']! as String,
    }).toList();
  }

  @override
  Future<void> addKontak(String nama, String nomor) async {
    final db = await _db;
    await db.insert('kontak', {'nama': nama, 'nomor': nomor});
  }

  @override
  Future<void> deleteKontak(int id) async {
    final db = await _db;
    await db.delete('kontak', where: 'id = ?', whereArgs: [id]);
  }
}

class KontakApp extends StatelessWidget {
  const KontakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(scaffoldBackgroundColor: const Color(0xFFF5F5F0)),
      home: HalamanKontak(store: SqliteKontakStore()),
    );
  }
}

class HalamanKontak extends StatefulWidget {
  const HalamanKontak({super.key, required this.store});
  final KontakStore store;

  @override
  State<HalamanKontak> createState() => _HalamanKontakState();
}

class _HalamanKontakState extends State<HalamanKontak> {
  final namaController = TextEditingController();
  final nomorController = TextEditingController();

  List<Map<String, String>> daftarKontak = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadKontak();
  }

  Future<void> _loadKontak() async {
    final data = await widget.store.getKontak();
    if (!mounted) return;
    setState(() {
      daftarKontak = data;
      _isLoading = false;
    });
  }

  Future<void> tambahKontak() async {
    if (namaController.text.isEmpty || nomorController.text.isEmpty) return;

    final nama = namaController.text;
    final nomor = nomorController.text;

    await widget.store.addKontak(nama, nomor);
    if (!mounted) return;

    namaController.clear();
    nomorController.clear();
    _loadKontak();
  }

  Future<void> hapusKontak(int id) async {
    await widget.store.deleteKontak(id);
    if (!mounted) return;
    _loadKontak();
  }

  Widget buildInput(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF555555)),
        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF333333))),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFE8E0D0))),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F0),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('KONTAK', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 6, color: Color(0xFF1A1A1A))),
            Text('${daftarKontak.length} tersimpan', style: const TextStyle(fontSize: 11, color: Color(0xFF888888))),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
         
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(20)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('TAMBAH BARU', style: TextStyle(color: Color(0xFF888888), fontSize: 11, letterSpacing: 2)),
                  const SizedBox(height: 14),
                  buildInput(namaController, 'Nama lengkap'),
                  const SizedBox(height: 14),
                  buildInput(nomorController, 'Nomor HP'),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: tambahKontak,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE8E0D0),
                        foregroundColor: const Color(0xFF1A1A1A),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('TAMBAH KONTAK', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text('DAFTAR KONTAK', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 3, color: Color(0xFF888888))),
            const SizedBox(height: 12),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : daftarKontak.isEmpty
                      ? const Center(child: Text('Belum ada kontak.', style: TextStyle(color: Color(0xFF888888))))
                      : ListView.separated(
                          itemCount: daftarKontak.length,
                          separatorBuilder: (_, __) => const Divider(color: Color(0xFFE0E0D8)),
                          itemBuilder: (context, index) {
                            final kontak = daftarKontak[index];
                            return Row(
                              children: [
                                Text('${(index + 1).toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 11, color: Color(0xFFBBBBBB))),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(kontak['nama']!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
                                      Text(kontak['nomor']!, style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => hapusKontak(int.parse(kontak['id']!)),
                                  child: const Text('✕', style: TextStyle(color: Color(0xFFCCCCCC), fontSize: 13)),
                                ),
                              ],
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}