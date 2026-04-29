import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:human_nature_admin/providers/product_provider.dart';
import 'package:human_nature_admin/services/cloudinary_service.dart';
import 'package:image_picker/image_picker.dart';
class PaymentMethodsView extends ConsumerStatefulWidget {
  const PaymentMethodsView({super.key});

  @override
  ConsumerState<PaymentMethodsView> createState() => _PaymentMethodsViewState();
}

class _PaymentMethodsViewState extends ConsumerState<PaymentMethodsView> {
  bool _isLoading = true;
  bool _isSaving = false;

  // ── Trendyol ──
  bool _trendyolEnabled = false;
  final _trendyolLinkController = TextEditingController();
  final _trendyolDescController = TextEditingController(
    text: 'Ürün kodunu kullanarak Trendyol hesabınızda ürünü bulabilir ve sipariş verebilirsiniz.',
  );

  // ── Shopier ──
  bool _shopierEnabled = false;
  final _shopierLinkController = TextEditingController();
  final _shopierDescController = TextEditingController(
    text: 'Ürün kodunu kullanarak Shopier hesabınızda ürünü bulabilir ve sipariş verebilirsiniz.',
  );

  // ── Banka Havalesi ──
  bool _bankEnabled = false;
  final _bankNameController = TextEditingController();
  final _accountHolderController = TextEditingController();
  final _ibanController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _bankDescController = TextEditingController(
    text: 'Havale/EFT yaptıktan sonra dekontu WhatsApp üzerinden gönderiniz.',
  );
  XFile? _barcodeImageFile;
  String? _barcodeImageUrl;

  // ── Kapıda Ödeme ──
  bool _codEnabled = false;
  final _codFeePercentController = TextEditingController(text: '7');
  final _codDescController = TextEditingController(
    text: 'Siparişiniz kapınıza geldiğinde ödemenizi mevcut ödeme yöntemiyle yapabilirsiniz.',
  );

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _trendyolLinkController.dispose();
    _trendyolDescController.dispose();
    _shopierLinkController.dispose();
    _shopierDescController.dispose();
    _bankNameController.dispose();
    _accountHolderController.dispose();
    _ibanController.dispose();
    _whatsappController.dispose();
    _bankDescController.dispose();
    _codFeePercentController.dispose();
    _codDescController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final firebaseService = ref.read(firebaseServiceProvider);
    final data = await firebaseService.getPaymentMethods();

