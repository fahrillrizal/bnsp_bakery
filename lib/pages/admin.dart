import 'package:bakery_app/pages/home.dart';
import 'package:flutter/material.dart';
import 'package:bakery_app/services/order_service.dart';
import 'package:bakery_app/models/order_models.dart';
import 'package:bakery_app/services/location_service.dart';
import 'package:bakery_app/pages/admin_login.dart';

class AdminPage extends StatefulWidget {
  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final OrderService _orderService = OrderService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
        backgroundColor: Colors.orange[700],
        actions: [
          // Logout Button
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _showLogoutDialog,
            tooltip: 'Logout',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(text: 'Semua', icon: Icon(Icons.list_alt)),
            Tab(text: 'Pending', icon: Icon(Icons.pending_actions)),
            Tab(text: 'Proses', icon: Icon(Icons.local_shipping)),
            Tab(text: 'Selesai', icon: Icon(Icons.check_circle)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Statistics Cards
          _buildStatisticsCards(),
          
          // Orders List
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOrdersList(_orderService.orders),
                _buildOrdersList(_orderService.pendingOrders),
                _buildOrdersList(_orderService.confirmedOrders),
                _buildOrdersList(_orderService.completedOrders),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.logout, color: Colors.orange[700]),
              SizedBox(width: 8),
              Text('Logout'),
            ],
          ),
          content: Text('Apakah Anda yakin ingin keluar dari dashboard admin?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _handleLogout();
              },
              child: Text(
                'Logout',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void _handleLogout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => HomePage()),
      (route) => false,
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Berhasil logout'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildStatisticsCards() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total Pesanan',
              '${_orderService.getTotalOrdersCount()}',
              Icons.receipt_long,
              Colors.blue,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Pending',
              '${_orderService.getTotalOrdersByStatus(OrderStatus.pending)}',
              Icons.pending_actions,
              Colors.orange,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Total Revenue',
              'Rp ${_formatPrice(_orderService.getTotalRevenue())}',
              Icons.attach_money,
              Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersList(List<Order> orders) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 80, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'Tidak ada pesanan',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return _buildOrderCard(order);
      },
    );
  }

  Widget _buildOrderCard(Order order) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(order.status),
          child: Icon(
            _getStatusIcon(order.status),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          'Pesanan #${order.id.substring(order.id.length - 6)}',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text('${order.customer.name} - ${order.customer.phone}'),
            SizedBox(height: 2),
            Text(
              '${_formatDateTime(order.orderDate)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            SizedBox(height: 4),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getStatusColor(order.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                order.statusText,
                style: TextStyle(
                  fontSize: 11,
                  color: _getStatusColor(order.status),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        trailing: Text(
          'Rp ${_formatPrice(order.totalAmount)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.orange[700],
          ),
        ),
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Customer Details
                _buildDetailSection(
                  'Detail Pelanggan',
                  Icons.person,
                  [
                    'Nama: ${order.customer.name}',
                    'Telepon: ${order.customer.phone}',
                    'Alamat: ${order.customer.address}',
                    'Koordinat: ${LocationService.formatCoordinates(order.customer.latitude, order.customer.longitude)}',
                  ],
                ),
                
                SizedBox(height: 16),
                
                // Order Items
                _buildDetailSection(
                  'Item Pesanan',
                  Icons.shopping_cart,
                  order.items.map((item) => 
                    '${item.product.name} x${item.quantity} - Rp ${_formatPrice(item.totalPrice)}'
                    + (item.notes?.isNotEmpty == true ? '\n  Catatan: ${item.notes}' : '')
                  ).toList(),
                ),
                
                if (order.notes?.isNotEmpty == true) ...[
                  SizedBox(height: 16),
                  _buildDetailSection(
                    'Catatan Pesanan',
                    Icons.note,
                    [order.notes!],
                  ),
                ],
                
                SizedBox(height: 20),
                
                // Action Buttons
                if (order.status != OrderStatus.delivered && order.status != OrderStatus.cancelled)
                  _buildActionButtons(order),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, IconData icon, List<String> details) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.orange[700]),
            SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: details.map((detail) => Padding(
              padding: EdgeInsets.symmetric(vertical: 2),
              child: Text(
                detail,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                ),
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(Order order) {
    return Row(
      children: [
        if (order.status == OrderStatus.pending) ...[
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _updateOrderStatus(order, OrderStatus.confirmed),
              icon: Icon(Icons.check, size: 16),
              label: Text('Konfirmasi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _updateOrderStatus(order, OrderStatus.cancelled),
              icon: Icon(Icons.cancel, size: 16),
              label: Text('Tolak'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ] else if (order.status == OrderStatus.confirmed) ...[
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _updateOrderStatus(order, OrderStatus.preparing),
              icon: Icon(Icons.kitchen, size: 16),
              label: Text('Mulai Proses'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ] else if (order.status == OrderStatus.preparing) ...[
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _updateOrderStatus(order, OrderStatus.ready),
              icon: Icon(Icons.done_all, size: 16),
              label: Text('Siap Antar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ] else if (order.status == OrderStatus.ready) ...[
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _updateOrderStatus(order, OrderStatus.delivered),
              icon: Icon(Icons.local_shipping, size: 16),
              label: Text('Antar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _updateOrderStatus(Order order, OrderStatus newStatus) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Update Status Pesanan'),
          content: Text(
            'Apakah Anda yakin ingin mengubah status pesanan #${order.id.substring(order.id.length - 6)} '
            'dari "${order.statusText}" menjadi "${_getStatusText(newStatus)}"?'
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _orderService.updateOrderStatus(order.id, newStatus);
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Status pesanan berhasil diupdate'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Text('Update'),
            ),
          ],
        );
      },
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange[600]!;
      case OrderStatus.confirmed:
        return Colors.blue[600]!;
      case OrderStatus.preparing:
        return Colors.purple[600]!;
      case OrderStatus.ready:
        return Colors.indigo[600]!;
      case OrderStatus.delivered:
        return Colors.green[600]!;
      case OrderStatus.cancelled:
        return Colors.red[600]!;
    }
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Icons.pending_actions;
      case OrderStatus.confirmed:
        return Icons.check_circle;
      case OrderStatus.preparing:
        return Icons.kitchen;
      case OrderStatus.ready:
        return Icons.done_all;
      case OrderStatus.delivered:
        return Icons.local_shipping;
      case OrderStatus.cancelled:
        return Icons.cancel;
    }
  }

  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Menunggu Konfirmasi';
      case OrderStatus.confirmed:
        return 'Dikonfirmasi';
      case OrderStatus.preparing:
        return 'Sedang Diproses';
      case OrderStatus.ready:
        return 'Siap Antar';
      case OrderStatus.delivered:
        return 'Terkirim';
      case OrderStatus.cancelled:
        return 'Dibatalkan';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = months[dateTime.month - 1];
    final year = dateTime.year;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    
    return '$day $month $year, $hour:$minute';
  }

  String _formatPrice(double price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)}M';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}k';
    }
    return price.toStringAsFixed(0);
  }
}