import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:human_nature_admin/views/orders/order_detail_view.dart';

/// Admin orders page — shows all orders with real-time streaming.
class OrdersView extends StatelessWidget {
  const OrdersView({super.key});

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'humannature',
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(LucideIcons.shoppingBag, size: 24, color: Colors.black),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SİPARİŞLER',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tüm siparişleri yönetin',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Orders List ──
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: db
                    .collection('orders')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.alertCircle, size: 48, color: Colors.red.shade300),
                          const SizedBox(height: 16),
                          Text(
                            'Hata: ${snapshot.error}',
                            style: GoogleFonts.inter(color: Colors.red.shade700),
                          ),
                        ],
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.black),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];

                  if (docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.inbox, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                            'Henüz sipariş yok',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Yeni siparişler burada görünecektir.',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      return _OrderCard(
                        docId: doc.id,
                        data: data,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => OrderDetailView(
                                docId: doc.id,
                                data: data,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Single order card in the list.
class _OrderCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  const _OrderCard({
    required this.docId,
    required this.data,
    required this.onTap,
  });

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
  Widget build(BuildContext context) {
    final orderId = data['orderId'] ?? docId;
    final customerName = data['customerName'] ?? 'Bilinmiyor';
    final total = (data['total'] ?? 0).toDouble();
    final status = data['status'] ?? 'Sipariş Alındı';
    final paymentMethod = data['paymentMethod'] as String? ?? '';
    final items = data['items'] as List<dynamic>? ?? [];
    final itemCount = items.fold<int>(0, (acc, item) => acc + ((item['quantity'] ?? 1) as int));

    // Parse createdAt
    String dateStr = '';
    final createdAt = data['createdAt'];
    if (createdAt != null && createdAt is Timestamp) {
      dateStr = DateFormat('dd MMM yyyy  HH:mm', 'tr_TR').format(createdAt.toDate());
    }

    final statusCol = _statusColor(status);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              // Status icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: statusCol.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_statusIcon(status), size: 22, color: statusCol),
              ),
              const SizedBox(width: 16),

              // Order info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          orderId,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusCol.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            status,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: statusCol,
                            ),
                          ),
                        ),
                        if (paymentMethod.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: (_paymentMethodColors[paymentMethod] ?? Colors.grey).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
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
                                  size: 10,
                                  color: _paymentMethodColors[paymentMethod] ?? Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _paymentMethodLabels[paymentMethod] ?? paymentMethod,
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: _paymentMethodColors[paymentMethod] ?? Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 16,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.user, size: 13, color: Colors.grey.shade500),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                customerName,
                                style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade700),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.package, size: 13, color: Colors.grey.shade500),
                            const SizedBox(width: 6),
                            Text(
                              '$itemCount ürün',
                              style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                        if (dateStr.isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(LucideIcons.calendar, size: 13, color: Colors.grey.shade500),
                              const SizedBox(width: 6),
                              Text(
                                dateStr,
                                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Total
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₺${total.toStringAsFixed(2)}',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Icon(LucideIcons.chevronRight, size: 18, color: Colors.grey.shade400),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
