import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:human_nature_admin/providers/product_provider.dart';

class StoreSettingsView extends ConsumerStatefulWidget {
  const StoreSettingsView({super.key});

  @override
  ConsumerState<StoreSettingsView> createState() => _StoreSettingsViewState();
}

class _StoreSettingsViewState extends ConsumerState<StoreSettingsView> {
  // Company Info
  final _brandNameController = TextEditingController();
  final _legalNameController = TextEditingController();
  final _mersisNoController = TextEditingController();
  final _taxOfficeController = TextEditingController();
  final _taxNoController = TextEditingController();
  final _addressController = TextEditingController();

  // Contact Info
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _workingHoursController = TextEditingController();

  // Return & Cargo
  final _returnDaysController = TextEditingController();
  final _returnCargoCompanyController = TextEditingController();
  final _returnCargoCodeController = TextEditingController();

  // About Us (Hakkımızda)
  final _founderNameController = TextEditingController();
  final _founderPhotoController = TextEditingController();
  final _aboutTextController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final firebaseService = ref.read(firebaseServiceProvider);
    final data = await firebaseService.getStoreSettings();
    
    if (data != null && mounted) {
      setState(() {
        _brandNameController.text = data['brandName'] ?? '';
        _legalNameController.text = data['legalName'] ?? '';
        _mersisNoController.text = data['mersisNo'] ?? '';
        _taxOfficeController.text = data['taxOffice'] ?? '';
        _taxNoController.text = data['taxNo'] ?? '';
        _addressController.text = data['address'] ?? '';
        
        _phoneController.text = data['phone'] ?? '';
        _emailController.text = data['email'] ?? '';
        _workingHoursController.text = data['workingHours'] ?? '';
        
        _returnDaysController.text = data['returnDays'] ?? '';
        _returnCargoCompanyController.text = data['returnCargoCompany'] ?? '';
        _returnCargoCodeController.text = data['returnCargoCode'] ?? '';

        _founderNameController.text = data['founderName'] ?? '';
        _founderPhotoController.text = data['founderPhoto'] ?? '';
        _aboutTextController.text = data['aboutText'] ?? 'Bu marka, tasarımları bizzat kurgulayan, kesimini yapan ve uzman ellerde bir araya getiren ${_founderNameController.text.isNotEmpty ? _founderNameController.text : "kurucumuz"} tarafından yönetilmektedir. 10 yılı aşkın tecrübe, siparişlerde esneklik, kusursuz ve profesyonel işçilik.';
      });
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    
    final firebaseService = ref.read(firebaseServiceProvider);
    await firebaseService.updateStoreSettings({
      'brandName': _brandNameController.text,
      'legalName': _legalNameController.text,
      'mersisNo': _mersisNoController.text,
      'taxOffice': _taxOfficeController.text,
      'taxNo': _taxNoController.text,
      'address': _addressController.text,
      
      'phone': _phoneController.text,
      'email': _emailController.text,
      'workingHours': _workingHoursController.text,
      
      'returnDays': _returnDaysController.text,
      'returnCargoCompany': _returnCargoCompanyController.text,
      'returnCargoCode': _returnCargoCodeController.text,

      'founderName': _founderNameController.text,
      'founderPhoto': _founderPhotoController.text,
      'aboutText': _aboutTextController.text,
    });
    
    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mağaza ayarları başarıyla güncellendi!'), backgroundColor: Colors.green),
      );
    }
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
            'MAĞAZA AYARLARI',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.5),
          ),
          const SizedBox(height: 8),
          const Text(
            'Buradan mağazanızın genel bilgilerini güncelleyebilirsiniz. Bu bilgiler web sitesindeki İletişim, İade ve Gizlilik sayfalarına otomatik yansıyacaktır.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),

          // Firma Bilgileri Section
          _buildSectionCard(
            title: 'Firma Bilgileri',
            icon: LucideIcons.building,
            children: [
              _buildTextField('Marka Adı', _brandNameController),
              const SizedBox(height: 16),
              _buildTextField('Ticari Ünvan', _legalNameController),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildTextField('Vergi Dairesi', _taxOfficeController)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField('Vergi No', _taxNoController)),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField('Mersis No', _mersisNoController),
              const SizedBox(height: 16),
              _buildTextField('Firma Adresi', _addressController, maxLines: 3),
            ],
          ),
          const SizedBox(height: 32),

          // İletişim Bilgileri Section
          _buildSectionCard(
            title: 'İletişim Bilgileri',
            icon: LucideIcons.phone,
            children: [
              Row(
                children: [
                  Expanded(child: _buildTextField('Müşteri Hizmetleri Telefon', _phoneController)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField('İletişim E-Posta', _emailController)),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField('Çalışma Saatleri', _workingHoursController),
            ],
          ),
          const SizedBox(height: 32),

          // İade ve Kargo Section
          _buildSectionCard(
            title: 'İade ve Kargo',
            icon: LucideIcons.packageOpen,
            children: [
              _buildTextField('İade Süresi (Gün)', _returnDaysController),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildTextField('Anlaşmalı Kargo Firması', _returnCargoCompanyController)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField('Kargo İade Kodu', _returnCargoCodeController)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Hakkımızda Section
          _buildSectionCard(
            title: 'Hakkımızda Sayfası',
            icon: LucideIcons.user,
            children: [
              _buildTextField('Kurucu Adı', _founderNameController),
              const SizedBox(height: 16),
              _buildTextField('Kurucu Fotoğrafı URL (Cloudinary\'den kopyalayın)', _founderPhotoController),
              const SizedBox(height: 16),
              _buildTextField('Hakkımızda Metni', _aboutTextController, maxLines: 4),
            ],
          ),
          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveSettings,
              icon: _isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(LucideIcons.save, size: 18),
              label: const Text('AYARLARI KAYDET', style: TextStyle(letterSpacing: 1.5, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
            ),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Colors.black87),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: '$label giriniz...',
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
