import 'package:flutter/material.dart';
import '../../models/order_model.dart';
import 'order_detail_screen.dart';
import 'package:intl/intl.dart';

class CustomerOrderHistoryScreen extends StatelessWidget {
  final String customerName;
  final String customerPhone;
  final List<dynamic> orders;

  const CustomerOrderHistoryScreen({
    super.key,
    required this.customerName,
    required this.customerPhone,
    required this.orders,
  });

  @override
  Widget build(BuildContext context) {
    const kPrimary = Color(0xFF6366F1);
    const kPending = Color(0xFFF59E0B);
    const kPriced = Color(0xFF10B981);
    const kBg = Color(0xFFF8FAFC);

    final sortedOrders = List<dynamic>.from(orders)..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(customerName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            Text(customerPhone, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: sortedOrders.length,
        itemBuilder: (context, index) {
          final order = sortedOrders[index];
          final isPending = order.status.toUpperCase() == 'PENDING';
          
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
              ],
            ),
            child: InkWell(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order, isSeller: true))),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _statusColor(order.status),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('#ORD-${order.id.substring(0, 8).toUpperCase()}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              _statusBadge(order.status),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${order.items.length} items  •  ${_formatDate(order.createdAt)}',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                              if (!isPending)
                                Text('\$${order.totalAmount.toStringAsFixed(2)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: kPrimary)),
                            ],
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    return DateFormat('MMM d, yyyy • h:mm a').format(d);
  }

  Color _statusColor(String status) {
    final s = status.toUpperCase();
    if (s == 'PENDING') return const Color(0xFFF59E0B);
    if (s == 'READY') return const Color(0xFFF59E0B);
    if (s == 'CONFIRMED' || s == 'CONFIRMED_IMMEDIATE') return const Color(0xFF6366F1);
    if (s == 'PRICED') return const Color(0xFF10B981);
    if (s == 'COMPLETED') return const Color(0xFF10B981);
    return Colors.redAccent;
  }

  Widget _statusBadge(String status) {
    final s = status.toUpperCase();
    final Map<String, (String, Color, Color)> map = {
      'PENDING':                       ('Pending',            const Color(0xFFFFF4E5), const Color(0xFFF59E0B)),
      'PRICED':                        ('Priced',             const Color(0xFFF0FDF4), const Color(0xFF10B981)),
      'CONFIRMED':                     ('Confirmed',          const Color(0xFFEEF0FA), const Color(0xFF6366F1)),
      'CONFIRMED_IMMEDIATE':           ('Immediate',          const Color(0xFFEEF0FA), const Color(0xFF6366F1)),
      'READY':                         ('Ready',              const Color(0xFFFFF4E5), const Color(0xFFF59E0B)),
      'COMPLETED':                     ('Completed',          const Color(0xFFF0FDF4), const Color(0xFF10B981)),
      'EXPIRED_PENDING_CONFIRMATION':  ('Expired',            const Color(0xFFFEF2F2), Colors.redAccent),
      'EXPIRED':                       ('Expired',            const Color(0xFFFEF2F2), Colors.redAccent),
    };
    final (label, bg, fg) = map[s] ?? ('Unknown', const Color(0xFFF1F5F9), const Color(0xFF64748B));
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: fg.withOpacity(0.3))),
      child: Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 10)),
    );
  }
}
