import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:mebelmart_furniture/providers/app_state.dart';
import 'package:mebelmart_furniture/theme/app_theme.dart';

class CheckoutPage extends StatefulWidget {
  final Map<String, dynamic> cartData;

  const CheckoutPage({super.key, required this.cartData});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill form with user data
    final userData = context.read<AppState>().userData?['user'];
    if (userData != null) {
      _fullNameController.text = userData['fullName'] ?? '';
      _phoneController.text = userData['phoneNumber'] ?? '';
      _addressController.text = userData['address'] ?? '';
    }
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final appState = context.read<AppState>();
      final userId = appState.userData!['user']['_id'];

      // Generate orderId
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final orderId = 'ORD$timestamp';

      final orderData = {
        'orderId': orderId,
        'userId': userId,
        'items': widget.cartData['items']
            .map((item) => {
                  'productId': item['productId'] ?? '',
                  'productName':
                      item['product']?['name'] ?? 'Produk tidak diketahui',
                  'category':
                      item['product']?['category'] ?? 'Tidak ada kategori',
                  'price': item['product']?['price'] ?? 0,
                  'quantity': item['quantity'] ?? 1,
                  'subtotal': item['subtotal'] ?? 0,
                })
            .toList(),
        'totalAmount': widget.cartData['total'] ?? 0,
        'shippingAddress': {
          'fullName': _fullNameController.text.trim(),
          'phoneNumber': _phoneController.text.trim(),
          'address': _addressController.text.trim(),
          'city': _cityController.text.trim(),
          'postalCode': _postalCodeController.text.trim(),
        },
        'paymentStatus': 'PENDING',
        'orderStatus': 'PENDING',
        'paymentMethod': 'CASH_ON_DELIVERY',
        'orderDate': DateTime.now().toIso8601String(),
      };

      try {
        print('Preparing order data...'); // Debug log
        final jsonData = json.encode(orderData);
        print('Order data prepared: $jsonData'); // Debug log

        // Create order
        print('Sending order to server...'); // Debug log
        final orderResponse = await http.post(
          Uri.parse('http://192.168.180.94:44800/api/orders'),
          headers: {'Content-Type': 'application/json'},
          body: jsonData,
        );

        print(
            'Order response status: ${orderResponse.statusCode}'); // Debug log
        print('Order response body: ${orderResponse.body}'); // Debug log

        if (orderResponse.statusCode != 201) {
          throw Exception('Gagal membuat pesanan: ${orderResponse.body}');
        }

        // Clear cart after successful order
        print('Clearing cart...'); // Debug log
        final cartResponse = await http.delete(
          Uri.parse('http://192.168.180.94:44800/api/carts/$userId'),
        );

        print(
            'Cart deletion response status: ${cartResponse.statusCode}'); // Debug log

        if (!mounted) return;

        // Show success message and navigate back
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pesanan berhasil dibuat!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back to cart page
        Navigator.of(context).pop(true); // true indicates successful order
      } catch (e) {
        print('Error in order process: $e'); // Debug log
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error creating order: $e'); // Debug log
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Checkout',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Summary
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ringkasan Pesanan',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darkColors['text'],
                          ),
                        ),
                        const Divider(),
                        ...widget.cartData['items'].map<Widget>((item) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['product']['name'],
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        'Jumlah: ${item['quantity']}',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          color: AppTheme
                                              .darkColors['textSecondary'],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  NumberFormat.currency(
                                    locale: 'id_ID',
                                    symbol: 'Rp ',
                                    decimalDigits: 0,
                                  ).format(item['subtotal']),
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    color: AppTheme.darkColors['accent'],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total:',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              NumberFormat.currency(
                                locale: 'id_ID',
                                symbol: 'Rp ',
                                decimalDigits: 0,
                              ).format(widget.cartData['total']),
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppTheme.darkColors['accent'],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Shipping Information
                Text(
                  'Informasi Pengiriman',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkColors['text'],
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Lengkap',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nama lengkap harus diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Nomor Telepon',
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nomor telepon harus diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Alamat',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Alamat harus diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(
                    labelText: 'Kota',
                    prefixIcon: Icon(Icons.location_city),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Kota harus diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _postalCodeController,
                  decoration: const InputDecoration(
                    labelText: 'Kode Pos',
                    prefixIcon: Icon(Icons.local_post_office),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Kode pos harus diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Place Order Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _placeOrder,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppTheme.darkColors['accent'],
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Buat Pesanan',
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
        ),
      ),
    );
  }
}
