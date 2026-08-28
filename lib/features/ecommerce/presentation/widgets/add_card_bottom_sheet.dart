import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/card_network.dart';
import '../../domain/entities/payment_card.dart';
import '../providers/card_provider.dart';

/// Muestra el bottom sheet para agregar una nueva tarjeta.
Future<void> showAddCardBottomSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _AddCardBottomSheet(),
  );
}

class _AddCardBottomSheet extends ConsumerStatefulWidget {
  const _AddCardBottomSheet();

  @override
  ConsumerState<_AddCardBottomSheet> createState() =>
      _AddCardBottomSheetState();
}

class _AddCardBottomSheetState extends ConsumerState<_AddCardBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _numberController = TextEditingController();
  final _holderController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();

  CardNetwork _detectedNetwork = CardNetwork.unknown;

  @override
  void dispose() {
    _numberController.dispose();
    _holderController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  void _onNumberChanged(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    setState(() => _detectedNetwork = detectCardNetwork(digits));
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final rawDigits =
        _numberController.text.replaceAll(RegExp(r'\D'), '');
    // Formatea el número con espacios cada 4 dígitos
    final formatted = rawDigits.replaceAllMapped(
      RegExp(r'.{1,4}'),
      (m) => '${m.group(0)} ',
    ).trim();

    final card = PaymentCard(
      number: formatted,
      holderName: _holderController.text.trim().toUpperCase(),
      network: _detectedNetwork,
      behavior: CardBehavior.approved,
    );

    ref.read(cardListProvider.notifier).addCard(card).then((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle decorativo
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              const Text(
                'Add new card',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 20),

              // ── Número de tarjeta ───────────────────────────────────────
              _FieldLabel('Card number'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _numberController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _CardNumberFormatter(),
                ],
                maxLength: 19, // 16 dígitos + 3 espacios
                onChanged: _onNumberChanged,
                decoration: _inputDecoration(
                  hint: '0000 0000 0000 0000',
                  suffix: _NetworkBadge(network: _detectedNetwork),
                ),
                validator: (v) {
                  final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
                  if (digits.length < 13) return 'Enter a valid card number';
                  return null;
                },
              ),

              const SizedBox(height: 12),

              // ── Nombre del titular ──────────────────────────────────────
              _FieldLabel('Cardholder name'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _holderController,
                textCapitalization: TextCapitalization.characters,
                decoration: _inputDecoration(hint: 'Name on card'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter cardholder name' : null,
              ),

              const SizedBox(height: 12),

              // ── Expiry + CVV ────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FieldLabel('Expiry date'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _expiryController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            _ExpiryFormatter(),
                          ],
                          maxLength: 5,
                          decoration: _inputDecoration(hint: 'MM/YY'),
                          validator: (v) {
                            final clean = (v ?? '').replaceAll('/', '');
                            if (clean.length < 4) return 'Invalid date';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FieldLabel('CVV'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _cvvController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          maxLength: 4,
                          obscureText: true,
                          decoration: _inputDecoration(hint: '•••'),
                          validator: (v) {
                            if ((v ?? '').length < 3) return 'Invalid CVV';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── Botón agregar ───────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Add Card',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint, Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textGray, fontSize: 14),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF4F6FA),
      counterText: '',
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }
}

// ─── Label de campo ───────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
      ),
    );
  }
}

// ─── Badge de red detectada ───────────────────────────────────────────────────

class _NetworkBadge extends StatelessWidget {
  final CardNetwork network;
  const _NetworkBadge({required this.network});

  @override
  Widget build(BuildContext context) {
    if (network == CardNetwork.unknown) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.lightBlue,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          network.displayName,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

// ─── Formatters ───────────────────────────────────────────────────────────────

/// Agrupa los dígitos de la tarjeta en bloques de 4 separados por espacio.
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length && i < 16; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final formatted = buffer.toString();
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Formatea la fecha de vencimiento como MM/YY.
class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length && i < 4; i++) {
      if (i == 2) buffer.write('/');
      buffer.write(digits[i]);
    }
    final formatted = buffer.toString();
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
