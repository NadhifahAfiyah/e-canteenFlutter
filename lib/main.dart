import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kantin Poliwangi',
      theme: ThemeData(primarySwatch: Colors.orange),
      home: const MenuPage(),
    );
  }
}

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  final CollectionReference _menuRef =
      FirebaseFirestore.instance.collection('menus');

  final CollectionReference _orderRef =
      FirebaseFirestore.instance.collection('orders');

  /// Default filter memakai lowercase agar cocok dengan Firestore
  String activeFilter = "semua";

  String formatRupiah(int price) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(price);
  }

  // DIALOG PEMESANAN 
  void _showOrderDialog(String menuName, int price) {
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Pesan $menuName"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: "Nama Pemesan",
            hintText: "Contoh: Budi (TI-2A)",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                _orderRef.add({
                  'menu_item': menuName,
                  'price': price,
                  'customer_name': nameController.text,
                  'status': 'Menunggu',
                  'timestamp': FieldValue.serverTimestamp(),
                });

                Navigator.pop(ctx);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Pesanan berhasil dikirim!")),
                );
              }
            },
            child: const Text("Pesan Sekarang"),
          ),
        ],
      ),
    );
  }

  // STREAM FILTER 
  Stream<QuerySnapshot> getMenuStream() {
    if (activeFilter == "semua") {
      return _menuRef.snapshots();
    } else {
      return _menuRef.where('category', isEqualTo: activeFilter).snapshots();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("E-Canteen Poliwangi"),
      ),

      // FILTER BUTTON 
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            FilterButton(
              label: "Semua",
              active: activeFilter == "semua",
              onTap: () => setState(() => activeFilter = "semua"),
            ),
            FilterButton(
              label: "Makanan",
              active: activeFilter == "makanan",
              onTap: () => setState(() => activeFilter = "makanan"),
            ),
            FilterButton(
              label: "Minuman",
              active: activeFilter == "minuman",
              onTap: () => setState(() => activeFilter = "minuman"),
            ),
          ],
        ),
      ),

      // LIST MENU
      body: StreamBuilder(
        stream: getMenuStream(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Terjadi kesalahan koneksi."));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Menu belum tersedia."));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange.shade100,
                    child: Text(data['name'][0]),
                  ),
                  title: Text(
                    data['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(formatRupiah(data['price'])),
                  trailing: ElevatedButton(
                    onPressed: data['isAvailable'] == true
                        ? () => _showOrderDialog(data['name'], data['price'])
                        : null,
                    child: Text(data['isAvailable'] ? "Pesan" : "Habis"),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// FILTER BUTTON WIDGET 
class FilterButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const FilterButton({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: active ? Colors.orange : Colors.grey,
      ),
      child: Text(label),
    );
  }
}