    if (data != null && mounted) {
      final trendyol = data['trendyol'] as Map<String, dynamic>? ?? {};
      final shopier = data['shopier'] as Map<String, dynamic>? ?? {};
      final bank = data['bank'] as Map<String, dynamic>? ?? {};
      final cod = data['cod'] as Map<String, dynamic>? ?? {};

      setState(() {
        _trendyolEnabled = trendyol['enabled'] ?? false;
        _trendyolLinkController.text = trendyol['link'] ?? '';
        _trendyolDescController.text = trendyol['description'] ?? _trendyolDescController.text;

        _shopierEnabled = shopier['enabled'] ?? false;
        _shopierLinkController.text = shopier['link'] ?? '';
        _shopierDescController.text = shopier['description'] ?? _shopierDescController.text;

        _bankEnabled = bank['enabled'] ?? false;
        _bankNameController.text = bank['bankName'] ?? '';
        _accountHolderController.text = bank['accountHolder'] ?? '';
        _ibanController.text = bank['iban'] ?? '';
        _whatsappController.text = bank['whatsappNumber'] ?? '';
        _bankDescController.text = bank['description'] ?? _bankDescController.text;
        _barcodeImageUrl = bank['barcodeImage'];

        _codEnabled = cod['enabled'] ?? false;
        _codFeePercentController.text = (cod['extraFeePercent'] ?? 7).toString();
        _codDescController.text = cod['description'] ?? _codDescController.text;
      });
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    final firebaseService = ref.read(firebaseServiceProvider);

    String finalBarcodeUrl = _barcodeImageUrl ?? '';
    
    if (_barcodeImageFile != null) {
      try {
        final accounts = await firebaseService.getCloudinaryAccounts();
        if (accounts.isEmpty) {
          throw Exception('Cloudinary hesapları bulunamadı. Lütfen ayarlardan hesap ekleyin.');
        }
        final account = accounts.firstWhere(
          (acc) => acc['isActive'] == true,
          orElse: () => accounts.first,
        );
        final bytes = await _barcodeImageFile!.readAsBytes();
        final url = await CloudinaryService.uploadImage(
          imageBytes: bytes,
          cloudName: account['cloudName']!,
          uploadPreset: account['uploadPreset']!,
          fileName: _barcodeImageFile!.name,
        );
        if (url != null) {
          finalBarcodeUrl = url;
        } else {
          throw Exception('Görsel yüklenirken bir hata oluştu');
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red));
        }
        return;
      }
    }

    await firebaseService.updatePaymentMethods({
      'trendyol': {
        'enabled': _trendyolEnabled,
        'link': _trendyolLinkController.text.trim(),
        'description': _trendyolDescController.text.trim(),
      },
      'shopier': {
        'enabled': _shopierEnabled,
        'link': _shopierLinkController.text.trim(),
        'description': _shopierDescController.text.trim(),
      },
      'bank': {
        'enabled': _bankEnabled,
        'bankName': _bankNameController.text.trim(),
        'accountHolder': _accountHolderController.text.trim(),
        'iban': _ibanController.text.trim(),
        'whatsappNumber': _whatsappController.text.trim(),
        'description': _bankDescController.text.trim(),
        'barcodeImage': finalBarcodeUrl,
      },
      'cod': {
        'enabled': _codEnabled,
        'extraFeePercent': int.tryParse(_codFeePercentController.text) ?? 7,
        'description': _codDescController.text.trim(),
      },
    });

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Ödeme yöntemleri başarıyla güncellendi!'),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.black));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Text(
            'ÖDEME YÖNTEMLERİ',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Mağazanızda kullanılacak ödeme yöntemlerini buradan yönetebilirsiniz. Aktif olan yöntemler müşterilere gösterilecektir.',
            style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 32),

          // ── 1. Trendyol ──
          _PaymentMethodCard(
            color: const Color(0xFFFF6000),
            icon: LucideIcons.shoppingCart,
            title: 'Trendyol',
            subtitle: 'Müşterileri Trendyol mağazanıza yönlendirin',
            enabled: _trendyolEnabled,
            onToggle: (v) => setState(() => _trendyolEnabled = v),
            children: [
              _buildField('Trendyol Mağaza Linki', _trendyolLinkController, hint: 'https://www.trendyol.com/magaza/...'),
              const SizedBox(height: 16),
              _buildField('Müşteriye Gösterilecek Mesaj', _trendyolDescController, maxLines: 2),
            ],
          ),
          const SizedBox(height: 20),

          // ── 2. Shopier ──
          _PaymentMethodCard(
            color: const Color(0xFF00C853),
            icon: LucideIcons.store,
            title: 'Shopier',
            subtitle: 'Müşterileri Shopier mağazanıza yönlendirin',
            enabled: _shopierEnabled,
            onToggle: (v) => setState(() => _shopierEnabled = v),
            children: [
              _buildField('Shopier Mağaza Linki', _shopierLinkController, hint: 'https://www.shopier.com/...'),
              const SizedBox(height: 16),
              _buildField('Müşteriye Gösterilecek Mesaj', _shopierDescController, maxLines: 2),
            ],
          ),
          const SizedBox(height: 20),

          // ── 3. Banka Havalesi ──
          _PaymentMethodCard(
            color: const Color(0xFF1565C0),
            icon: LucideIcons.landmark,
            title: 'Banka Havalesi / EFT',
            subtitle: 'IBAN bilgilerinizi girerek havale ile ödeme alın',
            enabled: _bankEnabled,
            onToggle: (v) => setState(() => _bankEnabled = v),
            children: [
              _buildField('Banka Adı', _bankNameController, hint: 'Ziraat Bankası'),
              const SizedBox(height: 16),
              _buildField('Hesap Sahibi', _accountHolderController, hint: 'Ad Soyad'),
              const SizedBox(height: 16),
              _buildField('IBAN', _ibanController, hint: 'TR00 0000 0000 0000 0000 0000 00'),
              const SizedBox(height: 16),
              _buildField('WhatsApp Numarası', _whatsappController, hint: '+905XXXXXXXXX'),
              const SizedBox(height: 16),
              _buildField('Müşteriye Gösterilecek Mesaj', _bankDescController, maxLines: 2),
              const SizedBox(height: 16),
              Text(
                'Barkod Görseli (İsteğe Bağlı)',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final picker = ImagePicker();
                  final file = await picker.pickImage(source: ImageSource.gallery);
                  if (file != null) {
                    setState(() {
                      _barcodeImageFile = file;
                    });
                  }
                },
                child: Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBFBFB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: _barcodeImageFile != null
                      ? Center(child: Text('Yeni görsel seçildi: ${_barcodeImageFile!.name}', style: const TextStyle(color: Colors.green)))
                      : (_barcodeImageUrl != null && _barcodeImageUrl!.isNotEmpty)
                          ? Image.network(_barcodeImageUrl!, fit: BoxFit.contain)
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(LucideIcons.image, color: Colors.grey.shade400, size: 32),
                                const SizedBox(height: 8),
                                Text(
                                  'Barkod görseli yüklemek için tıklayın',
                                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── 4. Kapıda Ödeme ──
          _PaymentMethodCard(
            color: const Color(0xFFFFC107),
            icon: LucideIcons.home,
            title: 'Kapıda Ödeme',
            subtitle: 'Teslimat sırasında ödeme alın',
            enabled: _codEnabled,
            onToggle: (v) => setState(() => _codEnabled = v),
            children: [
              _buildField('Ek Ücret Yüzdesi (%)', _codFeePercentController, hint: '7'),
              const SizedBox(height: 16),
              _buildField('Müşteriye Gösterilecek Mesaj', _codDescController, maxLines: 2),
            ],
          ),
          const SizedBox(height: 32),

          // ── Save Button ──
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveSettings,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(LucideIcons.save, size: 18),
              label: Text(
                'AYARLARI KAYDET',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, {String? hint, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: GoogleFonts.inter(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint ?? '$label giriniz...',
            hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 13),
            filled: true,
            fillColor: const Color(0xFFFBFBFB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.black, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}

/// Card wrapper for each payment method
class _PaymentMethodCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final ValueChanged<bool> onToggle;
  final List<Widget> children;

  const _PaymentMethodCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onToggle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: enabled ? color.withValues(alpha: 0.4) : Colors.grey.shade200,
          width: enabled ? 2 : 1,
        ),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: enabled,
                  onChanged: onToggle,
                  activeColor: color,
                ),
              ],
            ),
          ),
          // Body (if enabled)
          if (enabled)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(color: Colors.grey.shade200),
                  const SizedBox(height: 16),
                  ...children,
                ],
              ),
            ),
        ],
      ),
    );
  }
}
