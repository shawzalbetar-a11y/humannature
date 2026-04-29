import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:human_nature_admin/services/notification_service.dart';

/// Admin page for managing notification settings.
/// Allows configuring admin email, sender email, and push/email toggles.
/// Settings are stored in Firestore: settings/notifications
class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _db = FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'humannature');

  bool _loading = true;
  bool _saving = false;

  // Form fields
  final _adminEmailController = TextEditingController();
  final _senderEmailController = TextEditingController();
  final _senderNameController = TextEditingController();
  final _resendApiKeyController = TextEditingController();
  final _senderDomainController = TextEditingController();
  bool _pushEnabled = true;
  bool _emailEnabled = true;
  bool _obscureApiKey = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _adminEmailController.dispose();
    _senderEmailController.dispose();
    _senderNameController.dispose();
    _resendApiKeyController.dispose();
    _senderDomainController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final doc = await _db.collection('settings').doc('notifications').get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        setState(() {
          _adminEmailController.text = data['adminEmail'] ?? '';
          _senderEmailController.text = data['senderEmail'] ?? 'onboarding@resend.dev';
          _senderNameController.text = data['senderName'] ?? 'HUMAN NATURE';
          _resendApiKeyController.text = data['resendApiKey'] ?? '';
          _senderDomainController.text = data['senderDomain'] ?? '';
          _pushEnabled = data['pushEnabled'] ?? true;
          _emailEnabled = data['emailEnabled'] ?? true;
        });
      } else {
        // Set defaults
        _senderEmailController.text = 'onboarding@resend.dev';
        _senderNameController.text = 'HUMAN NATURE';
      }
    } catch (e) {
      debugPrint('Error loading notification settings: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      await _db.collection('settings').doc('notifications').set({
        'adminEmail': _adminEmailController.text.trim(),
        'senderEmail': _senderEmailController.text.trim(),
        'senderName': _senderNameController.text.trim(),
        'resendApiKey': _resendApiKeyController.text.trim(),
        'senderDomain': _senderDomainController.text.trim(),
        'pushEnabled': _pushEnabled,
        'emailEnabled': _emailEnabled,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Update FCM subscription based on push toggle
      if (_pushEnabled) {
        await NotificationService().initialize();
      } else {
        await NotificationService().unsubscribeFromAdmin();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Bildirim ayarları kaydedildi ✅'),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving notification settings: $e');
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
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.black),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Form(
        key: _formKey,
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
                  child: const Icon(LucideIcons.bell, size: 24, color: Colors.black),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BİLDİRİM AYARLARI',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sipariş bildirimlerini yapılandırın',
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
            const SizedBox(height: 32),

            // ── Push Notifications Section ──
            _buildSectionCard(
              icon: LucideIcons.smartphone,
              title: 'PUSH BİLDİRİMLERİ',
              subtitle: 'Yeni sipariş alındığında anlık bildirim alın',
              children: [
                _buildToggleRow(
                  title: 'Push Bildirimleri',
                  subtitle: 'FCM üzerinden anlık bildirim (Android & Web)',
                  value: _pushEnabled,
                  onChanged: (v) => setState(() => _pushEnabled = v),
                ),
                const Divider(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Row(
                    children: [
                      Icon(LucideIcons.info, size: 18, color: Colors.blue.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Push bildirimleri Android cihazlarda otomatik olarak çalışır. '
                          'Windows masaüstünde bildirimler uygulama içi olarak gösterilir.',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.blue.shade800,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Email Notifications Section ──
            _buildSectionCard(
              icon: LucideIcons.mail,
              title: 'E-POSTA BİLDİRİMLERİ',
              subtitle: 'Sipariş özetini e-posta ile alın (Resend API)',
              children: [
                _buildToggleRow(
                  title: 'E-posta Bildirimleri',
                  subtitle: 'Resend API üzerinden e-posta gönderimi',
                  value: _emailEnabled,
                  onChanged: (v) => setState(() => _emailEnabled = v),
                ),
                const SizedBox(height: 24),
                _buildTextField(
                  controller: _adminEmailController,
                  label: 'YÖNETİCİ E-POSTA ADRESİ',
                  hint: 'admin@example.com',
                  icon: LucideIcons.atSign,
                  validator: (v) {
                    if (_emailEnabled && (v == null || v.trim().isEmpty)) {
                      return 'E-posta adresi zorunludur';
                    }
                    if (v != null && v.trim().isNotEmpty && !v.contains('@')) {
                      return 'Geçerli bir e-posta adresi girin';
                    }
                    return null;
                  },
                  helpText: 'Sipariş bildirimleri bu adrese gönderilecektir.',
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _senderNameController,
                  label: 'GÖNDEREN ADI',
                  hint: 'HUMAN NATURE',
                  icon: LucideIcons.user,
                  helpText: 'E-posta gönderen adı olarak görünecektir.',
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _senderEmailController,
                  label: 'GÖNDEREN E-POSTA',
                  hint: 'onboarding@resend.dev',
                  icon: LucideIcons.send,
                  helpText: 'Resend üzerinde doğrulanmış domain e-postası. '
                      'Henüz domain doğrulamadıysanız onboarding@resend.dev kullanın.',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Resend API Configuration Section ──
            _buildSectionCard(
              icon: LucideIcons.key,
              title: 'RESEND API YAPILANDIRMASI',
              subtitle: 'E-posta gönderim hizmeti API anahtarı ve domain ayarları',
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(LucideIcons.shieldAlert, size: 18, color: Colors.amber.shade800),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'API anahtarı güvenli bir şekilde Firestore\'da saklanır. '
                          'Bu anahtarı yalnızca Resend hesabınızdan alabilirsiniz. '
                          'resend.com/api-keys adresinden erişebilirsiniz.',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.amber.shade900,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RESEND API KEY',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _resendApiKeyController,
                      obscureText: _obscureApiKey,
                      style: GoogleFonts.inter(fontSize: 14),
                      validator: (v) {
                        if (_emailEnabled && (v == null || v.trim().isEmpty)) {
                          return 'E-posta bildirimleri aktifse API key zorunludur';
                        }
                        if (v != null && v.trim().isNotEmpty && !v.startsWith('re_')) {
                          return 'Geçerli bir Resend API key "re_" ile başlamalıdır';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: 're_xxxxxxxxxxxxxxxxxxxxxxxxxx',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey.shade400,
                        ),
                        prefixIcon: Icon(LucideIcons.key, size: 18, color: Colors.grey.shade500),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureApiKey ? LucideIcons.eyeOff : LucideIcons.eye,
                            size: 18,
                            color: Colors.grey.shade500,
                          ),
                          onPressed: () => setState(() => _obscureApiKey = !_obscureApiKey),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.black, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Resend hesabınızdan aldığınız API anahtarı. resend.com/api-keys',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _senderDomainController,
                  label: 'DOĞRULANMIŞ DOMAİN',
                  hint: 'siparis.humannature.tr',
                  icon: LucideIcons.globe,
                  helpText: 'Resend üzerinde doğrulanmış domain adı. '
                      'Domain doğrulama: resend.com/domains',
                ),
              ],
            ),
            const SizedBox(height: 32),

            // ── Save Button ──
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'AYARLARI KAYDET',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── Helper Widgets ──

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
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
              Icon(icon, size: 18, color: Colors.grey.shade600),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
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
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildToggleRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
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
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeTrackColor: Colors.black,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? helpText,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          style: GoogleFonts.inter(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey.shade400,
            ),
            prefixIcon: Icon(icon, size: 18, color: Colors.grey.shade500),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.black, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        if (helpText != null) ...[
          const SizedBox(height: 6),
          Text(
            helpText,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: Colors.grey.shade500,
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }
}
