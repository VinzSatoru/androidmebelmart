import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mebelmart_furniture/theme/app_theme.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int totalRevenue = 0;
  int totalCustomers = 0;
  int newOrders = 0;
  int activeProducts = 0;
  bool isLoading = true;
  List<Map<String, dynamic>> recentActivities = [];

  @override
  void initState() {
    super.initState();
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    try {
      // Fetch total revenue and new orders from orders collection
      final ordersResponse = await http.get(
        Uri.parse('http://192.168.180.94:44800/api/orders/all'),
        headers: {'Content-Type': 'application/json'},
      );

      // Fetch customers count
      final customersResponse = await http.get(
        Uri.parse('http://192.168.180.94:44800/api/users'),
        headers: {'Content-Type': 'application/json'},
      );

      // Fetch products count
      final productsResponse = await http.get(
        Uri.parse('http://192.168.180.94:44800/api/products'),
        headers: {'Content-Type': 'application/json'},
      );

      if (ordersResponse.statusCode == 200 &&
          customersResponse.statusCode == 200 &&
          productsResponse.statusCode == 200) {
        final orders = json.decode(ordersResponse.body) as List;
        final customers = json.decode(customersResponse.body) as List;
        final products = json.decode(productsResponse.body) as List;

        // Calculate total revenue from all orders
        final revenue = orders.fold<int>(
          0,
          (sum, order) {
            final amount = order['totalAmount'];
            if (amount == null) return sum;
            if (amount is int) return sum + amount;
            if (amount is double) return sum + amount.toInt();
            if (amount is String) return sum + (int.tryParse(amount) ?? 0);
            return sum;
          },
        );

        // Count new orders (orders with PENDING status)
        final pendingOrders = orders
            .where(
              (order) =>
                  order['orderStatus']?.toString().toUpperCase() == 'PENDING',
            )
            .length;

        // Count customers (excluding admin users)
        final customerCount = customers
            .where(
              (user) => user['role']?.toString().toLowerCase() == 'customer',
            )
            .length;

        // Get recent activities from orders
        final recentOrderActivities = orders
            .take(3)
            .map((order) => {
                  'title': _getActivityTitle(order['orderStatus']),
                  'subtitle': _getOrderItems(order['items']),
                  'time': _formatActivityTime(
                      order['orderDate'] ?? order['createdAt']),
                  'color': _getStatusColor(order['orderStatus']),
                })
            .toList();

        if (mounted) {
          setState(() {
            totalRevenue = revenue;
            totalCustomers = customerCount;
            newOrders = pendingOrders;
            activeProducts = products.length;
            recentActivities = recentOrderActivities;
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching dashboard data: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  String _getActivityTitle(String? status) {
    switch (status?.toUpperCase()) {
      case 'PENDING':
        return 'Pesanan Baru';
      case 'PROCESSING':
        return 'Pesanan Diproses';
      case 'SHIPPED':
        return 'Pesanan Dikirim';
      case 'DELIVERED':
        return 'Pesanan Selesai';
      default:
        return 'Status Tidak Diketahui';
    }
  }

  String _getOrderItems(List<dynamic>? items) {
    if (items == null || items.isEmpty) return 'Tidak ada item';
    final firstItem = items.first;
    final itemName = firstItem['productName'] ?? 'Produk tidak diketahui';
    final itemCount = items.length;
    return itemCount > 1
        ? '$itemName dan ${itemCount - 1} item lainnya'
        : itemName;
  }

  String _formatActivityTime(String? dateStr) {
    if (dateStr == null) return 'Waktu tidak diketahui';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 60) {
        return '${difference.inMinutes} menit yang lalu';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} jam yang lalu';
      } else {
        return '${difference.inDays} hari yang lalu';
      }
    } catch (e) {
      return 'Waktu tidak valid';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toUpperCase()) {
      case 'PENDING':
        return const Color(0xFF4CAF50);
      case 'PROCESSING':
        return const Color(0xFF2196F3);
      case 'SHIPPED':
        return const Color(0xFFFF7043);
      case 'DELIVERED':
        return const Color(0xFF9C27B0);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: fetchDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.darkColors['primary']!,
                    AppTheme.darkColors['secondary']!,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selamat Datang, Admin!',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.darkColors['text'],
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          Text(
                            DateFormat.yMMMMEEEEd('id').format(DateTime.now()),
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: AppTheme.darkColors['textSecondary'],
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              AppTheme.darkColors['accent']!.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.notifications_none,
                          color: AppTheme.darkColors['accent'],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Stats Grid
            isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.darkColors['accent']!,
                      ),
                    ),
                  )
                : GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount:
                        MediaQuery.of(context).size.width < 600 ? 2 : 4,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.3,
                    children: [
                      _buildStatCard(
                        title: 'Total Pendapatan',
                        value: NumberFormat.currency(
                          locale: 'id_ID',
                          symbol: 'Rp ',
                          decimalDigits: 0,
                        ).format(totalRevenue),
                        icon: Icons.attach_money,
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF4CAF50),
                            AppTheme.darkColors['accent']!,
                          ],
                        ),
                      ),
                      _buildStatCard(
                        title: 'Total Pelanggan',
                        value: totalCustomers.toString(),
                        icon: Icons.people,
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF2196F3),
                            AppTheme.darkColors['accent']!,
                          ],
                        ),
                      ),
                      _buildStatCard(
                        title: 'Pesanan Baru',
                        value: newOrders.toString(),
                        icon: Icons.shopping_cart,
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFFF7043),
                            AppTheme.darkColors['accent']!,
                          ],
                        ),
                      ),
                      _buildStatCard(
                        title: 'Produk Aktif',
                        value: activeProducts.toString(),
                        icon: Icons.inventory,
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF9C27B0),
                            AppTheme.darkColors['accent']!,
                          ],
                        ),
                      ),
                    ],
                  ),
            const SizedBox(height: 24),

            // Recent Activities
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.darkColors['surface'],
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Aktivitas Terkini',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkColors['text'],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (recentActivities.isEmpty)
                    Center(
                      child: Text(
                        'Belum ada aktivitas',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: AppTheme.darkColors['textSecondary'],
                        ),
                      ),
                    )
                  else
                    ...recentActivities.map((activity) => _buildActivityItem(
                          activity['title'],
                          activity['subtitle'],
                          activity['time'],
                          activity['color'],
                        )),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Quick Actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.darkColors['surface'],
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Aksi Cepat',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkColors['text'],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: _buildQuickAction(
                          'Tambah\nProduk',
                          Icons.add_box,
                          const Color(0xFF4CAF50),
                          () {},
                        ),
                      ),
                      Expanded(
                        child: _buildQuickAction(
                          'Proses\nPesanan',
                          Icons.local_shipping,
                          const Color(0xFF2196F3),
                          () {},
                        ),
                      ),
                      Expanded(
                        child: _buildQuickAction(
                          'Laporan',
                          Icons.bar_chart,
                          const Color(0xFFFF7043),
                          () {},
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Gradient gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  color: Colors.white70,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
    String title,
    String subtitle,
    String time,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.notifications_none, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkColors['text'],
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: AppTheme.darkColors['textSecondary'],
                    fontSize: 12,
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: AppTheme.darkColors['textSecondary'],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: AppTheme.darkColors['text'],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
