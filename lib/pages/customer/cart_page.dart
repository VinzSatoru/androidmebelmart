import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:mebelmart_furniture/providers/app_state.dart';
import 'package:mebelmart_furniture/theme/app_theme.dart';
import 'package:mebelmart_furniture/pages/customer/checkout_page.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  Map<String, dynamic>? cartData;
  bool isLoading = true;
  String? errorMessage;

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
  void initState() {
    super.initState();
    loadCart();
  }

  Future<void> loadCart() async {
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

      print('Loading cart for user: $userId');

      final response = await http.get(
        Uri.parse('http://192.168.180.94:44800/api/carts/$userId'),
      );

      print('Cart response status: ${response.statusCode}');
      print('Cart response body: ${response.body}');

      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body);
        print('Decoded cart data: $decodedData');
        setState(() {
          cartData = decodedData;
          isLoading = false;
        });
      } else if (response.statusCode == 404) {
        setState(() {
          cartData = null;
          errorMessage = 'Keranjang belanja kosong';
          isLoading = false;
        });
      } else {
        throw Exception('Gagal memuat keranjang: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading cart: $e');
      setState(() {
        cartData = null;
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> deleteCartItem(String itemId) async {
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final userId = appState.userData!['user']?['_id'];

      print('Deleting item: $itemId for user: $userId');

      final response = await http.delete(
        Uri.parse(
            'http://192.168.180.94:44800/api/carts/$userId/items/$itemId'),
      );

      print('Delete response status: ${response.statusCode}');
      print('Delete response body: ${response.body}');

      if (response.statusCode == 200) {
        // Refresh cart after successful deletion
        loadCart();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produk berhasil dihapus dari keranjang'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        String errorMessage = 'Gagal menghapus item';
        try {
          if (response.body.isNotEmpty) {
            final errorBody = json.decode(response.body);
            errorMessage = errorBody['message'] ?? 'Gagal menghapus item';
          }
        } catch (e) {
          print('Error parsing response body: $e');
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Error deleting item: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> showDeleteConfirmation(String itemId, String productName) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Konfirmasi Hapus',
            style: TextStyle(fontFamily: 'Poppins'),
          ),
          content: Text(
            'Apakah Anda yakin ingin menghapus "$productName" dari keranjang?',
            style: TextStyle(fontFamily: 'Poppins'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Batal',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: Colors.grey,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                deleteCartItem(itemId);
              },
              child: Text(
                'Hapus',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: Colors.red,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Keranjang Belanja',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppTheme.darkColors['primary'],
      ),
      body: RefreshIndicator(
        onRefresh: loadCart,
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            AppTheme.darkColors['accent']!,
          ),
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              errorMessage!,
              style: TextStyle(
                color: Colors.red,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: loadCart,
              child: Text(
                'Coba Lagi',
                style: TextStyle(fontFamily: 'Poppins'),
              ),
            ),
          ],
        ),
      );
    }

    if (cartData == null ||
        cartData!['items'] == null ||
        (cartData!['items'] as List).isEmpty) {
      return Center(
        child: Text(
          'Keranjang Belanja Kosong',
          style: TextStyle(
            fontSize: 16,
            fontFamily: 'Poppins',
          ),
        ),
      );
    }

    final items = cartData!['items'] as List;
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index] as Map<String, dynamic>;
              final product = (item['product'] ?? {}) as Map<String, dynamic>;

              print('Cart item $index details:');
              print('- Item ID: ${item['_id']}');
              print('- Product: $product');
              print('- Full item data: $item');

              final String productName = product['name'] ??
                  item['productName'] ??
                  'Produk tidak diketahui';

              final String? category = product['category'] ?? item['category'];

              return Card(
                elevation: 2,
                margin: EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Category Icon
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppTheme.darkColors['surface'],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            getCategoryImage(category, productName),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              _getCategoryIcon(category),
                              size: 30,
                              color: AppTheme.darkColors['accent'],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              productName,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Jumlah: ${item['quantity']?.toString() ?? '0'}',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              NumberFormat.currency(
                                locale: 'id_ID',
                                symbol: 'Rp ',
                                decimalDigits: 0,
                              ).format(item['subtotal'] ?? 0),
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                                color: AppTheme.darkColors['accent'],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        onPressed: () => showDeleteConfirmation(
                          item['_id'] ?? item['productId'],
                          productName,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        // Total section at the bottom
        if (cartData != null && cartData!['total'] != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total:',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      NumberFormat.currency(
                        locale: 'id_ID',
                        symbol: 'Rp ',
                        decimalDigits: 0,
                      ).format(cartData!['total'] ?? 0),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                        color: AppTheme.darkColors['accent'],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CheckoutPage(
                            cartData: cartData!,
                          ),
                        ),
                      );

                      // If order was successful, refresh the cart
                      if (result == true) {
                        loadCart();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.darkColors['accent'],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Checkout',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
