import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/utils/constants.dart';
import '../../core/services/api_service.dart';
import '../../providers/order_provider.dart';
import '../auth/login_screen.dart';
import 'order_detail_screen.dart';
import 'customer_order_history_screen.dart';
import '../../core/widgets/user_avatar.dart';

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
  final String? profileImage;
  SellerInfo({required this.id, required this.name, required this.phone, this.profileImage});
}

final sellersProvider = FutureProvider<List<SellerInfo>>((ref) async {
  final response = await ApiClient.get(AppConstants.sellers);
  final list = response['sellers'] as List;
  return list
      .map((e) => SellerInfo(
            id: e['id'] as String,
            name: e['name'] as String,
            phone: e['phone'] as String,
            profileImage: e['profile_image'] as String?,
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
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(
        () => ref.read(orderProvider.notifier).fetchCustomerOrders());
  }

  final TextEditingController _sellerSearchController = TextEditingController();

  @override
  void dispose() {
    _tabController.dispose();
    _sellerSearchController.dispose();
    for (final c in _nameControllers) {
      c.dispose();
    }
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

    if (_selectedSeller == null) {
      _showDialog('Select Seller', 'Please search and select a seller first.');
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
        for (final c in _nameControllers) {
          c.dispose();
        }
        _selectedSeller = null;
        _sellerSearchController.clear();
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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);

    if (pickedFile != null) {
      final file = File(pickedFile.path);
      await ref.read(authProvider.notifier).uploadProfileImage(file);
      if (!mounted) return;
      
      final authState = ref.read(authProvider);
      if (authState.error != null) {
        _showDialog('Upload Failed', authState.error!);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Profile picture updated successfully!'),
          backgroundColor: _kPrimary,
        ));
      }
    }
  }

  Widget _buildCurrentTab() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return _buildHistoryTab();
      case 2:
        return _buildProfileTab();
      default:
        return _buildHomeTab();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildCurrentTab(),
        ),
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _kPrimary);
            }
            return const TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Color(0xFF64748B));
          }),
        ),
        child: NavigationBar(
          height: 70,
          elevation: 10,
          shadowColor: Colors.black.withValues(alpha: 0.1),
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
      ),
    );
  }

  Widget _buildHomeTab() {
    return Column(
      children: [
        // ── AppBar ──
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
            ],
          ),
        ),

        // ── Tabs ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
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

        // ── Body ──
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
    );
  }

  // â”€â”€â”€ New List Tab â”€â”€â”€
  Widget _buildNewListTab() {
    final accountStatus = ref.watch(authProvider).accountStatus;
    final isRestricted = accountStatus == 'restricted';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),

          if (isRestricted) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your account is restricted due to too many no-shows. You cannot create new orders.',
                      style: TextStyle(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],


          // Items card â€” flush table matching Order Detail style
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
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
              onPressed: isRestricted ? null : _addItem,
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

          const SizedBox(height: 24),

          // ── Seller Search ──
          const Text('Select Seller',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 8),
          
          Consumer(
            builder: (context, ref, child) {
              final sellersAsync = ref.watch(sellersProvider);
              
              return sellersAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(12),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, stack) => Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('Error loading sellers: $err', style: const TextStyle(color: Colors.red)),
                ),
                data: (sellers) {
                  return Autocomplete<SellerInfo>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return const Iterable<SellerInfo>.empty();
                      }
                      final query = textEditingValue.text.toLowerCase();
                      return sellers.where((SellerInfo seller) {
                        return seller.name.toLowerCase().contains(query) ||
                               seller.phone.contains(query);
                      });
                    },
                    displayStringForOption: (SellerInfo option) => '${option.name} (${option.phone})',
                    onSelected: (SellerInfo selection) {
                      setState(() {
                        _selectedSeller = selection;
                      });
                      FocusScope.of(context).unfocus();
                    },
                    fieldViewBuilder: (BuildContext context, TextEditingController fieldTextEditingController,
                        FocusNode fieldFocusNode, VoidCallback onFieldSubmitted) {
                      
                      // Keep our controller in sync so we can manually clear it later
                      if (fieldTextEditingController.text != _sellerSearchController.text) {
                        fieldTextEditingController.text = _sellerSearchController.text;
                      }
                      
                      return TextField(
                        controller: fieldTextEditingController,
                        focusNode: fieldFocusNode,
                        enabled: !isRestricted,
                        onChanged: (val) {
                          _sellerSearchController.text = val;
                          if (val.isEmpty && _selectedSeller != null) {
                            setState(() => _selectedSeller = null);
                          }
                        },
                        decoration: InputDecoration(
                          hintText: 'Search by name or phone...',
                          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8)),
                          suffixIcon: _selectedSeller != null 
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 20, color: Colors.grey),
                                onPressed: () {
                                  fieldTextEditingController.clear();
                                  _sellerSearchController.clear();
                                  setState(() => _selectedSeller = null);
                                },
                              )
                            : null,
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: _selectedSeller != null ? _kPrimary : Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: _kPrimary, width: 2),
                          ),
                        ),
                      );
                    },
                    optionsViewBuilder: (context, onSelected, options) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 4.0,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            constraints: const BoxConstraints(maxHeight: 200),
                            width: MediaQuery.of(context).size.width - 40,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              itemCount: options.length,
                              separatorBuilder: (context, index) => const Divider(height: 1),
                              itemBuilder: (BuildContext context, int index) {
                                final SellerInfo option = options.elementAt(index);
                                final initial = option.name.isNotEmpty ? option.name[0].toUpperCase() : '?';
                                return ListTile(
                                  leading: UserAvatar(
                                    profileImage: option.profileImage,
                                    name: option.name,
                                    radius: 16,
                                  ),
                                  title: Text(option.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                  subtitle: Text(option.phone, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  onTap: () {
                                    onSelected(option);
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
          
          if (_selectedSeller != null)
             Padding(
               padding: const EdgeInsets.only(top: 8.0, left: 4.0),
               child: Row(
                 children: [
                   const Icon(Icons.check_circle_rounded, color: _kPrimary, size: 16),
                   const SizedBox(width: 6),
                   Text('Selected: ${_selectedSeller!.name}', style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                 ],
               ),
             ),

          const SizedBox(height: 24),

          // Send List to Seller
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: isRestricted || ref.watch(orderProvider).isLoading
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

    // Keep active statuses at the top
    int sortValue(String status) {
      final s = status.toUpperCase();
      if (s == 'PENDING') return 0;
      if (s == 'PRICED') return 1;
      if (s == 'CONFIRMED' || s == 'CONFIRMED_IMMEDIATE') return 2;
      if (s == 'READY') return 3;
      if (s == 'EXPIRED_PENDING_CONFIRMATION') return 4;
      return 5;
    }

    // Group orders by sellerId
    final Map<String, List<dynamic>> grouped = {};
    for (final order in orderState.orders) {
      grouped.putIfAbsent(order.sellerId, () => []).add(order);
    }

    // Sort within group
    for (final list in grouped.values) {
      list.sort((a, b) {
        final valA = sortValue(a.status);
        final valB = sortValue(b.status);
        if (valA != valB) return valA.compareTo(valB);
        return b.createdAt.compareTo(a.createdAt);
      });
    }

    // Sort groups
    final sortedGroups = grouped.entries.toList()
      ..sort((a, b) {
        final bestA = a.value.map((o) => sortValue(o.status)).reduce((min, val) => val < min ? val : min);
        final bestB = b.value.map((o) => sortValue(o.status)).reduce((min, val) => val < min ? val : min);
        if (bestA != bestB) return bestA.compareTo(bestB);
        final dateA = a.value.map((o) => o.createdAt as String).reduce((max, val) => val.compareTo(max) > 0 ? val : max);
        final dateB = b.value.map((o) => o.createdAt as String).reduce((max, val) => val.compareTo(max) > 0 ? val : max);
        return dateB.compareTo(dateA);
      });

    return RefreshIndicator(
      color: _kPrimary,
      onRefresh: () => ref.read(orderProvider.notifier).fetchCustomerOrders(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        children: sortedGroups.map((entry) {
          final sellerOrders = entry.value;
          final first = sellerOrders.first;
          final sellerName = first.sellerName as String;
          final initial = sellerName.isNotEmpty ? sellerName[0].toUpperCase() : '?';
          final pendingCount = sellerOrders
              .where((o) => o.status.toUpperCase() == 'PENDING')
              .length;

          final activeOrders = sellerOrders.where((o) {
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
                    color: Colors.black.withValues(alpha: 0.05),
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
                      UserAvatar(
                        profileImage: first.sellerProfileImage,
                        name: sellerName,
                        radius: 22,
                        backgroundColor: _kTeal,
                        textColor: Colors.white,
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
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CustomerOrderHistoryScreen(
                                customerName: sellerName,
                                customerPhone: first.sellerPhone,
                                orders: sellerOrders,
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
                                '${sellerOrders.length} Order${sellerOrders.length > 1 ? "s" : ""}',
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

                if (activeOrders.isNotEmpty)
                  const Divider(height: 1, indent: 14, endIndent: 14),

                // ── Order sub-rows ──
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
                      onRefresh: () => ref.read(orderProvider.notifier).fetchCustomerOrders(),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                        itemCount: historyOrders.length,
                        itemBuilder: (context, index) {
                          final order = historyOrders[index];
                          return InkWell(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order, isSeller: false))),
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
                                    profileImage: order.sellerProfileImage,
                                    name: order.sellerName,
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
                                        Text('${order.sellerName}  •  ${order.createdAt.substring(0, 10)}',
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
                            ? const Icon(Icons.person_rounded, size: 46, color: _kPrimary)
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
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Account Restricted', style: TextStyle(color: Color(0xFF991B1B), fontWeight: FontWeight.bold, fontSize: 14)),
                        SizedBox(height: 4),
                        Text('Your account is restricted due to multiple no-shows. You cannot create new orders.',
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
                        child: const Icon(Icons.location_on_outlined, color: Color(0xFF475569)),
                      ),
                      title: const Text('Saved Addresses', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
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
}
