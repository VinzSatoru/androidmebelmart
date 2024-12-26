import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mebelmart_furniture/pages/auth/login_page.dart';
import 'package:mebelmart_furniture/providers/app_state.dart';
import 'package:mebelmart_furniture/theme/app_theme.dart';
import 'package:mebelmart_furniture/pages/customer/orders_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkColors['surface'],
        title: Text(
          'Konfirmasi Logout',
          style: TextStyle(
            fontFamily: 'Poppins',
            color: AppTheme.darkColors['text'],
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Apakah Anda yakin ingin keluar?',
          style: TextStyle(
            fontFamily: 'Poppins',
            color: AppTheme.darkColors['textSecondary'],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: AppTheme.darkColors['accent'],
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.darkColors['error'],
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              context.read<AppState>().logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
            child: const Text(
              'Logout',
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

  @override
  Widget build(BuildContext context) {
    final userData = context.watch<AppState>().userData?['user'];

    if (userData == null) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            AppTheme.darkColors['accent']!,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          // Profile Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.darkColors['primary']!,
                  AppTheme.darkColors['secondary']!,
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.darkColors['accent']!,
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: AppTheme.darkColors['surface'],
                    child: Text(
                      userData['fullName'][0].toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkColors['accent'],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  userData['fullName'],
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  userData['email'],
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Menu Items
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _buildMenuSection(
                  title: 'Akun Saya',
                  items: [
                    _buildMenuItem(
                      icon: Icons.shopping_bag,
                      title: 'Pesanan Saya',
                      subtitle: 'Lihat riwayat pesanan Anda',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const OrdersPage(),
                          ),
                        );
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.location_on,
                      title: 'Alamat',
                      subtitle: 'Atur alamat pengiriman',
                      onTap: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildMenuSection(
                  title: 'Pengaturan',
                  items: [
                    _buildMenuItem(
                      icon: Icons.person,
                      title: 'Edit Profil',
                      subtitle: 'Ubah informasi profil',
                      onTap: () {},
                    ),
                    _buildMenuItem(
                      icon: Icons.notifications,
                      title: 'Notifikasi',
                      subtitle: 'Atur notifikasi aplikasi',
                      onTap: () {},
                    ),
                    _buildMenuItem(
                      icon: Icons.security,
                      title: 'Keamanan',
                      subtitle: 'Ubah password',
                      onTap: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildMenuSection(
                  title: 'Lainnya',
                  items: [
                    _buildMenuItem(
                      icon: Icons.help,
                      title: 'Bantuan',
                      subtitle: 'Pusat bantuan',
                      onTap: () {},
                    ),
                    _buildMenuItem(
                      icon: Icons.info,
                      title: 'Tentang',
                      subtitle: 'Informasi aplikasi',
                      onTap: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout),
              label: const Text(
                'Keluar',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.darkColors['error'],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMenuSection({
    required String title,
    required List<Widget> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkColors['text'],
            ),
          ),
        ),
        Card(
          elevation: 2,
          color: AppTheme.darkColors['surface'],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.darkColors['accent']!.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: AppTheme.darkColors['accent'],
              ),
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
                      fontSize: 16,
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
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppTheme.darkColors['textSecondary'],
            ),
          ],
        ),
      ),
    );
  }
}
