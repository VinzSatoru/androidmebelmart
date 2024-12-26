import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mebelmart_furniture/constants/api_constants.dart';

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  List<dynamic> customers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCustomers();
  }

  Future<void> fetchCustomers() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.users),
        headers: {'Content-Type': 'application/json'},
      );

      print('Customers response: ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        final List<dynamic> allUsers = json.decode(response.body);
        setState(() {
          customers = allUsers
              .where(
                  (user) => user['role'] != null && user['role'] == 'customer')
              .toList();
          isLoading = false;
        });
      } else {
        print('Error fetching customers: ${response.statusCode}');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching customers: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pelanggan'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : customers.isEmpty
              ? const Center(child: Text('Tidak ada pelanggan'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: customers.length,
                  itemBuilder: (context, index) {
                    final customer = customers[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          child: Text(
                            customer['fullName'][0].toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(customer['fullName']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(customer['email']),
                            Text(customer['phoneNumber']),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.info_outline),
                          onPressed: () {
                            _showCustomerDetails(context, customer);
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  void _showCustomerDetails(
      BuildContext context, Map<String, dynamic> customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(customer['fullName']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: const Icon(Icons.email),
              title: Text(customer['email']),
            ),
            ListTile(
              leading: const Icon(Icons.phone),
              title: Text(customer['phoneNumber']),
            ),
            ListTile(
              leading: const Icon(Icons.location_on),
              title: Text(customer['address']),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text('Bergabung: ${_formatDate(customer['createdAt'])}'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    final date = DateTime.parse(dateStr);
    return '${date.day}/${date.month}/${date.year}';
  }
}
