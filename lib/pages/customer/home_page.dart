import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:mebelmart_furniture/theme/app_theme.dart';
import 'package:mebelmart_furniture/constants/api_constants.dart';
import 'package:provider/provider.dart';
import 'package:mebelmart_furniture/providers/app_state.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<dynamic> products = [];
  bool isLoading = true;
  String? selectedCategory;

  // Tambahkan variasi warna untuk kategori
  final List<Map<String, dynamic>> categories = [
    {
      'icon': Icons.chair,
      'label': 'Kursi',
      'gradient': const LinearGradient(
        colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
      ),
    },
    {
      'icon': Icons.table_restaurant,
      'label': 'Meja',
      'gradient': const LinearGradient(
        colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
      ),
    },
    {
      'icon': Icons.door_sliding,
      'label': 'Lemari',
      'gradient': const LinearGradient(
        colors: [Color(0xFFFF7043), Color(0xFFE64A19)],
      ),
    },
    {
      'icon': Icons.bed,
      'label': 'Tempat',
      'gradient': const LinearGradient(
        colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
      ),
    },
    {
      'icon': Icons.weekend,
      'label': 'Sofa',
      'gradient': const LinearGradient(
        colors: [Color(0xFFFFB300), Color(0xFFFB8C00)],
      ),
    },
  ];

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<void> fetchProducts({String? category}) async {
    try {
      String url = ApiConstants.products;
      if (category != null) {
        url += '?category=$category';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (mounted) {
          setState(() {
            products = category != null
                ? data.where((p) => p['category'] == category).toList()
                : data;
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching products: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _showAddToCartDialog(Map<String, dynamic> product) async {
    int quantity = 1; // Default quantity

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tambah ke Keranjang'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Nama Produk: ${product['name']}'),
                  const SizedBox(height: 16),
                  Text(
                    'Harga: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ').format(product['price'])}',
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Jumlah:'),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: () {
                              if (quantity > 1) {
                                setState(() {
                                  quantity--;
                                });
                              }
                            },
                          ),
                          Text('$quantity'),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              setState(() {
                                quantity++;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                await addToCart(product, quantity);
                Navigator.pop(context);
              },
              child: const Text('Konfirmasi'),
            ),
          ],
        );
      },
    );
  }

  Future<void> addToCart(Map<String, dynamic> product, int quantity) async {
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final userId = appState.userData?['user']['_id'];

      if (userId == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Silakan login terlebih dahulu')),
        );
        return;
      }

      print(
          'Adding to cart - Product: ${product['name']}, Quantity: $quantity'); // Debug log

      final response = await http.post(
        Uri.parse('http://192.168.180.94:44800/api/carts/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'productId': product['_id'],
          'quantity': quantity,
          'price': product['price'],
          'productName': product['name'],
          'product': {
            '_id': product['_id'],
            'name': product['name'],
            'price': product['price'],
            'image': product['image'],
          },
        }),
      );

      print('Add to cart response status: ${response.statusCode}'); // Debug log
      print('Add to cart response body: ${response.body}'); // Debug log

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produk berhasil ditambahkan ke keranjang'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(
            errorBody['message'] ?? 'Gagal menambahkan ke keranjang');
      }
    } catch (e) {
      print('Error adding to cart: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menambahkan ke keranjang: $e'),
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
                        child: Icon(
                          _getCategoryIcon(category),
                          size: 40,
                          color: AppTheme.darkColors['accent'],
                        ),
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
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Categories
          Container(
            height: 100,
            margin: const EdgeInsets.only(bottom: 8), // Tambahkan margin bottom
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length,
              itemBuilder: (context, index) =>
                  _buildCategoryItem(categories[index]),
            ),
          ),

          // Featured Products
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Produk Unggulan',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkColors['text'],
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'Lihat Semua',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: AppTheme.darkColors['accent'],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Product Grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return _buildProductCard(product);
              },
            ),
          ),

          // Bottom padding untuk menghindari overflow
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(Map<String, dynamic> category) {
    final isSelected = selectedCategory == category['label'];
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = isSelected ? null : category['label'];
        });
        fetchProducts(category: isSelected ? null : category['label']);
      },
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                gradient:
                    isSelected ? AppTheme.accentGradient : category['gradient'],
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(category['icon'], color: Colors.white, size: 30),
            ),
            const SizedBox(height: 8),
            Text(
              category['label'],
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? AppTheme.darkColors['accent']
                    : AppTheme.darkColors['text'],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkColors['surface'],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section with fixed height
            SizedBox(
              height: 120,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  GestureDetector(
                    onTap: () => _showProductImage(
                      context,
                      product['category'],
                      product['name'],
                      product['_id'],
                    ),
                    child: Hero(
                      tag: product['_id'],
                      child: Image.asset(
                        getCategoryImage(product['category'], product['name']),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          print('Error loading image: $error');
                          return Container(
                            color: AppTheme.darkColors['background'],
                            child: Icon(
                              _getCategoryIcon(product['category']),
                              size: 40,
                              color: AppTheme.darkColors['accent'],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Product info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product['name'] ?? 'Unnamed Product',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            color: AppTheme.darkColors['text'],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          NumberFormat.currency(
                            locale: 'id_ID',
                            symbol: 'Rp ',
                            decimalDigits: 0,
                          ).format(product['price'] ?? 0),
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: AppTheme.darkColors['accent'],
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      width: double.infinity,
                      height: 32,
                      child: ElevatedButton(
                        onPressed: () => _showAddToCartDialog(product),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.darkColors['accent'],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Beli',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
      case 'Tempat Tidur':
        return Icons.bed;
      default:
        return Icons.category;
    }
  }
}
