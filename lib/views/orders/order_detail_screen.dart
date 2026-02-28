import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/order_model.dart';
import '../../providers/order_provider.dart';

const _kPrimary = Color(0xFF3D52D5);
const _kBg = Color(0xFFF0F2F5);
const _kPending = Color(0xFFF97316);
const _kPriced = Color(0xFF22C55E);

class OrderDetailScreen extends ConsumerStatefulWidget {
  final OrderModel order;
  final bool isSeller;

  const OrderDetailScreen({
    super.key,
    required this.order,
    required this.isSeller,
  });

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  late List<TextEditingController> _nameControllers;
  late List<TextEditingController> _priceControllers;
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    _nameControllers =
        widget.order.items.map((i) => TextEditingController(text: i.name)).toList();
    _priceControllers = widget.order.items
        .map((i) => TextEditingController(
            text: i.price != null ? i.price!.toStringAsFixed(2) : ''))
        .toList();
  }

  @override
  void dispose() {
    for (final c in _nameControllers) c.dispose();
    for (final c in _priceControllers) c.dispose();
    super.dispose();
  }

  void _addRow() {
    setState(() {
      _nameControllers.add(TextEditingController());
      _priceControllers.add(TextEditingController());
      _isDirty = true;
    });
  }

  void _removeRow(int index) {
    if (_nameControllers.length <= 1) return;
    setState(() {
      _nameControllers[index].dispose();
      _priceControllers[index].dispose();
      _nameControllers.removeAt(index);
      _priceControllers.removeAt(index);
      _isDirty = true;
    });
  }

  Future<void> _saveItems() async {
    final items = <Map<String, dynamic>>[];
    for (int i = 0; i < _nameControllers.length; i++) {
      final name = _nameControllers[i].text.trim();
      if (name.isNotEmpty) items.add({'name': name, 'quantity': 1});
    }
    if (items.isEmpty) {
      _snack('Add at least one item.', Colors.orange);
      return;
    }
    final success = await ref
        .read(orderProvider.notifier)
        .updateOrderItems(orderId: widget.order.id, items: items);
    if (!mounted) return;
    if (success) {
      setState(() => _isDirty = false);
      _snack('List updated!', _kPriced);
    } else {
      _snack(ref.read(orderProvider).error ?? 'Failed', Colors.redAccent);
    }
  }

  Future<void> _savePrices() async {
    final items = <Map<String, dynamic>>[];
    for (int i = 0; i < widget.order.items.length; i++) {
      final price = double.tryParse(_priceControllers[i].text) ?? 0;
      items.add({'name': widget.order.items[i].name, 'price': price});
    }
    final success = await ref
        .read(orderProvider.notifier)
        .updateOrderPrices(orderId: widget.order.id, items: items);
    if (!mounted) return;
    if (success) {
      setState(() => _isDirty = false);
      _snack('Prices saved!', _kPriced);
      Navigator.pop(context);
    } else {
      _snack(ref.read(orderProvider).error ?? 'Failed', Colors.redAccent);
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _showProfile() {
    final name =
        widget.isSeller ? widget.order.customerName : widget.order.sellerName;
    final phone =
        widget.isSeller ? widget.order.customerPhone : widget.order.sellerPhone;
    final role = widget.isSeller ? 'Customer' : 'Seller';
    final id = widget.isSeller ? widget.order.customerId : widget.order.sellerId;
    final initials = name.trim().split(' ').take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      backgroundColor: Colors.white,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2)),
            ),
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: const Color(0xFFEEF0FA),
                  child: Text(initials,
                      style: const TextStyle(
                          fontSize: 28, color: _kPrimary,
                          fontWeight: FontWeight.bold)),
                ),
                Positioned(
                  right: 2, bottom: 2,
                  child: Container(
                    width: 16, height: 16,
                    decoration: const BoxDecoration(
                        color: _kPriced, shape: BoxShape.circle),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(name,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A))),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.badge_rounded, size: 14, color: _kPriced),
                  const SizedBox(width: 4),
                  Text(role,
                      style: const TextStyle(
                          color: _kPriced,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _infoRow(
                    icon: Icons.phone_rounded,
                    iconColor: _kPrimary,
                    label: 'MOBILE',
                    value: phone,
                    trailing: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                          color: const Color(0xFFEEF0FA),
                          borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.chat_bubble_outline_rounded,
                          size: 16, color: _kPrimary),
                    ),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _infoRow(
                    icon: Icons.fingerprint_rounded,
                    iconColor: const Color(0xFF8B5CF6),
                    label: 'ID',
                    value: id.substring(0, 12).toUpperCase() + '...',
                    trailing: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                          color: const Color(0xFFF3F0FF),
                          borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.copy_rounded,
                          size: 16, color: Color(0xFF8B5CF6)),
                    ),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _infoRow(
                    icon: Icons.history_rounded,
                    iconColor: _kPending,
                    label: 'LAST ORDER DATE',
                    value: widget.order.createdAt.substring(0, 10),
                    trailing: const Icon(Icons.chevron_right_rounded,
                        color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required Widget trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 10, color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 14, color: Color(0xFF0F172A),
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  // ── Header cell for table ──
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

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(orderProvider).isLoading;
    final isPending = widget.order.status.toUpperCase() == 'PENDING';
    final bool locked = !widget.isSeller && !isPending;

    final name =
        widget.isSeller ? widget.order.customerName : widget.order.sellerName;
    final role = widget.isSeller ? 'Customer' : 'Seller';
    final initials = name.trim().split(' ').take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();

    double computedTotal = 0;
    if (widget.isSeller) {
      for (final c in _priceControllers) {
        computedTotal += double.tryParse(c.text) ?? 0;
      }
    } else {
      computedTotal = widget.order.totalAmount;
    }

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            // ── AppBar ──
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: Color(0xFF0F172A)),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Order #${widget.order.id.substring(0, 8).toUpperCase()}',
                        style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A)),
                      ),
                    ),
                  ),
                  _statusPill(widget.order.status),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Customer/Seller header card ──
                    GestureDetector(
                      onTap: _showProfile,
                      child: Container(
                        padding: const EdgeInsets.all(14),
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
                        child: Row(
                          children: [
                            Container(
                              width: 52, height: 52,
                              decoration: const BoxDecoration(
                                  color: Color(0xFFFEF3C7),
                                  shape: BoxShape.circle),
                              child: Center(
                                child: Text(initials,
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFF59E0B))),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(role,
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF94A3B8),
                                          fontWeight: FontWeight.w500)),
                                  Text(name,
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0F172A))),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded,
                                color: Color(0xFF94A3B8)),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── Date & Items row ──
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 8)
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('DATE',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF94A3B8),
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5)),
                                const SizedBox(height: 4),
                                Text(_formatDate(widget.order.createdAt),
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F172A))),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 8)
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('ITEMS',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF94A3B8),
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5)),
                                const SizedBox(height: 4),
                                Text(
                                  '${widget.isSeller ? widget.order.items.length : _nameControllers.length} items',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F172A)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // ── Shopping List card ──
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
                        children: [
                          // Indigo banner
                          Container(
                            color: _kPrimary,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                const Icon(Icons.shopping_cart_outlined,
                                    color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                                const Text('SHOPPING LIST',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        letterSpacing: 0.5)),
                                const Spacer(),
                                if (locked)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.lock_rounded,
                                            color: Colors.white, size: 12),
                                        SizedBox(width: 4),
                                        Text('Locked',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500)),
                                      ],
                                    ),
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text('Editable',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500)),
                                  ),
                              ],
                            ),
                          ),

                          // ── Bordered Table ──
                          Table(
                            columnWidths: widget.isSeller
                                ? {
                                    0: FixedColumnWidth(
                                        MediaQuery.of(context).size.width * 0.10),
                                    1: const FlexColumnWidth(2),
                                    2: FixedColumnWidth(
                                        MediaQuery.of(context).size.width * 0.28),
                                  }
                                : locked
                                    ? {
                                        0: FixedColumnWidth(
                                            MediaQuery.of(context).size.width * 0.10),
                                        1: const FlexColumnWidth(2),
                                        2: FixedColumnWidth(
                                            MediaQuery.of(context).size.width * 0.22),
                                      }
                                    : {
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
                              // Header row — indigo tint
                              TableRow(
                                decoration: const BoxDecoration(
                                    color: Color(0xFFEEF0FA)),
                                children: [
                                  _hCell('SR'),
                                  _hCell('Item'),
                                  _hCell(widget.isSeller ? 'Price (\$)' : 'Price'),
                                  if (!widget.isSeller && !locked) _hCell(''),
                                ],
                              ),

                              // ── SELLER rows ──
                              if (widget.isSeller)
                                for (int i = 0; i < widget.order.items.length; i++)
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
                                            TableCellVerticalAlignment.middle,
                                        child: Padding(
                                          padding: const EdgeInsets.all(10),
                                          child: Text(widget.order.items[i].name,
                                              style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Color(0xFF0F172A))),
                                        ),
                                      ),
                                      TableCell(
                                        child: TextField(
                                          controller: _priceControllers[i],
                                          keyboardType:
                                              const TextInputType.numberWithOptions(
                                                  decimal: true),
                                          onChanged: (_) =>
                                              setState(() => _isDirty = true),
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                              fontSize: 14,
                                              color: _kPrimary,
                                              fontWeight: FontWeight.w600),
                                          decoration: const InputDecoration(
                                            isDense: true,
                                            contentPadding: EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 10),
                                            hintText: '0.00',
                                            prefixText: '\$ ',
                                            hintStyle: TextStyle(
                                                color: Color(0xFFCBD5E1)),
                                            border: InputBorder.none,
                                            enabledBorder: InputBorder.none,
                                            focusedBorder: UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: _kPrimary, width: 1.5)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                              // ── CUSTOMER rows ──
                              if (!widget.isSeller)
                                for (int i = 0; i < _nameControllers.length; i++)
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
                                      // Name
                                      TableCell(
                                        verticalAlignment: locked
                                            ? TableCellVerticalAlignment.middle
                                            : TableCellVerticalAlignment.top,
                                        child: locked
                                            ? Padding(
                                                padding: const EdgeInsets.all(10),
                                                child: Text(
                                                    _nameControllers[i].text,
                                                    style: const TextStyle(
                                                        fontSize: 14,
                                                        color: Color(0xFF0F172A))),
                                              )
                                            : TextField(
                                                controller: _nameControllers[i],
                                                onChanged: (_) => setState(
                                                    () => _isDirty = true),
                                                decoration: const InputDecoration(
                                                  isDense: true,
                                                  contentPadding:
                                                      EdgeInsets.symmetric(
                                                          horizontal: 10,
                                                          vertical: 10),
                                                  hintText: 'Item name',
                                                  hintStyle: TextStyle(
                                                      color: Color(0xFFCBD5E1)),
                                                  border: InputBorder.none,
                                                  enabledBorder: InputBorder.none,
                                                  focusedBorder:
                                                      UnderlineInputBorder(
                                                          borderSide: BorderSide(
                                                              color: _kPrimary,
                                                              width: 1.5)),
                                                ),
                                              ),
                                      ),
                                      // Price (read-only)
                                      TableCell(
                                        verticalAlignment:
                                            TableCellVerticalAlignment.middle,
                                        child: Center(
                                          child: Text(
                                            i < widget.order.items.length &&
                                                    widget.order.items[i].price !=
                                                        null
                                                ? '\$${widget.order.items[i].price!.toStringAsFixed(2)}'
                                                : '--',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: (i <
                                                          widget.order.items
                                                              .length &&
                                                      widget.order.items[i]
                                                              .price !=
                                                          null)
                                                  ? _kPrimary
                                                  : const Color(0xFFCBD5E1),
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Delete
                                      if (!locked)
                                        TableCell(
                                          verticalAlignment:
                                              TableCellVerticalAlignment.middle,
                                          child: Center(
                                            child: IconButton(
                                              icon: const Icon(
                                                  Icons.delete_outline_rounded,
                                                  size: 18,
                                                  color: Colors.redAccent),
                                              onPressed: () => _removeRow(i),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                            ],
                          ),

                          // ── Total row ──
                          Container(
                            color: const Color(0xFFF8FAFC),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            child: Row(
                              children: [
                                const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Total Estimate',
                                        style: TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF64748B),
                                            fontWeight: FontWeight.w500)),
                                    Text('Includes taxes',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF94A3B8))),
                                  ],
                                ),
                                const Spacer(),
                                Text(
                                  '\$ ${computedTotal.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: _kPrimary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Add Item (customer editable only) ──
                    if (!widget.isSeller && !locked) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: _addRow,
                          icon: const Icon(Icons.add_rounded, color: _kPrimary),
                          label: const Text('Add Item',
                              style: TextStyle(
                                  color: _kPrimary, fontWeight: FontWeight.w600)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: _kPrimary, width: 1.5),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30)),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // ── Bottom Save button ──
      bottomNavigationBar: locked
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: isLoading
                        ? null
                        : (widget.isSeller ? _savePrices : _saveItems),
                    icon: isLoading
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Icon(widget.isSeller
                            ? Icons.save_rounded
                            : Icons.check_circle_outline_rounded),
                    label: Text(
                      widget.isSeller ? 'Save Prices' : 'Save Changes',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPrimary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _statusPill(String status) {
    final isPending = status.toUpperCase() == 'PENDING';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: isPending ? const Color(0xFFFFF4E5) : const Color(0xFFF0FDF4),
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
            fontSize: 13),
      ),
    );
  }

  String _formatDate(String iso) {
    final d = DateTime.tryParse(iso)?.toLocal();
    if (d == null) return iso.substring(0, 10);
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}
