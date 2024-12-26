import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:mebelmart_furniture/providers/app_state.dart';
import 'package:mebelmart_furniture/theme/app_theme.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  List<dynamic> orders = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadOrders();
  }

  Future<void> loadOrders() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      if (!appState.isLoggedIn || appState.userData == null) {
        throw Exception('Silakan login terlebih dahulu');
      }

      final userId = appState.userData!['user']?['_id'];
      if (userId == null) {
        throw Exception('Data pengguna tidak valid');
      }

      final response = await http.get(
        Uri.parse('http://192.168.180.94:44800/api/orders/$userId'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          orders = data;
          isLoading = false;
        });
      } else {
        throw Exception('Gagal memuat pesanan');
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _updateOrderStatus(String orderId, String status) async {
    try {
      final response = await http.put(
        Uri.parse('http://192.168.180.94:44800/api/orders/$orderId/status'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'status': status}),
      );

      if (response.statusCode == 200) {
        loadOrders(); // Refresh the orders list
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pembayaran Sukses, Pesanan diproses'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Gagal melakukan pembayaran');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showPaymentConfirmation(String orderId) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Konfirmasi Pembayaran',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            color: AppTheme.darkColors['text'],
          ),
        ),
        content: Text(
          'Apakah Anda yakin akan membayar sekarang?',
          style: TextStyle(
            fontFamily: 'Poppins',
            color: AppTheme.darkColors['textSecondary'],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Tidak',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: AppTheme.darkColors['textSecondary'],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateOrderStatus(orderId, 'PROCESSING');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.darkColors['accent'],
            ),
            child: const Text(
              'Ya',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getOrderStatusText(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'Menunggu Pembayaran';
      case 'PROCESSING':
        return 'Sedang Diproses';
      case 'SHIPPED':
        return 'Dalam Pengiriman';
      case 'DELIVERED':
        return 'Terkirim';
      case 'CANCELLED':
        return 'Dibatalkan';
      default:
        return 'Status Tidak Diketahui';
    }
  }

  Color _getOrderStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.orange;
      case 'PROCESSING':
        return Colors.blue;
      case 'SHIPPED':
        return Colors.purple;
      case 'DELIVERED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String getCategoryImage(String? category, String? productName) {
    if (productName != null) {
      switch (productName.toLowerCase()) {
        case 'kursi makan minimalis':
          return 'assets/images/kursi_makan.png';
        case 'meja kerja':
          return 'assets/images/meja_kerja.png';
        case 'sofa toxedo':
          return 'assets/images/sofa_toxedo.png';
        case 'lemari 3 pintu':
          return 'assets/images/lemari_3_pintu.png';
        case 'kursi gajah':
          return 'assets/images/kursi_gajah.png';
        case 'sofa emyu':
          return 'assets/images/sofa_emyu.png';
        case 'sofa classic':
          return 'assets/images/sofa_classic.png';
        case 'lemari buku':
          return 'assets/images/lemari_buku.png';
      }
    }

    // Fallback to category-based images
    switch (category?.toLowerCase()) {
      case 'kursi':
        return 'assets/images/chair.png';
      case 'meja':
        return 'assets/images/table.png';
      case 'lemari':
        return 'assets/images/cabinet.png';
      case 'tempat tidur':
        return 'assets/images/bed.png';
      case 'sofa':
        return 'assets/images/sofa.png';
      default:
        return 'assets/images/furniture.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pesanan Saya',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: loadOrders,
        child: isLoading
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.darkColors['accent']!,
                  ),
                ),
              )
            : errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: AppTheme.darkColors['error'],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          errorMessage!,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: AppTheme.darkColors['error'],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: loadOrders,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.darkColors['accent'],
                          ),
                          child: const Text(
                            'Coba Lagi',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : orders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shopping_bag_outlined,
                              size: 64,
                              color: AppTheme.darkColors['textSecondary'],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Belum ada pesanan',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.darkColors['text'],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Mulai belanja sekarang!',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: AppTheme.darkColors['textSecondary'],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: orders.length,
                        itemBuilder: (context, index) {
                          final order = orders[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    alignment: WrapAlignment.spaceBetween,
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      Text(
                                        'Order #${order['orderId']}',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                          color: AppTheme.darkColors['text'],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getOrderStatusColor(
                                                  order['orderStatus'])
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          _getOrderStatusText(
                                              order['orderStatus']),
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 12,
                                            color: _getOrderStatusColor(
                                                order['orderStatus']),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 24),
                                  ...List.generate(
                                    order['items'].length,
                                    (itemIndex) {
                                      final item = order['items'][itemIndex];
                                      final productName = item['productName'] ??
                                          item['name'] ??
                                          'Produk tidak diketahui';
                                      final productPrice =
                                          item['subtotal'] / item['quantity'];
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 12),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              width: 50,
                                              height: 50,
                                              decoration: BoxDecoration(
                                                color: AppTheme
                                                    .darkColors['surface'],
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: Image.asset(
                                                  getCategoryImage(
                                                      item['category'],
                                                      productName),
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error,
                                                          stackTrace) =>
                                                      Icon(
                                                    _getCategoryIcon(
                                                        item['category']),
                                                    size: 24,
                                                    color: AppTheme
                                                        .darkColors['accent'],
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    productName,
                                                    style: TextStyle(
                                                      fontFamily: 'Poppins',
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: AppTheme
                                                          .darkColors['text'],
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    '${item['quantity']} x ${NumberFormat.currency(
                                                      locale: 'id_ID',
                                                      symbol: 'Rp ',
                                                      decimalDigits: 0,
                                                    ).format(productPrice)}',
                                                    style: TextStyle(
                                                      fontFamily: 'Poppins',
                                                      fontSize: 12,
                                                      color:
                                                          AppTheme.darkColors[
                                                              'textSecondary'],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                  const Divider(height: 24),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Total Pembayaran',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        NumberFormat.currency(
                                          locale: 'id_ID',
                                          symbol: 'Rp ',
                                          decimalDigits: 0,
                                        ).format(order['totalAmount']),
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                          color: AppTheme.darkColors['accent'],
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (order['orderStatus']
                                          .toString()
                                          .toUpperCase() ==
                                      'PENDING')
                                    Padding(
                                      padding: const EdgeInsets.only(top: 16),
                                      child: SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: () =>
                                              _showPaymentConfirmation(
                                                  order['_id']),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                AppTheme.darkColors['accent'],
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 12),
                                          ),
                                          child: const Text(
                                            'Bayar Sekarang',
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }

  IconData _getCategoryIcon(String? category) {
    switch (category) {
      case 'Meja':
        return Icons.table_restaurant;
      case 'Kursi':
        return Icons.chair;
      case 'Lemari':
        return Icons.door_sliding;
      case 'Sofa':
        return Icons.weekend;
      case 'Tempat':
        return Icons.bed;
      default:
        return Icons.category;
    }
  }
}
