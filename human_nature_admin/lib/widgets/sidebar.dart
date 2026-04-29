import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class Sidebar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onDestinationSelected;

  const Sidebar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
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
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HUMAN',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  'NATURE ADMIN',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 4,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _SidebarItem(
            icon: LucideIcons.layoutDashboard,
            label: 'GENEL BAKIŞ',
            isSelected: widget.selectedIndex == 0,
            onTap: () => widget.onDestinationSelected(0),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: _unreadOrdersStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                print("Sidebar Stream Error: ${snapshot.error}");
              }
              int unreadCount = 0;
              if (snapshot.hasData) {
                unreadCount = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['isRead'] != true;
                }).length;
              }
              return _SidebarItem(
                icon: LucideIcons.shoppingBag,
                label: 'SİPARİŞLER',
                isSelected: widget.selectedIndex == 1,
                onTap: () => widget.onDestinationSelected(1),
                trailing: unreadCount > 0
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : null,
              );
            },
          ),
          _SidebarItem(
            icon: LucideIcons.plusCircle,
            label: 'ÜRÜN EKLE',
            isSelected: widget.selectedIndex == 2,
            onTap: () => widget.onDestinationSelected(2),
          ),
          _SidebarItem(
            icon: LucideIcons.package,
            label: 'ENVANTER',
            isSelected: widget.selectedIndex == 3,
            onTap: () => widget.onDestinationSelected(3),
          ),
          _SidebarItem(
            icon: LucideIcons.settings,
            label: 'MAĞAZA AYARLARI',
            isSelected: widget.selectedIndex == 4,
            onTap: () => widget.onDestinationSelected(4),
          ),
          _SidebarItem(
            icon: LucideIcons.cloud,
            label: 'CLOUDINARY',
            isSelected: widget.selectedIndex == 5,
            onTap: () => widget.onDestinationSelected(5),
          ),
          _SidebarItem(
            icon: LucideIcons.layoutGrid,
            label: 'ÖNE ÇIKAN',
            isSelected: widget.selectedIndex == 6,
            onTap: () => widget.onDestinationSelected(6),
          ),
          _SidebarItem(
            icon: LucideIcons.bell,
            label: 'BİLDİRİMLER',
            isSelected: widget.selectedIndex == 7,
            onTap: () => widget.onDestinationSelected(7),
          ),
          _SidebarItem(
            icon: LucideIcons.creditCard,
            label: 'ÖDEME YÖNTEMLERİ',
            isSelected: widget.selectedIndex == 8,
            onTap: () => widget.onDestinationSelected(8),
          ),
          const Spacer(),
          const Divider(),
          _SidebarItem(
            icon: LucideIcons.logOut,
            label: 'ÇIKIŞ YAP',
            isSelected: false,
            onTap: () {},
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Widget? trailing;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.black.withValues(alpha: 0.05) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.black : Colors.grey,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.black : Colors.grey.shade700,
                    letterSpacing: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ] else if (isSelected) ...[
                const SizedBox(width: 8),
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
