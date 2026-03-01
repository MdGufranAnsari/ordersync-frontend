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
  final TextEditingController _codeController = TextEditingController();
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
    _codeController.dispose();
    super.dispose();
  }

  // ── Lifecycle action helpers ──

  Future<void> _confirmOrder(String pickupType) async {
    final success = await ref.read(orderProvider.notifier).confirmOrder(
      orderId: widget.order.id,
      pickupType: pickupType,
    );
    if (!mounted) return;
    if (success) {
      _snack(
        pickupType == 'immediate'
            ? 'Order confirmed! Please collect at the shop.'
            : 'Order confirmed! Pickup code sent.',
        _kPriced,
      );
      Navigator.pop(context);
    } else {
      _snack(ref.read(orderProvider).error ?? 'Failed', Colors.redAccent);
    }
  }

  void _showConfirmPickupDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const Text('Choose Pickup Type',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text(
              'How will you collect your order?',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 20),
            // Immediate
            _pickupOption(
              icon: Icons.store_rounded,
              color: _kPrimary,
              title: 'Immediate Pickup',
              subtitle: 'Go to the shop now and collect directly.',
              onTap: () { Navigator.pop(context); _confirmOrder('immediate'); },
            ),
            const SizedBox(height: 12),
            // Later
            _pickupOption(
              icon: Icons.schedule_rounded,
              color: _kPending,
              title: 'Later Pickup',
              subtitle: 'Seller prepares order. You get a pickup code.',
              onTap: () { Navigator.pop(context); _confirmOrder('later'); },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _pickupOption({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: color.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(14),
            color: color.withOpacity(0.05),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: color,
                            fontSize: 15)),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: color),
            ],
          ),
        ),
      );

  Future<void> _markReady() async {
    final success = await ref.read(orderProvider.notifier).markReady(
          orderId: widget.order.id);
    if (!mounted) return;
    if (success) {
      _snack('Order marked ready! 2-hour countdown started.', _kPriced);
      Navigator.pop(context);
    } else {
      _snack(ref.read(orderProvider).error ?? 'Failed', Colors.redAccent);
    }
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.length != 4) {
      _snack('Enter the 4-digit pickup code.', Colors.orange);
      return;
    }
    final success = await ref.read(orderProvider.notifier).verifyCode(
          orderId: widget.order.id, code: code);
    if (!mounted) return;
    if (success) {
      _snack('Code verified! Order completed.', _kPriced);
      Navigator.pop(context);
    } else {
      _snack(ref.read(orderProvider).error ?? 'Wrong code', Colors.redAccent);
    }
  }

  Future<void> _completeOrder() async {
    final success = await ref.read(orderProvider.notifier).completeOrder(
          orderId: widget.order.id);
    if (!mounted) return;
    if (success) {
      _snack('Order marked as completed!', _kPriced);
      Navigator.pop(context);
    } else {
      _snack(ref.read(orderProvider).error ?? 'Failed', Colors.redAccent);
    }
  }

  Future<void> _reportNoShow() async {
    final result = await ref.read(orderProvider.notifier).reportNoShow(
          orderId: widget.order.id);
    if (!mounted) return;
    if (result != null) {
      final restricted = result['restricted'] as bool? ?? false;
      final count = result['noShowCount'] as int? ?? 0;
      _snack(
        restricted
            ? 'Customer account restricted after $count no-shows.'
            : 'No-show recorded. Strike $count/3.',
        Colors.redAccent,
      );
      Navigator.pop(context);
    } else {
      _snack(ref.read(orderProvider).error ?? 'Failed', Colors.redAccent);
    }
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
                  const SizedBox(width: 48), // Balance for back button
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

                    // ── Status Stepper ──
                    _buildStepper(),

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

                    // ── Lifecycle Info Card ──
                    _buildLifecycleCard(),

                    // ── Seller: code entry field when status=ready ──
                    if (widget.isSeller && widget.order.status == 'ready') ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10)],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Enter Pickup Code',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Color(0xFF0F172A))),
                            const SizedBox(height: 4),
                            const Text(
                              'Ask the customer for their 4-digit code',
                              style: TextStyle(
                                  fontSize: 12, color: Color(0xFF94A3B8)),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _codeController,
                              keyboardType: TextInputType.number,
                              maxLength: 4,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 12,
                                  color: _kPrimary),
                              decoration: InputDecoration(
                                counterText: '',
                                hintText: '_ _ _ _',
                                hintStyle: const TextStyle(
                                    color: Color(0xFFCBD5E1),
                                    letterSpacing: 8,
                                    fontSize: 22),
                                filled: true,
                                fillColor: const Color(0xFFF1F5F9),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // ── Seller: expired_pending_confirmation buttons ──
                    if (widget.isSeller && widget.order.status == 'expired_pending_confirmation') ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFED7AA)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.help_outline_rounded,
                                    color: Color(0xFFF97316), size: 20),
                                SizedBox(width: 8),
                                Text('Did the customer collect?',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: Color(0xFF0F172A))),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Pickup deadline has passed. Confirm whether the customer actually collected the order.',
                              style: TextStyle(
                                  fontSize: 12, color: Color(0xFF64748B)),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: ref.watch(orderProvider).isLoading
                                        ? null
                                        : _reportNoShow,
                                    icon: const Icon(Icons.close_rounded,
                                        color: Colors.redAccent),
                                    label: const Text('No, did not collect',
                                        style: TextStyle(
                                            color: Colors.redAccent,
                                            fontWeight: FontWeight.w600)),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                          color: Colors.redAccent),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(30)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: ref.watch(orderProvider).isLoading
                                        ? null
                                        : _completeOrder,
                                    icon: const Icon(
                                        Icons.check_circle_outline_rounded),
                                    label: const Text('Yes, collected',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _kPriced,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(30)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
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

      // ── Bottom action bar ──
      bottomNavigationBar: _buildBottomBar(isLoading),
    );
  }

  Widget? _buildBottomBar(bool isLoading) {
    final status = widget.order.status;

    // ── Customer side ──
    if (!widget.isSeller) {
      if (status == 'PENDING') {
        // Customer can edit and save items
        return _actionBar(
          isLoading: isLoading,
          label: 'Save Changes',
          icon: Icons.check_circle_outline_rounded,
          color: _kPrimary,
          onTap: _saveItems,
        );
      }
      if (status == 'PRICED') {
        // Customer confirms pickup type
        return _actionBar(
          isLoading: isLoading,
          label: 'Confirm Order',
          icon: Icons.check_circle_outline_rounded,
          color: _kPriced,
          onTap: _showConfirmPickupDialog,
        );
      }
      return null; // All other statuses: no bottom action for customer
    }

    // ── Seller side ──
    if (status == 'PENDING') {
      // Seller sets prices
      return _actionBar(
        isLoading: isLoading,
        label: 'Save Prices',
        icon: Icons.save_rounded,
        color: _kPrimary,
        onTap: _savePrices,
      );
    }
    if (status == 'confirmed_immediate') {
      return _actionBar(
        isLoading: isLoading,
        label: 'Complete Order',
        icon: Icons.check_circle_outline_rounded,
        color: _kPriced,
        onTap: _completeOrder,
      );
    }
    if (status == 'confirmed') {
      return _actionBar(
        isLoading: isLoading,
        label: 'Mark Ready',
        icon: Icons.inventory_2_outlined,
        color: _kPrimary,
        onTap: _markReady,
      );
    }
    if (status == 'ready') {
      return _actionBar(
        isLoading: isLoading,
        label: 'Verify Code & Complete',
        icon: Icons.verified_outlined,
        color: _kPriced,
        onTap: _verifyCode,
      );
    }
    // expired_pending_confirmation: buttons are inline in the card, not bottom bar
    return null;
  }

  Widget _actionBar({
    required bool isLoading,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) =>
      SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : onTap,
              icon: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Icon(icon),
              label: Text(label,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ),
        ),
      );

  // ── Pickup code / deadline info card ──
  Widget _buildLifecycleCard() {
    final status = widget.order.status;
    final code = widget.order.pickupCode;
    final deadline = widget.order.pickupDeadlineLocal;

    // Customer: show pickup code when confirmed/ready
    if (!widget.isSeller && code != null && (status == 'confirmed' || status == 'ready')) {
      final remaining = deadline != null ? deadline.difference(DateTime.now()) : null;
      final isExpiringSoon =
          remaining != null && remaining.inMinutes <= 30 && remaining.inMinutes > 0;
      final isExpired = remaining != null && remaining.isNegative;

      return Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: isExpired
                    ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                    : isExpiringSoon
                        ? [_kPending, const Color(0xFFEA580C)]
                        : [_kPrimary, const Color(0xFF6366F1)],
              ),
            ),
            child: Column(
              children: [
                const Text('YOUR PICKUP CODE',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2)),
                const SizedBox(height: 8),
                Text(
                  code.split('').join('  '),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Show this code to the seller when collecting.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                if (deadline != null && status == 'ready') ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isExpired
                          ? 'Pickup deadline has passed'
                          : 'Collect before ${_fmt2(deadline)}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    }

    // Seller: show deadline info on ready orders
    if (widget.isSeller && status == 'ready' && deadline != null) {
      final remaining = deadline.difference(DateTime.now());
      final mins = remaining.inMinutes;
      final label = mins <= 0 ? 'Deadline passed' : '${mins} min remaining';
      final color = mins <= 0 ? Colors.redAccent : mins <= 30 ? _kPending : _kPriced;

      return Column(
        children: [
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withOpacity(0.35)),
            ),
            child: Row(
              children: [
                Icon(Icons.timer_outlined, color: color, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pickup Deadline',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: color)),
                      Text(_fmt2(deadline),
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(label,
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w600,
                          fontSize: 12)),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  String _fmt2(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : dt.hour == 0 ? 12 : dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }

  Widget _buildStepper() {
    final status = widget.order.status.toUpperCase();
    final pickupType = widget.order.pickupType;

    // Define the sequence of steps based on pickup type (if known)
    List<String> steps;
    if (pickupType == 'immediate' || status == 'CONFIRMED_IMMEDIATE') {
      steps = ['PENDING', 'PRICED', 'CONFIRMED_IMMEDIATE', 'COMPLETED'];
    } else {
      steps = ['PENDING', 'PRICED', 'CONFIRMED', 'READY', 'COMPLETED'];
    }

    // Handle failure states
    bool isExpired = status == 'EXPIRED' || status == 'EXPIRED_PENDING_CONFIRMATION';
    if (isExpired) {
      if (!steps.contains(status)) {
        // If expired, replace later steps with expired
        if (status == 'EXPIRED_PENDING_CONFIRMATION') {
          steps = ['PENDING', 'PRICED', 'EXPIRED_PENDING_CONFIRMATION'];
        } else {
          // General expiry (e.g., no-show)
          int readyIdx = steps.indexOf('READY');
          if (readyIdx != -1) {
             steps = steps.sublist(0, readyIdx + 1)..add('EXPIRED');
          } else {
             steps.add('EXPIRED');
          }
        }
      }
    }

    // Find current index
    int currentIndex = steps.indexOf(status);
    if (currentIndex == -1) {
      // Fallback if status not in list (e.g. migrating data)
      if (status == 'COMPLETED') currentIndex = steps.length - 1;
      else currentIndex = 0;
    }

    // Mapping for display
    final Map<String, (String, String, Color)> displayMap = {
      'PENDING': ('Order Sent', 'Customer prepared the list', _kPending),
      'PRICED': ('Priced by Seller', 'Prices added, awaiting confirmation', _kPriced),
      'CONFIRMED': ('Confirmed', 'Customer confirmed, preparing order', _kPrimary),
      'CONFIRMED_IMMEDIATE': ('Confirmed (Immediate)', 'Customer is arriving to collect', _kPrimary),
      'READY': ('Ready for Pick-Up', 'Order packed and awaiting collection', _kPending),
      'COMPLETED': ('Completed', 'Order successfully collected', _kPriced),
      'EXPIRED_PENDING_CONFIRMATION': ('Expired', 'Not confirmed in time', Colors.redAccent),
      'EXPIRED': ('Cancelled/No-Show', 'Order was not collected', Colors.redAccent),
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ORDER STATUS',
              style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5)),
          const SizedBox(height: 16),
          ...List.generate(steps.length, (i) {
            final stepKey = steps[i];
            final isCompleted = i <= currentIndex;
            final isCurrent = i == currentIndex;
            final isLast = i == steps.length - 1;
            
            final displayInfo = displayMap[stepKey] ?? (stepKey, '', Colors.grey);
            final title = displayInfo.$1;
            final subtitle = displayInfo.$2;
            final color = displayInfo.$3;
            
            // Adjust colors for past vs current vs future
            final markerColor = isCompleted ? color : Colors.grey.shade300;
            final titleColor = isCompleted ? const Color(0xFF0F172A) : Colors.grey.shade400;
            final subtitleColor = isCompleted ? const Color(0xFF64748B) : Colors.grey.shade300;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    // Marker
                    Container(
                      width: 20, height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted ? markerColor : Colors.white,
                        border: Border.all(
                          color: isCompleted ? markerColor : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: isCompleted
                          ? const Icon(Icons.check_rounded, size: 12, color: Colors.white)
                          : null,
                    ),
                    // Line
                    if (!isLast)
                      Container(
                        width: 2, height: 36,
                        color: i < currentIndex ? markerColor : Colors.grey.shade200,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                              color: titleColor)),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(subtitle,
                            style: TextStyle(fontSize: 12, color: subtitleColor)),
                      ],
                      if (!isLast) const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            );
          }),
        ],
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
