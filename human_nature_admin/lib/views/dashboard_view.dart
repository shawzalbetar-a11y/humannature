import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:human_nature_admin/views/overview_page.dart';
import 'package:human_nature_admin/views/orders/orders_view.dart';
import 'package:human_nature_admin/views/add_product/add_product_view.dart';
import 'package:human_nature_admin/views/inventory/inventory_view.dart';
import 'package:human_nature_admin/views/pages/pages_view.dart';
import 'package:human_nature_admin/views/cloudinary_view.dart';
import 'package:human_nature_admin/views/featured_categories/featured_categories_view.dart';
import 'package:human_nature_admin/views/pages/notification_settings_page.dart';
import 'package:human_nature_admin/views/payment_methods/payment_methods_view.dart';
import 'package:human_nature_admin/widgets/sidebar.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  int _selectedIndex = 0;

  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return const OverviewPage();
      case 1:
        return const OrdersView();
      case 2:
        return const AddProductView();
      case 3:
        return const InventoryView();
      case 4:
        return const StoreSettingsView();
      case 5:
        return const CloudinaryView();
      case 6:
        return const FeaturedCategoriesView();
      case 7:
        return const NotificationSettingsPage();
      case 8:
        return const PaymentMethodsView();
      default:
        return const Scaffold(body: Center(child: Text('Page not found')));
    }
  }

  final List<String> _titles = [
    'GENEL BAKIŞ',
    'SİPARİŞLER',
    'YENİ ÜRÜN EKLE',
    'ENVANTER YÖNETİMİ',
    'MAĞAZA AYARLARI',
    'CLOUDINARY',
    'ÖNE ÇIKAN KATEGORİLER',
    'BİLDİRİM AYARLARI',
    'ÖDEME YÖNTEMLERİ',
  ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    final sidebar = Sidebar(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) {
        setState(() {
          _selectedIndex = index;
        });
        if (!isDesktop) {
          Navigator.pop(context); // Close drawer on mobile
        }
      },
    );

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            sidebar,
            Expanded(
              child: Container(
                color: Colors.grey.shade50,
                child: _getPage(_selectedIndex),
              ),
            ),
          ],
        ),
      );
    }

    // Mobile layout
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_selectedIndex],
          style: const TextStyle(letterSpacing: 2, fontSize: 16, fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: false,
        actions: [
          NotificationBadgeAction(
            onOrdersTapped: () {
              setState(() {
                _selectedIndex = 1; // SİPARİŞLER
              });
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: sidebar,
      ),
      body: Container(
        color: Colors.grey.shade50,
        child: _getPage(_selectedIndex),
      ),
    );
  }
}

class NotificationBadgeAction extends StatefulWidget {
  final VoidCallback? onOrdersTapped;
  const NotificationBadgeAction({super.key, this.onOrdersTapped});

  @override
  State<NotificationBadgeAction> createState() => _NotificationBadgeActionState();
}

class _NotificationBadgeActionState extends State<NotificationBadgeAction> {
  late final Stream<QuerySnapshot> _unreadOrdersStream;

  @override
  void initState() {
    super.initState();
     _unreadOrdersStream = FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'humannature')
        .collection('orders')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _unreadOrdersStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print("NotificationBadge Stream Error: ${snapshot.error}");
        }
        
        List<DocumentSnapshot> unreadDocs = [];
        if (snapshot.hasData) {
          unreadDocs = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['isRead'] != true;
          }).toList();
        }
        int unreadCount = unreadDocs.length;

        return PopupMenuButton<String>(
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(LucideIcons.bell),
              if (unreadCount > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 14,
                      minHeight: 14,
                    ),
                    child: Text(
                      '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          onSelected: (value) {
            if (value != 'empty' && widget.onOrdersTapped != null) {
              widget.onOrdersTapped!();
            }
          },
          itemBuilder: (context) {
            if (unreadDocs.isEmpty) {
              return [
                const PopupMenuItem(
                  value: 'empty',
                  child: Text('Okunmamış sipariş yok', style: TextStyle(fontSize: 13)),
                ),
              ];
            }
            return unreadDocs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final orderId = data['orderId'] ?? doc.id;
              return PopupMenuItem<String>(
                value: orderId,
                child: Text('Yeni Sipariş: $orderId', style: const TextStyle(fontSize: 13)),
              );
            }).toList();
          },
        );
      },
    );
  }
}

