// Mengimpor pustaka utama material design dari Flutter untuk komponen UI
import 'package:flutter/material.dart';
// Mengimpor paket go_router untuk navigasi halaman (seperti menutup halaman menggunakan context.pop())
import 'package:go_router/go_router.dart';
// Mengimpor paket provider untuk mengakses state management dari widget tree
import 'package:provider/provider.dart';

// Mengimpor provider produk untuk memanggil fungsi penambahan produk
import '../providers/product_provider.dart';
// Mengimpor file konfigurasi warna kustom aplikasi
import '../theme/app_colors.dart';
// Mengimpor widget kustom untuk menampilkan pemberitahuan (toast)
import '../widgets/app_toast.dart';
// Mengimpor widget formulir input data produk
import '../widgets/product_form.dart';

// Kelas AddProductScreen berupa StatelessWidget untuk menampilkan halaman tambah produk
class AddProductScreen extends StatelessWidget {
  const AddProductScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Mengatur warna latar belakang halaman menggunakan warna kustom aplikasi
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent, // Menghilangkan warna tint material 3 pada scroll
        foregroundColor: AppColors.ink,       // Warna teks dan ikon pada app bar
        elevation: 0,                         // Menghilangkan bayangan di bawah app bar
        title: const Text(
          'Tambah Produk',
          style: TextStyle(fontWeight: FontWeight.w800), // Judul teks dengan cetak tebal
        ),
      ),
      body: SafeArea(
        child: ProductForm(
          submitLabel: 'Simpan Produk', // Label teks tombol submit pada form
          onSubmit: (data) async {      // Callback ketika formulir disubmit membawa data produk baru
            // Mengambil instance ProductProvider tanpa mendengarkan perubahan (read-only action)
            final provider = context.read<ProductProvider>();
            // Memanggil fungsi addProduct untuk menyimpan data dan menunggu hasilnya (true/false)
            final ok = await provider.addProduct(data);
            
            // Mengecek apakah context masih aktif / mounted setelah proses asynchronous selesai
            if (!context.mounted) return;
            
            // Menampilkan toast notifikasi berhasil atau gagal berdasarkan nilai variabel 'ok'
            showAppToast(
              context,
              message: ok ? 'Produk berhasil ditambahkan' : 'Gagal menambahkan produk',
              icon: ok ? Icons.check_circle_rounded : Icons.error_outline_rounded,
              color: ok ? AppColors.mint : AppColors.pink,
            );
            
            // Jika penambahan berhasil, tutup halaman saat ini dan kembali ke halaman sebelumnya
            if (ok) context.pop();
          },
        ),
      ),
    );
  }
}