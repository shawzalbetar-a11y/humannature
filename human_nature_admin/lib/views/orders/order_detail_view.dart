import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:human_nature_admin/services/shipping_label_service.dart';

/// Detailed view for a single order.
class OrderDetailView extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;

  const OrderDetailView({
    super.key,
    required this.docId,
    required this.data,
  });

  @override
  State<OrderDetailView> createState() => _OrderDetailViewState();
}

class _OrderDetailViewState extends State<OrderDetailView> {
  late Map<String, dynamic> _data;
  bool _updatingStatus = false;

  final _db = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'humannature',
  );

  static const List<String> _statusOptions = [
    'Ödeme Bekleniyor',
    'Onay Bekleniyor',
    'Sipariş Alındı',
    'Hazırlanıyor',
    'Kargoya Verildi',
    'Teslim Edildi',
    'İptal Edildi',
  ];

  static const Map<String, Color> _paymentMethodColors = {
    'trendyol': Color(0xFFFF6000),
    'shopier': Color(0xFF00C853),
    'bank': Color(0xFF1565C0),
    'cod': Color(0xFFFFC107),
  };

  static const Map<String, String> _paymentMethodLabels = {
    'trendyol': 'Trendyol',
    'shopier': 'Shopier',
    'bank': 'Banka Havalesi',
    'cod': 'Kapıda Ödeme',
  };

  @override
  void initState() {
    super.initState();
    _data = Map<String, dynamic>.from(widget.data);
    _markAsRead();
  }

  Future<void> _markAsRead() async {
    if (_data['isRead'] == false) {
      try {
        await _db.collection('orders').doc(widget.docId).update({'isRead': true});
        
        final String? userId = _data['userId'];
        if (userId != null && userId.isNotEmpty) {
          try {
            await _db.collection('users').doc(userId).collection('customer_orders').doc(widget.docId).update({'isRead': true});
          } catch (_) {}
        }

        if (mounted) setState(() { _data['isRead'] = true; });
      } catch (e) {
        // Ignore error
      }
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Ödeme Bekleniyor':
        return Colors.amber;
      case 'Onay Bekleniyor':
        return Colors.deepOrange;
      case 'Sipariş Alındı':
        return Colors.blue;
      case 'Hazırlanıyor':
        return Colors.orange;
      case 'Kargoya Verildi':
        return Colors.purple;
      case 'Teslim Edildi':
        return Colors.green;
      case 'İptal Edildi':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'Ödeme Bekleniyor':
        return LucideIcons.clock;
      case 'Onay Bekleniyor':
        return LucideIcons.fileClock;
      case 'Sipariş Alındı':
        return LucideIcons.clipboardCheck;
      case 'Hazırlanıyor':
        return LucideIcons.package;
      case 'Kargoya Verildi':
        return LucideIcons.truck;
      case 'Teslim Edildi':
        return LucideIcons.checkCircle;
      case 'İptal Edildi':
        return LucideIcons.xCircle;
      default:
        return LucideIcons.clock;
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _updatingStatus = true);
    try {
      await _db.collection('orders').doc(widget.docId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      final String? userId = _data['userId'];
      if (userId != null && userId.isNotEmpty) {
        try {
          await _db.collection('users').doc(userId).collection('customer_orders').doc(widget.docId).update({
            'status': newStatus,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } catch (_) {}
      }

      setState(() {
        _data['status'] = newStatus;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Durum güncellendi: $newStatus'),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _updatingStatus = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderId = _data['orderId'] ?? widget.docId;
    final customerName = _data['customerName'] ?? 'Bilinmiyor';
    final customerPhone = _data['customerPhone'] ?? '';
    final total = (_data['total'] ?? 0).toDouble();
    final status = _data['status'] ?? 'Sipariş Alındı';
    final items = _data['items'] as List<dynamic>? ?? [];
    final address = _data['address'] as Map<String, dynamic>? ?? {};
    final paymentMethod = _data['paymentMethod'] as String? ?? '';
    final extraFee = (_data['extraFee'] ?? 0).toDouble();
    final subtotal = (_data['subtotal'] ?? total).toDouble();

    // Parse createdAt
    String dateStr = '';
    final createdAt = _data['createdAt'];
    if (createdAt != null && createdAt is Timestamp) {
      dateStr = DateFormat('dd MMMM yyyy  HH:mm', 'tr_TR').format(createdAt.toDate());
    }

    final statusCol = _statusColor(status);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'SİPARİŞ DETAYI',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
        actions: [
          // Print shipping label
          IconButton(
            icon: const Icon(LucideIcons.printer, size: 18),
            tooltip: 'Kargo Etiketi Yazdır',
            onPressed: () => ShippingLabelService.printLabel(_data, widget.docId),
          ),
          // Copy order ID
          IconButton(
            icon: const Icon(LucideIcons.copy, size: 18),
            tooltip: 'Sipariş No kopyala',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: orderId));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Sipariş numarası kopyalandı'),
                  duration: const Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Order Header ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Order ID & Status
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: statusCol.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(_statusIcon(status), size: 28, color: statusCol),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              orderId,
                              style: GoogleFonts.inter(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                              ),
                            ),
                            if (dateStr.isNotEmpty)
                              Text(
                                dateStr,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        '₺${total.toStringAsFixed(2)}',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(height: 1),
                  const SizedBox(height: 20),

                  // Status update
                  Row(
                    children: [
                      Text(
                        'SİPARİŞ DURUMU',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const Spacer(),
                      if (_updatingStatus)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _statusOptions.map((s) {
                      final isActive = s == status;
                      final col = _statusColor(s);
                      return InkWell(
                        onTap: _updatingStatus || isActive ? null : () => _updateStatus(s),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isActive ? col : col.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isActive ? col : col.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _statusIcon(s),
                                size: 14,
                                color: isActive ? Colors.white : col,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                s,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isActive ? Colors.white : col,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Payment Method ──
            if (paymentMethod.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _SectionCard(
                  icon: LucideIcons.creditCard,
                  title: 'ÖDEME YÖNTEMİ',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: (_paymentMethodColors[paymentMethod] ?? Colors.grey).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: (_paymentMethodColors[paymentMethod] ?? Colors.grey).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              paymentMethod == 'bank' ? LucideIcons.landmark
                                  : paymentMethod == 'cod' ? LucideIcons.home
                                  : paymentMethod == 'trendyol' ? LucideIcons.shoppingCart
                                  : LucideIcons.store,
                              size: 18,
                              color: _paymentMethodColors[paymentMethod] ?? Colors.grey,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _paymentMethodLabels[paymentMethod] ?? paymentMethod,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: _paymentMethodColors[paymentMethod] ?? Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (extraFee > 0) ...[
                        const SizedBox(height: 12),
                        _InfoRow(label: 'Ara Toplam', value: '₺${subtotal.toStringAsFixed(2)}'),
                        _InfoRow(label: 'Kapıda Ödeme Ücreti', value: '+₺${extraFee.toStringAsFixed(2)}'),
                        _InfoRow(label: 'Toplam', value: '₺${total.toStringAsFixed(2)}'),
                      ],
                    ],
                  ),
                ),
              ),

            // ── Customer Info ──
            _SectionCard(
              icon: LucideIcons.user,
              title: 'MÜŞTERİ BİLGİLERİ',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(label: 'Ad Soyad', value: customerName),
                  if (customerPhone.isNotEmpty)
                    _InfoRow(label: 'Telefon', value: customerPhone),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Delivery Address ──
            if (address.isNotEmpty)
              _SectionCard(
                icon: LucideIcons.mapPin,
                title: 'TESLİMAT ADRESİ',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (address['title'] != null)
                      _InfoRow(label: 'Başlık', value: address['title']),
                    if (address['fullName'] != null)
                      _InfoRow(label: 'Ad Soyad', value: address['fullName']),
                    if (address['phone'] != null)
                      _InfoRow(label: 'Telefon', value: address['phone']),
                    if (address['fullAddress'] != null)
                      _InfoRow(label: 'Adres', value: address['fullAddress']),
                    if (address['district'] != null || address['city'] != null)
                      _InfoRow(
                        label: 'İl / İlçe',
                        value: '${address['district'] ?? ''} / ${address['city'] ?? ''}',
                      ),
                  ],
                ),
              ),
            if (address.isNotEmpty) const SizedBox(height: 16),

            // ── Order Items ──
            _SectionCard(
              icon: LucideIcons.shoppingBag,
              title: 'SİPARİŞ KALEMLERİ (${items.length})',
              child: Column(
                children: [
                  for (int i = 0; i < items.length; i++) ...[
                    if (i > 0) const Divider(height: 24),
                    _OrderItemRow(item: items[i] as Map<String, dynamic>),
                  ],
                  const Divider(height: 32),
                  // Total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'TOPLAM TUTAR',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        '₺${total.toStringAsFixed(2)}',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Print Shipping Label Button ──
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => ShippingLabelService.printLabel(_data, widget.docId),
                icon: const Icon(LucideIcons.printer, size: 18),
                label: Text(
                  'KARGO ETİKETİ YAZDIR',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

/// Reusable section card.
class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

/// Info row (label: value).
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Single order item row.
class _OrderItemRow extends StatelessWidget {
  final Map<String, dynamic> item;

  const _OrderItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final name = item['name'] ?? 'Ürün';
    final price = (item['price'] ?? 0).toDouble();
    final quantity = (item['quantity'] ?? 1) as int;
    final size = item['size'] ?? '';
    final color = item['color'] ?? '';
    final image = item['image'] as String?;
    final lineTotal = price * quantity;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product image
        Container(
          width: 64,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.antiAlias,
          child: image != null && image.isNotEmpty
              ? Image.network(
                  image,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(
                    LucideIcons.imageOff,
                    size: 24,
                    color: Colors.grey.shade400,
                  ),
                )
              : Icon(
                  LucideIcons.package,
                  size: 24,
                  color: Colors.grey.shade400,
                ),
        ),
        const SizedBox(width: 16),

        // Product info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (size.isNotEmpty)
                    _DetailChip(label: 'Beden', value: size),
                  if (color.isNotEmpty)
                    _DetailChip(label: 'Renk', value: color),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '$quantity adet × ₺${price.toStringAsFixed(2)}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),

        // Line total
        Text(
          '₺${lineTotal.toStringAsFixed(2)}',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// Small chip for size/color details.
class _DetailChip extends StatelessWidget {
  final String label;
  final String value;

  const _DetailChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label: $value',
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }
}
