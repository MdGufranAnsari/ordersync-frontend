import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/utils/constants.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import 'order_detail_screen.dart';
import 'customer_order_history_screen.dart';
import '../../core/widgets/user_avatar.dart';
import '../../core/services/socket_service.dart';

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
  int _currentIndex = 0;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final user = ref.read(authProvider).user;
      if (user != null) {
        SocketService().init(user.id);
        SocketService().addOrderListener(_onOrderUpdated);
      }
      ref.read(orderProvider.notifier).fetchSellerOrders();
    });
  }

  void _onOrderUpdated() {
    if (mounted) {
      ref.read(orderProvider.notifier).fetchSellerOrders();
    }
  }

  @override
  void dispose() {
    SocketService().removeOrderListener(_onOrderUpdated);
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
        child: _buildCurrentTab(filtered, grouped),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        backgroundColor: Colors.white,
        indicatorColor: _kPrimary.withValues(alpha: 0.15),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded, color: _kPrimary),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_rounded),
            selectedIcon: Icon(Icons.history_rounded, color: _kPrimary),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded, color: _kPrimary),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);

    if (pickedFile != null) {
      final file = File(pickedFile.path);
      await ref.read(authProvider.notifier).uploadProfileImage(file);
      if (!mounted) return;
      
      final authState = ref.read(authProvider);
      if (authState.error != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(authState.error!),
          backgroundColor: Colors.redAccent,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Profile picture updated successfully!'),
          backgroundColor: _kPrimary,
        ));
      }
    }
  }

  Widget _buildCurrentTab(List<dynamic> filtered, Map<String, List<dynamic>> grouped) {
    if (_currentIndex == 0) return _buildHomeTab(filtered, grouped);
    if (_currentIndex == 1) return _buildHistoryTab();
    return _buildProfileTab();
  }

  Widget _buildHomeTab(List<dynamic> filtered, Map<String, List<dynamic>> grouped) {
    final orderState = ref.watch(orderProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── AppBar ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
              child: const Text('Seller Dashboard',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A))),
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
                        color: Colors.black.withValues(alpha: 0.05),
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
                                  
                              final activeOrders = customerOrders.where((o) {
                                final s = o.status.toUpperCase();
                                return s == 'PENDING' || s == 'READY' || s == 'CONFIRMED' || s == 'CONFIRMED_IMMEDIATE' || s == 'PRICED';
                              }).toList();

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
                                          UserAvatar(
                                            profileImage: first.customerProfileImage,
                                            name: customerName,
                                            radius: 22,
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
                                          GestureDetector(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => CustomerOrderHistoryScreen(
                                                    customerName: customerName,
                                                    customerPhone: first.customerPhone,
                                                    orders: customerOrders,
                                                  ),
                                                ),
                                              );
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 10, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFEEF2FF),
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    '${customerOrders.length} Order${customerOrders.length > 1 ? 's' : ''}',
                                                    style: const TextStyle(
                                                        color: _kPrimary,
                                                        fontWeight: FontWeight.w600,
                                                        fontSize: 12),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: _kPrimary),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Only show divider if there are active orders to show below
                                    if (activeOrders.isNotEmpty)
                                      const Divider(height: 1, indent: 14, endIndent: 14),

                                    // ── Active Order sub-rows ──
                                    if (activeOrders.isEmpty)
                                      const Padding(
                                        padding: EdgeInsets.all(16.0),
                                        child: Text('No active orders. Tap above to see history.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontStyle: FontStyle.italic)),
                                      )
                                    else
                                      ...activeOrders.map((order) {
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
                                                  color: _statusColor(order.status),
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
                                              color: _kPending.withValues(alpha: 0.8),
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
    );
  }

  Widget _buildHistoryTab() {
    final orderState = ref.watch(orderProvider);
    final allOrders = orderState.orders;
    final historyOrders = allOrders.where((o) {
      final s = o.status.toUpperCase();
      return s == 'COMPLETED' || s == 'EXPIRED' || s == 'EXPIRED_PENDING_CONFIRMATION';
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── AppBar ──
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 16, 16),
          child: Text('Order History',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A))),
        ),
        
        // ── Content ──
        Expanded(
          child: orderState.isLoading
              ? const Center(child: CircularProgressIndicator(color: _kPrimary))
              : historyOrders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history_rounded, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          const Text('No past orders found.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 15)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      color: _kPrimary,
                      onRefresh: () => ref.read(orderProvider.notifier).fetchSellerOrders(),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                        itemCount: historyOrders.length,
                        itemBuilder: (context, index) {
                          final order = historyOrders[index];
                          return InkWell(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order, isSeller: true))),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                              ),
                              child: Row(
                                children: [
                                  UserAvatar(
                                    profileImage: order.customerProfileImage,
                                    name: order.customerName,
                                    radius: 20,
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
                                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                            _statusBadge(order.status),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text('${order.customerName}  •  ${_timeLabel(order.createdAt)}',
                                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildProfileTab() {
    final user = ref.watch(authProvider).user;
    if (user == null) return const Center(child: CircularProgressIndicator());

    final isRestricted = ref.watch(authProvider).accountStatus == 'restricted';

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // ── Header/Avatar Card ──
        Container(
          padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_kPrimary, Color(0xFF5B73E8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
          ),
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        radius: 46,
                        backgroundColor: _kPrimary.withValues(alpha: 0.1),
                        backgroundImage: user.profileImage != null
                            ? NetworkImage('${AppConstants.imageBaseUrl}${user.profileImage}')
                            : null,
                        child: user.profileImage == null
                            ? const Icon(Icons.storefront_rounded, size: 46, color: _kPrimary)
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _kPrimary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                user.name,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  user.phone,
                  style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500)
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // ── Restriction Warning ──
        if (isRestricted)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFECACA), width: 1.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_rounded, color: Color(0xFFEF4444)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Account Restricted', style: TextStyle(color: Color(0xFF991B1B), fontWeight: FontWeight.bold, fontSize: 14)),
                        SizedBox(height: 4),
                        Text('Your catalog operations are currently restricted. Please contact support.',
                            style: TextStyle(color: Color(0xFFB91C1C), fontSize: 13)),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),

        // ── Settings Cards ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Account Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.person_outline_rounded, color: Color(0xFF475569)),
                      ),
                      title: const Text('Personal Details', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                      onTap: () {},
                    ),
                    Divider(color: Colors.grey.shade100, height: 1),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.store_mall_directory_outlined, color: Color(0xFF475569)),
                      ),
                      title: const Text('Store Configuration', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                      onTap: () {},
                    ),
                    Divider(color: Colors.grey.shade100, height: 1),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.help_outline_rounded, color: Color(0xFF475569)),
                      ),
                      title: const Text('Help & Support', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // ── Action Buttons ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Log Out', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFEF2F2),
                foregroundColor: const Color(0xFFEF4444),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _statusBadge(String status) {
    final s = status.toUpperCase();
    final Map<String, (String, Color, Color, IconData)> map = {
      'PENDING':                      ('Pending',   const Color(0xFFFFF4E5), _kPending,        Icons.access_time_rounded),
      'PRICED':                       ('Priced',    const Color(0xFFF0FDF4), _kPriced,         Icons.attach_money_rounded),
      'CONFIRMED':                    ('Confirmed', const Color(0xFFEEF0FA), _kPrimary,        Icons.check_circle_outline_rounded),
      'CONFIRMED_IMMEDIATE':          ('Immediate', const Color(0xFFEEF0FA), _kPrimary,        Icons.store_rounded),
      'READY':                        ('Ready',     const Color(0xFFFFF4E5), _kPending,        Icons.inventory_2_outlined),
      'COMPLETED':                    ('Done',      const Color(0xFFF0FDF4), _kPriced,         Icons.verified_rounded),
      'EXPIRED_PENDING_CONFIRMATION': ('Expired',   const Color(0xFFFEF2F2), Colors.redAccent, Icons.warning_amber_rounded),
      'EXPIRED':                      ('Expired',   const Color(0xFFFEF2F2), Colors.redAccent, Icons.warning_amber_rounded),
    };
    final (label, bg, fg, icon) = map[s] ?? ('Unknown', const Color(0xFFF1F5F9), const Color(0xFF94A3B8), Icons.help_outline_rounded);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 11)),
        ],
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

  Color _statusColor(String status) {
    final s = status.toUpperCase();
    final Map<String, Color> map = {
      'PENDING':                       _kPending,
      'PRICED':                        _kPriced,
      'CONFIRMED':                     _kPrimary,
      'CONFIRMED_IMMEDIATE':           _kPrimary,
      'READY':                         _kPending,
      'COMPLETED':                     _kPriced,
      'EXPIRED_PENDING_CONFIRMATION':  Colors.redAccent,
      'EXPIRED':                       Colors.redAccent,
    };
    return map[s] ?? const Color(0xFF64748B);
  }
}
