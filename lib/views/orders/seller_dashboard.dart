import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import 'order_detail_screen.dart';

const _kPrimary = Color(0xFF3D52D5);
const _kBg = Color(0xFFF0F2F5);
const _kPending = Color(0xFFF97316);
const _kPriced = Color(0xFF22C55E);

class SellerDashboard extends ConsumerStatefulWidget {
  const SellerDashboard({super.key});

  @override
  ConsumerState<SellerDashboard> createState() => _SellerDashboardState();
}

class _SellerDashboardState extends ConsumerState<SellerDashboard> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(orderProvider.notifier).fetchSellerOrders());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    await ref.read(authProvider.notifier).logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderState = ref.watch(orderProvider);

    ref.listen(orderProvider, (_, next) {
      if (next.error != null && next.error!.contains('Session expired')) {
        _logout();
      }
    });

    final allOrders = orderState.orders;
    final filtered = _searchQuery.isEmpty
        ? allOrders
        : allOrders
            .where((o) => o.customerName
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()))
            .toList();

    // Group by customerId
    final Map<String, List<dynamic>> grouped = {};
    for (final order in filtered) {
      grouped.putIfAbsent(order.customerId, () => []).add(order);
    }

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── AppBar ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Seller Dashboard',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A))),
                  IconButton(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout_rounded,
                        color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),

            // ── Search bar ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8)
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: const InputDecoration(
                    hintText: 'Search customers...',
                    hintStyle: TextStyle(
                        color: Color(0xFFADB5BD), fontSize: 14),
                    prefixIcon: Icon(Icons.search_rounded,
                        color: Color(0xFF94A3B8)),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ),

            // ── Orders list ──
            Expanded(
              child: orderState.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: _kPrimary))
                  : filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inbox_outlined,
                                  size: 64, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              const Text('No orders yet.',
                                  style: TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontSize: 15)),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          color: _kPrimary,
                          onRefresh: () => ref
                              .read(orderProvider.notifier)
                              .fetchSellerOrders(),
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(
                                20, 4, 20, 20),
                            children: grouped.values.map((customerOrders) {
                              final first = customerOrders.first;
                              final customerName = first.customerName as String;
                              final initials = customerName
                                  .trim()
                                  .split(' ')
                                  .take(2)
                                  .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
                                  .join();
                              final pendingCount = customerOrders
                                  .where((o) => o.status.toUpperCase() == 'PENDING')
                                  .length;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3))
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // ── Customer header ──
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 22,
                                            backgroundColor: const Color(0xFFEEEFF8),
                                            child: Text(initials,
                                                style: const TextStyle(
                                                    color: _kPrimary,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14)),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(customerName,
                                                    style: const TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 15,
                                                        color: Color(0xFF0F172A))),
                                                const SizedBox(height: 2),
                                                Text(first.customerPhone,
                                                    style: const TextStyle(
                                                        fontSize: 12,
                                                        color: Color(0xFF94A3B8))),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEEEFF8),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              '${customerOrders.length} Order${customerOrders.length > 1 ? 's' : ''}',
                                              style: const TextStyle(
                                                  color: _kPrimary,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const Divider(height: 1, indent: 14, endIndent: 14),

                                    // ── Order sub-rows ──
                                    ...customerOrders.map((order) {
                                      final isPending = order.status.toUpperCase() == 'PENDING';
                                      return InkWell(
                                        onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => OrderDetailScreen(
                                                order: order, isSeller: true),
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 4,
                                                height: 40,
                                                decoration: BoxDecoration(
                                                  color: isPending ? _kPending : _kPriced,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      '#ORD-${order.id.substring(0, 8).toUpperCase()}',
                                                      style: const TextStyle(
                                                          fontWeight: FontWeight.w600,
                                                          fontSize: 13,
                                                          color: Color(0xFF0F172A)),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      '${order.items.length} items  •  ${_timeLabel(order.createdAt)}',
                                                      style: const TextStyle(
                                                          fontSize: 12,
                                                          color: Color(0xFF94A3B8)),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              if (!isPending)
                                                Text(
                                                  '\$${order.totalAmount.toStringAsFixed(2)}',
                                                  style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 14,
                                                      color: Color(0xFF0F172A)),
                                                ),
                                              const SizedBox(width: 8),
                                              _statusBadge(order.status),
                                              const SizedBox(width: 4),
                                              const Icon(Icons.chevron_right_rounded,
                                                  size: 18,
                                                  color: Color(0xFFCBD5E1)),
                                            ],
                                          ),
                                        ),
                                      );
                                    }),

                                    if (pendingCount > 0)
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                                        child: Text(
                                          '$pendingCount pending — needs pricing',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: _kPending.withOpacity(0.8),
                                              fontStyle: FontStyle.italic),
                                        ),
                                      )
                                    else
                                      const SizedBox(height: 4),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    final isPending = status.toUpperCase() == 'PENDING';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isPending
            ? const Color(0xFFFFF4E5)
            : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPending
              ? const Color(0xFFFED7AA)
              : const Color(0xFFBBF7D0),
        ),
      ),
      child: Text(
        isPending ? 'Pending' : 'Priced',
        style: TextStyle(
            color: isPending ? _kPending : _kPriced,
            fontWeight: FontWeight.w600,
            fontSize: 12),
      ),
    );
  }

  bool _isToday(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return false;
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  bool _isYesterday(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return false;
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return d.year == yesterday.year &&
        d.month == yesterday.month &&
        d.day == yesterday.day;
  }

  String _timeLabel(String iso) {
    final d = DateTime.tryParse(iso)?.toLocal();
    if (d == null) return iso.substring(0, 10);
    if (_isToday(iso)) return _timeOnly(iso);
    if (_isYesterday(iso)) return 'Yesterday';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  String _timeOnly(String iso) {
    final d = DateTime.tryParse(iso)?.toLocal();
    if (d == null) return '';
    final h = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
    final m = d.minute.toString().padLeft(2, '0');
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }
}
