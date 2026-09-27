class SettingsModel {
  final String siteName;
  final String supportEmail;
  final String supportPhone;
  final double deliveryBaseFee;
  final double taxPercentage;
  final bool cashPaymentEnabled;
  final bool cardPaymentEnabled;

  SettingsModel({
    required this.siteName,
    required this.supportEmail,
    required this.supportPhone,
    required this.deliveryBaseFee,
    required this.taxPercentage,
    required this.cashPaymentEnabled,
    required this.cardPaymentEnabled,
  });

  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    return SettingsModel(
      siteName: json['site_name'] ?? 'سوق جو - SouqJo',
      supportEmail: json['support_email'] ?? 'support@souqjo.com',
      supportPhone: json['support_phone'] ?? '+962790000000',
      deliveryBaseFee:
          double.tryParse(json['delivery_base_fee']?.toString() ?? '1.5') ??
          1.5,
      taxPercentage:
          double.tryParse(json['tax_percentage']?.toString() ?? '16.0') ?? 16.0,
      cashPaymentEnabled: json['cash_payment_enabled'] ?? true,
      cardPaymentEnabled: json['card_payment_enabled'] ?? true,
    );
  }
}
