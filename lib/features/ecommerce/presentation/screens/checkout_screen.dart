import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/notifications/notification_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/card_network.dart';
import '../../domain/entities/payment_card.dart';
import '../providers/card_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/order_provider.dart';
import '../providers/payment_provider.dart';
import '../widgets/add_card_bottom_sheet.dart';
import 'order_confirmation_screen.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  // Método de pago seleccionado: 'credit_card' o 'apple_pay'
  String _selectedMethod = 'credit_card';

  // Número de la tarjeta seleccionada dentro de Credit Card
  String _selectedCard = '5555 5555 5555 4444';

  // Checkbox de billing address
  bool _sameAddress = true;

  // Indica si se está procesando el pago
  bool _isProcessing = false;

  Future<void> _processPayment() async {
    final cartItems = ref.read(cartProvider);
    if (cartItems.isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      final total = ref.read(cartProvider.notifier).total;

      // Para credit_card: llama al servicio real de pagos
      if (_selectedMethod == 'credit_card') {
        final paymentResult = await ref.read(processPaymentUseCaseProvider)(
          cardNumber: _selectedCard,
          amount: total,
        );

        if (!paymentResult.isApproved) {
          if (mounted) {
            setState(() => _isProcessing = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(paymentResult.message),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
          return;
        }
      }

      final order = await ref
          .read(orderProvider.notifier)
          .placeOrder(
            items: cartItems,
            total: total,
            paymentMethod: _selectedMethod,
            selectedCard: _selectedMethod == 'credit_card'
                ? _selectedCard
                : null,
          );

      // Vacía el carrito una vez confirmada la orden
      ref.read(cartProvider.notifier).clearAll();

      NotificationService.showPurchaseNotification(total, order.id);

      if (!mounted) return;

      // Navega a la pantalla de confirmación reemplazando el checkout
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => OrderConfirmationScreen(order: order),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().contains('PaymentApiException')
                ? e.toString().replaceFirst('PaymentApiException: ', '')
                : 'Payment failed. Please try again.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final testCards = ref.watch(testCardsProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(color: AppColors.primary, fontSize: 15),
          ),
        ),
        title: const Text(
          'Checkout',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Stepper de pasos
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: const _CheckoutStepper(currentStep: 2),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título
                  const Text(
                    'Choose a payment method',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "You won't be charged until you review the order on the next page",
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textGray,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Opción: Credit Card
                  _PaymentOptionCard(
                    label: 'Credit Card',
                    isSelected: _selectedMethod == 'credit_card',
                    onTap: () =>
                        setState(() => _selectedMethod = 'credit_card'),
                    child: _selectedMethod == 'credit_card'
                        ? _CreditCardSection(
                            cards: testCards,
                            selectedCard: _selectedCard,
                            sameAddress: _sameAddress,
                            onCardSelected: (card) =>
                                setState(() => _selectedCard = card),
                            onSameAddressChanged: (value) =>
                                setState(() => _sameAddress = value),
                            onAddCard: () => showAddCardBottomSheet(context),
                          )
                        : null,
                  ),

                  const SizedBox(height: 12),

                  // Opción: Apple Pay
                  _PaymentOptionCard(
                    label: 'Apple Pay',
                    isSelected: _selectedMethod == 'apple_pay',
                    onTap: () => setState(() => _selectedMethod = 'apple_pay'),
                    child: null,
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Botón Process Payment
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.primary.withAlpha(140),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Process Payment',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stepper de 3 pasos ──────────────────────────────────────────────────────

class _CheckoutStepper extends StatelessWidget {
  final int currentStep; // 0: bag, 1: shipping, 2: payment

  const _CheckoutStepper({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final steps = ['Your bag', 'Shipping', 'Payment'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(steps.length, (index) {
        final isDone = index < currentStep;
        final isActive = index == currentStep;

        return Row(
          children: [
            Column(
              children: [
                // Círculo del paso
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isDone || isActive
                        ? AppColors.primary
                        : const Color(0xFFE0E0E0),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isDone
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: isActive
                                  ? Colors.white
                                  : AppColors.textGray,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  steps[index],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.normal,
                    color: isActive ? AppColors.textDark : AppColors.textGray,
                  ),
                ),
              ],
            ),
            // Línea conectora entre pasos
            if (index < steps.length - 1)
              Container(
                width: 48,
                height: 1,
                margin: const EdgeInsets.only(bottom: 18),
                color: index < currentStep
                    ? AppColors.primary
                    : const Color(0xFFE0E0E0),
              ),
          ],
        );
      }),
    );
  }
}

// ─── Contenedor de opción de pago ────────────────────────────────────────────

class _PaymentOptionCard extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Widget? child;

  const _PaymentOptionCard({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Radio button
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.border,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? Center(
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
            ?child,
          ],
        ),
      ),
    );
  }
}

// ─── Contenido expandido de Credit Card ──────────────────────────────────────

class _CreditCardSection extends StatelessWidget {
  final List<PaymentCard> cards;
  final String selectedCard;
  final bool sameAddress;
  final ValueChanged<String> onCardSelected;
  final ValueChanged<bool> onSameAddressChanged;
  final VoidCallback onAddCard;

  const _CreditCardSection({
    required this.cards,
    required this.selectedCard,
    required this.sameAddress,
    required this.onCardSelected,
    required this.onSameAddressChanged,
    required this.onAddCard,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          // Lista de tarjetas del mock
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                for (int i = 0; i < cards.length; i++) ...[
                  _CardTile(
                    brand:
                        '${cards[i].network.displayName}  ·  ${cards[i].holderName}',
                    masked: cards[i].maskedNumber,
                    isSelected: selectedCard == cards[i].number,
                    onTap: () => onCardSelected(cards[i].number),
                  ),
                  if (i < cards.length - 1)
                    const Divider(height: 1, indent: 16, endIndent: 16),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Agregar nueva tarjeta
          GestureDetector(
            onTap: onAddCard,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, color: AppColors.primary, size: 18),
                SizedBox(width: 4),
                Text(
                  'Add new card',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Checkbox billing address
          GestureDetector(
            onTap: () => onSameAddressChanged(!sameAddress),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: sameAddress ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: sameAddress ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  child: sameAddress
                      ? const Icon(Icons.check, color: Colors.white, size: 14)
                      : null,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'My billing address is the same as my shipping address',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textGray,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Fila de tarjeta individual ───────────────────────────────────────────────

class _CardTile extends StatelessWidget {
  final String brand;
  final String masked;
  final bool isSelected;
  final VoidCallback onTap;

  const _CardTile({
    required this.brand,
    required this.masked,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.lightBlue : const Color(0xFFF4F6FA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    brand,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    masked,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textGray,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }
}
