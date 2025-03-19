import 'package:flutter/material.dart';
import 'package:vocallabs_flutter_app/utils/constants.dart';
import 'package:vocallabs_flutter_app/widgets/card_layout.dart';
import 'package:vocallabs_flutter_app/widgets/custom_button.dart';

class PaymentGatewayScreen extends StatefulWidget {
  const PaymentGatewayScreen({super.key});

  @override
  State<PaymentGatewayScreen> createState() => _PaymentGatewayScreenState();
}

class _PaymentGatewayScreenState extends State<PaymentGatewayScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedPaymentMethod = 'card';
  final _cardNumberController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvvController = TextEditingController();
  bool _isSaving = false;
  String _selectedPlan = 'Monthly'; // Default value
  String _planPrice = '\$9.99'; // Default value

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        setState(() {
          _selectedPlan = args['plan'] as String;
          _planPrice = _selectedPlan == 'Monthly' ? '\$9.99' : '\$79.99';
        });
      }
    });
  }

  Future<void> _processPayment() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isSaving = true;
      });

      // Simulate payment processing
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _isSaving = false;
      });

      if (!mounted) return;

      // Show success dialog
      _showSuccessDialog();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.success, size: 24),
                SizedBox(width: 8),
                Text('Payment Successful'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your payment for the $_selectedPlan plan was successful.',
                  style: AppTextStyles.body1,
                ),
                const SizedBox(height: 8),
                const Text(
                  'You now have access to all premium features.',
                  style: AppTextStyles.body2,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/profile',
                    (route) => false,
                  );
                },
                child: const Text('Go to Profile'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Payment'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: AppPadding.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Summary
              const Text('Order Summary', style: AppTextStyles.heading2),
              const SizedBox(height: 16),
              CardLayout(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'VocalLabs Pro $_selectedPlan',
                          style: AppTextStyles.body1.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _planPrice,
                          style: AppTextStyles.body1.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _planPrice,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Payment Methods
              const Text('Payment Method', style: AppTextStyles.heading2),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap:
                          () => setState(() => _selectedPaymentMethod = 'card'),
                      child: CardLayout(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color:
                                  _selectedPaymentMethod == 'card'
                                      ? AppColors.primaryBlue
                                      : Colors.transparent,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.credit_card,
                                color:
                                    _selectedPaymentMethod == 'card'
                                        ? AppColors.primaryBlue
                                        : Colors.grey,
                                size: 32,
                              ),
                              const SizedBox(height: 8),
                              const Text('Credit Card'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap:
                          () =>
                              setState(() => _selectedPaymentMethod = 'paypal'),
                      child: CardLayout(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color:
                                  _selectedPaymentMethod == 'paypal'
                                      ? AppColors.primaryBlue
                                      : Colors.transparent,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.account_balance_wallet,
                                color:
                                    _selectedPaymentMethod == 'paypal'
                                        ? AppColors.primaryBlue
                                        : Colors.grey,
                                size: 32,
                              ),
                              const SizedBox(height: 8),
                              const Text('PayPal'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Payment Details Form
              if (_selectedPaymentMethod == 'card') ...[
                const Text('Card Details', style: AppTextStyles.heading2),
                const SizedBox(height: 16),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _cardNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Card Number',
                          hintText: 'XXXX XXXX XXXX XXXX',
                          prefixIcon: Icon(Icons.credit_card),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Please enter card number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _cardHolderController,
                        decoration: const InputDecoration(
                          labelText: 'Card Holder Name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Please enter card holder name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _expiryDateController,
                              decoration: const InputDecoration(
                                labelText: 'Expiry Date',
                                hintText: 'MM/YY',
                                prefixIcon: Icon(Icons.date_range),
                              ),
                              validator: (value) {
                                if (value?.isEmpty ?? true) {
                                  return 'Required';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _cvvController,
                              decoration: const InputDecoration(
                                labelText: 'CVV',
                                hintText: 'XXX',
                                prefixIcon: Icon(Icons.lock_outline),
                              ),
                              obscureText: true,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value?.isEmpty ?? true) {
                                  return 'Required';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ] else if (_selectedPaymentMethod == 'paypal') ...[
                CardLayout(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.account_balance_wallet,
                          color: AppColors.primaryBlue,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'You will be redirected to PayPal to complete your payment',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.body1,
                        ),
                        const SizedBox(height: 16),
                        Image.network(
                          'https://www.paypalobjects.com/webstatic/en_US/i/buttons/PP_logo_h_100x26.png',
                          height: 26,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 32),

              // Security Note
              const CardLayout(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.security, color: AppColors.success),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Secure Payment',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'All transactions are secure and encrypted',
                              style: AppTextStyles.body2,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Payment Button
              CustomButton(
                text: _isSaving ? 'Processing...' : 'Complete Payment',
                onPressed: _isSaving ? () {} : _processPayment,
                icon: _isSaving ? Icons.circle : null,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    super.dispose();
  }
}
