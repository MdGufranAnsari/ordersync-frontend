import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/constants.dart';
import '../../core/services/api_service.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import 'order_detail_screen.dart';

const _kPrimary = Color(0xFF3D52D5);
const _kBg = Color(0xFFF0F2F5);
const _kPending = Color(0xFFF97316);
const _kPriced = Color(0xFF22C55E);
const _kTeal = Color(0xFF14B8A6);

// â”€â”€ Seller model â”€â”€
class SellerInfo {
  final String id;
  final String name;
  final String phone;
  SellerInfo({required this.id, required this.name, required this.phone});
}

final sellersProvider = FutureProvider<List<SellerInfo>>((ref) async {
  final response = await ApiClient.get(AppConstants.sellers);
  final list = response['sellers'] as List;
  return list
      .map((e) => SellerInfo(
            id: e['id'] as String,
            name: e['name'] as String,
            phone: e['phone'] as String,
          ))
      .toList();
});

class CustomerDashboard extends ConsumerStatefulWidget {
  const CustomerDashboard({super.key});

  @override
  ConsumerState<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends ConsumerState<CustomerDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<Map<String, dynamic>> _shoppingItems = [];
  final List<TextEditingController> _nameControllers = [];
  SellerInfo? _selectedSeller;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(
        () => ref.read(orderProvider.notifier).fetchCustomerOrders());
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final c in _nameControllers) c.dispose();
    super.dispose();
  }

  void _addItem() {
    setState(() {
      _shoppingItems.add({'serialNumber': _shoppingItems.length + 1, 'itemName': '', 'price': null});
      _nameControllers.add(TextEditingController());
    });
  }

  void _removeItem(int index) {
    _nameControllers[index].dispose();
    setState(() {
      _shoppingItems.removeAt(index);
      _nameControllers.removeAt(index);
      for (int i = 0; i < _shoppingItems.length; i++) {
        _shoppingItems[i]['serialNumber'] = i + 1;
      }
    });
  }

  Future<void> _sendToSeller() async {
    for (int i = 0; i < _shoppingItems.length; i++) {
      _shoppingItems[i]['itemName'] = _nameControllers[i].text.trim();
    }
    final validItems = _shoppingItems
        .where((item) => (item['itemName'] as String).isNotEmpty)
        .toList();

    if (validItems.isEmpty) {
      _showDialog('Empty List', 'Please add at least one item before sending.');
      return;
    }

    // Pick seller
    final sellersAsync = ref.read(sellersProvider);
    if (sellersAsync.isLoading) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Loading sellers, please wait...'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    final sellers = sellersAsync.value ?? [];
    if (sellers.isEmpty) {
      _showDialog('No Sellers', 'No sellers are registered yet.');
      return;
    }

    if (_selectedSeller == null) {
      _showSellerPicker(sellers, validItems);
      return;
    }

    await _submitOrder(validItems);
  }

  Future<void> _submitOrder(List<Map<String, dynamic>> validItems) async {
    final sellerId = _selectedSeller!.id;
    final items = validItems
        .map((item) => {'name': item['itemName'] as String, 'quantity': 1})
        .toList();

    final success = await ref
        .read(orderProvider.notifier)
        .createOrder(sellerId: sellerId, items: items);

    if (!mounted) return;
    if (success) {
      setState(() {
        _shoppingItems.clear();
        for (final c in _nameControllers) c.dispose();
        _nameControllers.clear();
        _selectedSeller = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Order sent successfully!'),
        backgroundColor: _kPriced,
        behavior: SnackBarBehavior.floating,
      ));
      _tabController.animateTo(1);
    } else {
      final error = ref.read(orderProvider).error ?? 'Failed to send order.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  void _showSellerPicker(
      List<SellerInfo> sellers, List<Map<String, dynamic>> validItems) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const Text('Select a Seller',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...sellers.map((s) {
              final initial = s.name.isNotEmpty ? s.name[0].toUpperCase() : '?';
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _kPrimary,
                  child: Text(initial,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                title: Text(s.name,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(s.phone,
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                onTap: () {
                  setState(() => _selectedSeller = s);
                  Navigator.pop(context);
                  _submitOrder(validItems);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK')),
        ],
      ),
    );
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
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            // â”€â”€ AppBar â”€â”€
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('My Dashboard',
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

            // â”€â”€ Tabs â”€â”€
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8)
                  ],
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: _kPrimary,
                    borderRadius: BorderRadius.circular(26),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: const Color(0xFF94A3B8),
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                  tabs: const [
                    Tab(text: 'New List'),
                    Tab(text: 'My Orders'),
                  ],
                ),
              ),
            ),

            // â”€â”€ Body â”€â”€
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildNewListTab(),
                  _buildOrdersTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // â”€â”€â”€ New List Tab â”€â”€â”€
  Widget _buildNewListTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),


          // Items card â€” flush table matching Order Detail style
          Container(
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
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Heading row â€” padded
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Items',
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A))),
                      if (_shoppingItems.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF0FA),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_shoppingItems.length} Items',
                            style: const TextStyle(
                                color: _kPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),

                if (_shoppingItems.isNotEmpty)
                  Table(
                    columnWidths: {
                      0: FixedColumnWidth(
                          MediaQuery.of(context).size.width * 0.10),
                      1: const FlexColumnWidth(2),
                      2: FixedColumnWidth(
                          MediaQuery.of(context).size.width * 0.14),
                      3: FixedColumnWidth(
                          MediaQuery.of(context).size.width * 0.12),
                    },
                    border: TableBorder.all(color: const Color(0xFFE2E8F0)),
                    children: [
                      // Header row
                      TableRow(
                        decoration: const BoxDecoration(
                            color: Color(0xFFEEF0FA)),
                        children: [
                          _hCell('SR'),
                          _hCell('Item Name'),
                          _hCell('Price'),
                          _hCell(''),
                        ],
                      ),
                      // Item rows
                      for (int i = 0; i < _shoppingItems.length; i++)
                        TableRow(
                          decoration: BoxDecoration(
                            color: i.isEven
                                ? Colors.white
                                : const Color(0xFFF8FAFC),
                          ),
                          children: [
                            TableCell(
                              verticalAlignment:
                                  TableCellVerticalAlignment.middle,
                              child: Center(
                                child: Text('${i + 1}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF64748B))),
                              ),
                            ),
                            TableCell(
                              verticalAlignment:
                                  TableCellVerticalAlignment.top,
                              child: TextField(
                                controller: _nameControllers[i],
                                maxLines: null,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 10),
                                  hintText: 'Enter item name',
                                  hintStyle: TextStyle(
                                      color: Color(0xFFCBD5E1),
                                      fontSize: 13),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                ),
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            const TableCell(
                              verticalAlignment:
                                  TableCellVerticalAlignment.middle,
                              child: Center(
                                child: Text('--',
                                    style: TextStyle(
                                        color: Color(0xFFCBD5E1),
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ),
                            TableCell(
                              verticalAlignment:
                                  TableCellVerticalAlignment.middle,
                              child: Center(
                                child: IconButton(
                                  icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      size: 18,
                                      color: Colors.redAccent),
                                  onPressed: () => _removeItem(i),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  )
                else
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    child: Center(
                      child: Text(
                        'No items yet. Tap "+ Add Item" to start.',
                        style: TextStyle(
                            color: Colors.grey.shade400, fontSize: 13),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // + Add Item
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: _addItem,
              icon: const Icon(Icons.add_rounded, color: _kPrimary),
              label: const Text('Add Item',
                  style: TextStyle(
                      color: _kPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: _kPrimary, width: 1.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Send List to Seller
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: ref.watch(orderProvider).isLoading
                  ? null
                  : _sendToSeller,
              icon: ref.watch(orderProvider).isLoading
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_rounded),
              label: const Text('Send List to Seller',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'Pricing will be updated by the seller after submission.',
              style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // â”€â”€ Table header cell helper â”€â”€
  TableCell _hCell(String text) => TableCell(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: _kPrimary,
            ),
          ),
        ),
      );


  // ─── My Orders Tab ───
  Widget _buildOrdersTab() {
    final orderState = ref.watch(orderProvider);

    if (orderState.isLoading) {
      return const Center(child: CircularProgressIndicator(color: _kPrimary));
    }

    if (orderState.orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text('No orders sent yet.',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 15)),
            const SizedBox(height: 8),
            const Text('Create a new list to get started.',
                style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 13)),
          ],
        ),
      );
    }

    // Group orders by sellerId
    final Map<String, List<dynamic>> grouped = {};
    for (final order in orderState.orders) {
      grouped.putIfAbsent(order.sellerId, () => []).add(order);
    }

    return RefreshIndicator(
      color: _kPrimary,
      onRefresh: () => ref.read(orderProvider.notifier).fetchCustomerOrders(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        children: grouped.values.map((sellerOrders) {
          final first = sellerOrders.first;
          final sellerName = first.sellerName as String;
          final initial = sellerName.isNotEmpty ? sellerName[0].toUpperCase() : '?';
          final pendingCount = sellerOrders
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
                    blurRadius: 12,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Seller header ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: _kTeal.withOpacity(0.15),
                        child: Text(initial,
                            style: const TextStyle(
                                color: _kTeal,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(sellerName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Color(0xFF0F172A))),
                            const SizedBox(height: 2),
                            Text(first.sellerPhone,
                                style: const TextStyle(
                                    fontSize: 12, color: Color(0xFF94A3B8))),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF0FA),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${sellerOrders.length} Order${sellerOrders.length > 1 ? "s" : ""}',
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
                ...sellerOrders.map((order) {
                  final isPending = order.status.toUpperCase() == 'PENDING';
                  return InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            OrderDetailScreen(order: order, isSeller: false),
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
                                  '${order.items.length} items  •  ${order.createdAt.substring(0, 10)}',
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
                              size: 18, color: Color(0xFFCBD5E1)),
                        ],
                      ),
                    ),
                  );
                }),

                if (pendingCount > 0)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                    child: Text(
                      '$pendingCount pending — awaiting seller pricing',
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
    );
  }

  Widget _card({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child: child,
      );

  Widget _statusBadge(String status) {
    final isPending = status.toUpperCase() == 'PENDING';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isPending
            ? const Color(0xFFFFF4E5)
            : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPending ? Icons.access_time_rounded : Icons.attach_money_rounded,
            size: 12,
            color: isPending ? _kPending : _kPriced,
          ),
          const SizedBox(width: 4),
          Text(
            status.toUpperCase(),
            style: TextStyle(
                color: isPending ? _kPending : _kPriced,
                fontWeight: FontWeight.bold,
                fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _reviewButton() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: _kPrimary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text('Review',
            style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      );
}
