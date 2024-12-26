import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:mebelmart_furniture/theme/app_theme.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  List<dynamic> orders = [];
  bool isLoading = true;
  String? selectedFilter;

  final List<String> statusFilters = [
    'SEMUA',
    'PENDING',
    'PROCESSING',
    'SHIPPED',
    'DELIVERED',
    'CANCELLED'
  ];

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    try {
      setState(() => isLoading = true);

      print('Fetching orders from admin panel...');
      final response = await http.get(
        Uri.parse('http://192.168.180.94:44800/api/orders/all'),
        headers: {'Content-Type': 'application/json'},
      );

      print('Response status: ${response.statusCode}');
      print('Response body length: ${response.body.length}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> allOrders = json.decode(response.body);
        print('Decoded ${allOrders.length} orders');

        setState(() {
          if (selectedFilter != null && selectedFilter != 'SEMUA') {
            print('Filtering by status: $selectedFilter');
            orders = allOrders
                .where((order) =>
                    order['orderStatus'].toString().toUpperCase() ==
                    selectedFilter)
                .toList();
            print('Found ${orders.length} orders with status $selectedFilter');
          } else {
            orders = allOrders;
            print('Showing all ${orders.length} orders');
          }
          isLoading = false;
        });
      } else {
        print('Error response: ${response.body}');
        throw Exception('Gagal memuat data pesanan: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching orders: $e');
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Coba Lagi',
              textColor: Colors.white,
              onPressed: () => fetchOrders(),
            ),
          ),
        );
      }
    }
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      final response = await http.put(
        Uri.parse('http://192.168.180.94:44800/api/orders/$orderId/status'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'status': newStatus}),
      );

      if (response.statusCode == 200) {
        fetchOrders();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Status pesanan berhasil diubah ke ${_getStatusText(newStatus)}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Gagal mengubah status pesanan');
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

  void _showStatusUpdateDialog(String orderId, String currentStatus) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Ubah Status Pesanan',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            color: AppTheme.darkColors['text'],
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Pilih status baru:',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: AppTheme.darkColors['textSecondary'],
              ),
            ),
            const SizedBox(height: 16),
            ...['PENDING', 'PROCESSING', 'SHIPPED', 'DELIVERED', 'CANCELLED']
                .where((status) => status != currentStatus)
                .map((status) => ListTile(
                      title: Text(
                        _getStatusText(status),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: _getStatusColor(status),
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _updateOrderStatus(orderId, status);
                      },
                      tileColor: AppTheme.darkColors['surface'],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ))
                .toList(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: AppTheme.darkColors['textSecondary'],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(String status) {
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

  Color _getStatusColor(String status) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Kelola Pesanan',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          // Status Filter
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: statusFilters.length,
              itemBuilder: (context, index) {
                final status = statusFilters[index];
                final isSelected = selectedFilter == status ||
                    (selectedFilter == null && status == 'SEMUA');
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      status == 'SEMUA'
                          ? 'Semua Pesanan'
                          : _getStatusText(status),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: isSelected
                            ? Colors.white
                            : AppTheme.darkColors['textSecondary'],
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (bool selected) {
                      setState(() {
                        selectedFilter = selected ? status : null;
                      });
                      fetchOrders();
                    },
                    backgroundColor: AppTheme.darkColors['surface'],
                    selectedColor: AppTheme.darkColors['accent'],
                    checkmarkColor: Colors.white,
                  ),
                );
              },
            ),
          ),

          // Orders List
          Expanded(
            child: isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.darkColors['accent']!,
                      ),
                    ),
                  )
                : orders.isEmpty
                    ? Center(
                        child: Text(
                          'Tidak ada pesanan',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: AppTheme.darkColors['textSecondary'],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: fetchOrders,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: orders.length,
                          itemBuilder: (context, index) {
                            final order = orders[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: ExpansionTile(
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Order #${order['orderId']}',
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontWeight: FontWeight.w600,
                                              color:
                                                  AppTheme.darkColors['text'],
                                            ),
                                          ),
                                          Text(
                                            DateFormat('dd MMM yyyy, HH:mm')
                                                .format(
                                              DateTime.parse(
                                                  order['orderDate'] ??
                                                      order['createdAt'] ??
                                                      DateTime.now()
                                                          .toIso8601String()),
                                            ),
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 12,
                                              color: AppTheme
                                                  .darkColors['textSecondary'],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(
                                                order['orderStatus'])
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        _getStatusText(order['orderStatus']),
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 12,
                                          color: _getStatusColor(
                                              order['orderStatus']),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Customer Info
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color:
                                                AppTheme.darkColors['surface'],
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Informasi Pelanggan',
                                                style: TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontWeight: FontWeight.w600,
                                                  color: AppTheme
                                                      .darkColors['text'],
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                order['shippingAddress']
                                                        ?['fullName'] ??
                                                    'Nama tidak tersedia',
                                                style: TextStyle(
                                                  fontFamily: 'Poppins',
                                                  color: AppTheme
                                                      .darkColors['text'],
                                                ),
                                              ),
                                              Text(
                                                order['shippingAddress']
                                                        ?['phoneNumber'] ??
                                                    'No telepon tidak tersedia',
                                                style: TextStyle(
                                                  fontFamily: 'Poppins',
                                                  color: AppTheme.darkColors[
                                                      'textSecondary'],
                                                ),
                                              ),
                                              Text(
                                                order['shippingAddress']
                                                        ?['address'] ??
                                                    'Alamat tidak tersedia',
                                                style: TextStyle(
                                                  fontFamily: 'Poppins',
                                                  color: AppTheme.darkColors[
                                                      'textSecondary'],
                                                ),
                                              ),
                                              Text(
                                                '${order['shippingAddress']?['city'] ?? 'Kota tidak tersedia'}, ${order['shippingAddress']?['postalCode'] ?? '-'}',
                                                style: TextStyle(
                                                  fontFamily: 'Poppins',
                                                  color: AppTheme.darkColors[
                                                      'textSecondary'],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 16),

                                        // Order Items
                                        Text(
                                          'Detail Pesanan:',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.darkColors['text'],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        ...List.generate(
                                          order['items'].length,
                                          (index) => ListTile(
                                            contentPadding: EdgeInsets.zero,
                                            title: Text(
                                              order['items'][index]
                                                      ?['productName'] ??
                                                  'Produk tidak diketahui',
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                                color:
                                                    AppTheme.darkColors['text'],
                                              ),
                                            ),
                                            subtitle: Text(
                                              '${order['items'][index]?['quantity'] ?? 0} x ${NumberFormat.currency(
                                                locale: 'id_ID',
                                                symbol: 'Rp ',
                                                decimalDigits: 0,
                                              ).format(order['items'][index]?['price'] ?? 0)}',
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                                color: AppTheme.darkColors[
                                                    'textSecondary'],
                                              ),
                                            ),
                                            trailing: Text(
                                              NumberFormat.currency(
                                                locale: 'id_ID',
                                                symbol: 'Rp ',
                                                decimalDigits: 0,
                                              ).format(order['items'][index]
                                                      ?['subtotal'] ??
                                                  0),
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                                fontWeight: FontWeight.w600,
                                                color: AppTheme
                                                    .darkColors['accent'],
                                              ),
                                            ),
                                          ),
                                        ),
                                        const Divider(height: 24),

                                        // Total and Actions
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Total Pembayaran:',
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                                fontWeight: FontWeight.w600,
                                                color:
                                                    AppTheme.darkColors['text'],
                                              ),
                                            ),
                                            Text(
                                              NumberFormat.currency(
                                                locale: 'id_ID',
                                                symbol: 'Rp ',
                                                decimalDigits: 0,
                                              ).format(
                                                  order['totalAmount'] ?? 0),
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16,
                                                color: AppTheme
                                                    .darkColors['accent'],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                            onPressed: () =>
                                                _showStatusUpdateDialog(
                                              order['_id'],
                                              order['orderStatus'],
                                            ),
                                            icon: const Icon(Icons.edit),
                                            label: const Text(
                                              'Ubah Status Pesanan',
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  AppTheme.darkColors['accent'],
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 12),
                                            ),
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
                      ),
          ),
        ],
      ),
    );
  }
}
