import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:mebelmart_furniture/constants/api_constants.dart';
import 'package:mebelmart_furniture/theme/app_theme.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  List<dynamic> products = [];
  bool isLoading = true;
  List<String> categories = [
    'Kursi',
    'Meja',
    'Lemari',
    'Tempat Tidur',
    'Sofa',
  ];

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.products),
        headers: {'Content-Type': 'application/json'},
      );

      print('Products response: ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        setState(() {
          products = json.decode(response.body);
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching products: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> addProduct(Map<String, dynamic> productData) async {
    try {
      print('Sending product data: $productData'); // Debug log

      final response = await http
          .post(
        Uri.parse(ApiConstants.products),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(productData),
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Connection timed out. Please try again.');
        },
      );

      print('Add product response status: ${response.statusCode}'); // Debug log
      print('Add product response body: ${response.body}'); // Debug log

      if (response.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produk berhasil ditambahkan'),
            backgroundColor: Colors.green,
          ),
        );
        fetchProducts(); // Refresh list
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menambahkan produk: ${response.body}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error adding product: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> updateProduct(
      String id, Map<String, dynamic> productData) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConstants.products}/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(productData),
      );

      print('Update product response: ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        fetchProducts(); // Refresh list
      }
    } catch (e) {
      print('Error updating product: $e');
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      print('Deleting product with id: $id'); // Debug log

      final response = await http.delete(
        Uri.parse('${ApiConstants.products}/$id'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Connection timeout. Please try again.');
        },
      );

      print('Delete response status: ${response.statusCode}'); // Debug log
      print('Delete response body: ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produk berhasil dihapus'),
            backgroundColor: Colors.green,
          ),
        );
        await fetchProducts(); // Refresh list
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus produk: ${response.body}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error deleting product: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor: Colors.red,
        ),
      );
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

  void _showProductImage(BuildContext context, String? category,
      String? productName, String heroTag) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Hero(
              tag: heroTag,
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.darkColors['surface'],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    getCategoryImage(category, productName),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      print('Error loading image: $error');
                      return Container(
                        color: AppTheme.darkColors['background'],
                        child: const Icon(Icons.image_not_supported),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
              color: Colors.white,
              iconSize: 30,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Produk'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showAddEditProductDialog(context);
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : products.isEmpty
              ? const Center(child: Text('Tidak ada produk'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        leading: GestureDetector(
                          onTap: () => _showProductImage(
                            context,
                            product['category'],
                            product['name'],
                            product['_id'],
                          ),
                          child: Hero(
                            tag: product['_id'],
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Image.asset(
                                getCategoryImage(
                                    product['category'], product['name']),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  print('Error loading image: $error');
                                  return const Icon(Icons.image_not_supported);
                                },
                              ),
                            ),
                          ),
                        ),
                        title: Text(product['name']),
                        subtitle: Text(
                          NumberFormat.currency(
                            locale: 'id_ID',
                            symbol: 'Rp ',
                            decimalDigits: 0,
                          ).format(product['price']),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                _showAddEditProductDialog(context,
                                    product: product);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              color: Colors.red,
                              onPressed: () {
                                _showDeleteConfirmation(context, product);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Future<void> _showAddEditProductDialog(BuildContext context,
      {Map<String, dynamic>? product}) async {
    final nameController = TextEditingController(text: product?['name'] ?? '');
    final priceController =
        TextEditingController(text: product?['price']?.toString() ?? '');
    final stockController =
        TextEditingController(text: product?['stock']?.toString() ?? '');
    final descriptionController =
        TextEditingController(text: product?['description'] ?? '');
    String selectedCategory = product?['category'] ?? categories[0];

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product == null ? 'Tambah Produk' : 'Edit Produk'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Produk',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  border: OutlineInputBorder(),
                ),
                items: categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (newValue) {
                  if (newValue != null) {
                    selectedCategory = newValue;
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'Harga',
                  border: OutlineInputBorder(),
                  prefixText: 'Rp ',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: stockController,
                decoration: const InputDecoration(
                  labelText: 'Stok',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final productData = {
                'name': nameController.text,
                'category': selectedCategory,
                'price': int.tryParse(priceController.text
                        .replaceAll(RegExp(r'[^0-9]'), '')) ??
                    0,
                'stock': int.tryParse(stockController.text) ?? 0,
                'description': descriptionController.text,
                'image': 'https://via.placeholder.com/150',
              };

              if (product == null) {
                await addProduct(productData);
              } else {
                await updateProduct(product['_id'], productData);
              }

              if (!context.mounted) return;
              Navigator.pop(context);
            },
            child: Text(product == null ? 'Tambah' : 'Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteConfirmation(
      BuildContext context, Map<String, dynamic> product) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Apakah Anda yakin ingin menghapus ${product['name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              try {
                Navigator.pop(context); // Tutup dialog terlebih dahulu
                await deleteProduct(product['_id']);
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Gagal menghapus produk: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
