import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:human_nature_admin/providers/product_provider.dart';

class PricingStep extends ConsumerWidget {
  const PricingStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formNotifier = ref.read(productFormProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'FİYATLANDIRMA VE TEKLİFLER',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        const Text(
          'Müşterilerin göreceği satış fiyatlarını ve indirimleri belirleyin.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Liste Fiyatı',
                  suffixText: 'TL',
                  hintText: '0.00',
                ),
                onChanged: (val) => formNotifier.updateOriginalPrice(double.tryParse(val) ?? 0),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'İndirimli Satış Fiyatı',
                  suffixText: 'TL',
                  hintText: '0.00',
                ),
                onChanged: (val) => formNotifier.updateDiscountPrice(double.tryParse(val) ?? 0),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Sepette Ek İndirimli Fiyat (Opsiyonel)',
            suffixText: 'TL',
            helperText: 'Örn: Sepette %10 indirim uygulanmış hali',
            hintText: '0.00',
          ),
          onChanged: (val) => formNotifier.updateCartPrice(double.tryParse(val)),
        ),
        const SizedBox(height: 16),
        TextFormField(
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Kalan Stok Adedi',
            helperText: 'Bu ürün için toplam kaç adet stokta var?',
            hintText: '0',
          ),
          onChanged: (val) => formNotifier.updateStockCount(int.tryParse(val) ?? 0),
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.amber, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'İndirimli fiyat liste fiyatından düşük olmalıdır. Sepet fiyatı ise en son uygulanacak fiyattır.',
                  style: TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
