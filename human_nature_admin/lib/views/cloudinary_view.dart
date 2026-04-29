import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:human_nature_admin/providers/product_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class CloudinaryView extends ConsumerStatefulWidget {
  const CloudinaryView({super.key});

  @override
  ConsumerState<CloudinaryView> createState() => _CloudinaryViewState();
}

class _CloudinaryViewState extends ConsumerState<CloudinaryView> {
  bool _isLoading = true;
  bool _isSaving = false;
  List<Map<String, String>> _accounts = [];

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    final firebaseService = ref.read(firebaseServiceProvider);
    final data = await firebaseService.getCloudinaryAccounts();
    
    if (mounted) {
      setState(() {
        _accounts = data.map((e) => {
          'cloudName': e['cloudName']?.toString() ?? '',
          'uploadPreset': e['uploadPreset']?.toString() ?? '',
          'isActive': (e['isActive'] == true).toString(),
        }).toList();
        _isLoading = false;
      });
    }
  }

  Future<void> _saveAccounts() async {
    setState(() => _isSaving = true);
    
    try {
      final accountsToSave = _accounts.map((acc) => {
        'cloudName': acc['cloudName'],
        'uploadPreset': acc['uploadPreset'],
        'isActive': acc['isActive'] == 'true',
      }).toList();

      await FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'humannature').collection('settings').doc('cloudinary').set({
        'accounts': accountsToSave,
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cloudinary hesapları başarıyla güncellendi!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _addAccount() {
    setState(() {
      final isFirst = _accounts.isEmpty;
      _accounts.add({'cloudName': '', 'uploadPreset': '', 'isActive': isFirst.toString()});
    });
  }

  void _removeAccount(int index) {
    setState(() {
      _accounts.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CLOUDINARY HESAPLARI',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.5),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ürün görsellerini yüklemek için kullanılacak Cloudinary hesaplarını (Unsigned Upload Preset) buradan yönetebilirsiniz. Lütfen görsel yüklemesi yapılacak aktif hesabı seçin.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),

          if (_accounts.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 24.0),
              child: Text('Henüz eklenmiş bir hesap bulunmuyor.', style: TextStyle(color: Colors.red)),
            ),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _accounts.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Cloud Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
                          const SizedBox(height: 8),
                          TextFormField(
                            initialValue: _accounts[index]['cloudName'],
                            onChanged: (val) => _accounts[index]['cloudName'] = val,
                            decoration: InputDecoration(
                              hintText: 'Cloud Name',
                              filled: true,
                              fillColor: const Color(0xFFFBFBFB),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black, width: 1.5)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Upload Preset', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
                          const SizedBox(height: 8),
                          TextFormField(
                            initialValue: _accounts[index]['uploadPreset'],
                            onChanged: (val) => _accounts[index]['uploadPreset'] = val,
                            decoration: InputDecoration(
                              hintText: 'Unsigned Upload Preset',
                              filled: true,
                              fillColor: const Color(0xFFFBFBFB),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black, width: 1.5)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      children: [
                        const Text('Aktif', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
                        const SizedBox(height: 8),
                        Switch(
                          value: _accounts[index]['isActive'] == 'true',
                          onChanged: (val) {
                            if (val) {
                              setState(() {
                                for (var acc in _accounts) {
                                  acc['isActive'] = 'false';
                                }
                                _accounts[index]['isActive'] = 'true';
                              });
                            } else {
                              // If they turn it off, but it's the only one, maybe don't let them?
                              // Or let them, but AddProductView will fallback to first
                              setState(() {
                                _accounts[index]['isActive'] = 'false';
                              });
                            }
                          },
                          activeThumbColor: Colors.black,
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Padding(
                      padding: const EdgeInsets.only(top: 24.0),
                      child: IconButton(
                        icon: const Icon(LucideIcons.trash2, color: Colors.red),
                        onPressed: () => _removeAccount(index),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _addAccount,
            icon: const Icon(LucideIcons.plus, size: 18),
            label: const Text('YENİ HESAP EKLE'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              foregroundColor: Colors.black,
            ),
          ),

          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveAccounts,
              icon: _isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(LucideIcons.save, size: 18),
              label: const Text('HESAPLARI KAYDET', style: TextStyle(letterSpacing: 1.5, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
            ),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }
}
