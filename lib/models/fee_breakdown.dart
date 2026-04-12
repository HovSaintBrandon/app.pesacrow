class FeeBreakdown {
  final double dealAmount;
  final double transactionFee;   // Paid by Buyer
  final double releaseFee;       // Paid by Seller
  final double inactivityFee;    // Potential future applied fee
  final double holdingFee;       // If applicable
  final double totalBuyerPays;
  final double netToSeller;
  final double platformGross;
  final double? bouquetCharge;    // Safaricom Business Bouquet Charge
  final double? bouquetRevenueShare; // PesaCrow share of the bouquet charge
  final String? tierApplied;     // e.g., "High Value Tier"
  final String? warning;         // e.g., "Inactivity fee applies after 7 days"

  FeeBreakdown({
    required this.dealAmount,
    required this.transactionFee,
    required this.releaseFee,
    this.inactivityFee = 0.0,
    this.holdingFee = 0.0,
    required this.totalBuyerPays,
    required this.netToSeller,
    required this.platformGross,
    this.bouquetCharge = 0.0,
    this.bouquetRevenueShare,
    this.tierApplied,
    this.warning,
  });

  factory FeeBreakdown.fromJson(Map<String, dynamic> json) {
    final breakdown = json['breakdown'] as Map<String, dynamic>?;
    
    return FeeBreakdown(
      dealAmount: (json['amount'] ?? json['dealAmount'] ?? 0.0).toDouble(),
      transactionFee: (breakdown?['transactionFee'] ?? json['transactionFee'] ?? 0.0).toDouble(),
      releaseFee: (breakdown?['releaseFee'] ?? json['releaseFee'] ?? 0.0).toDouble(),
      inactivityFee: (json['inactivityFee'] ?? 0.0).toDouble(),
      holdingFee: (json['holdingFee'] ?? 0.0).toDouble(),
      totalBuyerPays: (json['buyerTotal'] ?? json['totalBuyerPays'] ?? 0.0).toDouble(),
      netToSeller: (json['sellerNet'] ?? json['netToSeller'] ?? 0.0).toDouble(),
      platformGross: (json['platformGross'] ?? 0.0).toDouble(),
      bouquetCharge: (breakdown?['bouquetCharge'] ?? 0.0).toDouble(),
      bouquetRevenueShare: (json['bouquetRevenueShare'] ?? breakdown?['bouquetRevenueShare'])?.toDouble(),
      tierApplied: json['tierApplied'],
      warning: json['warning'],
    );
  }

  Map<String, dynamic> toJson() => {
    'dealAmount': dealAmount,
    'transactionFee': transactionFee,
    'releaseFee': releaseFee,
    'inactivityFee': inactivityFee,
    'holdingFee': holdingFee,
    'bouquetCharge': bouquetCharge,
    'bouquetRevenueShare': bouquetRevenueShare,
    'totalBuyerPays': totalBuyerPays,
    'netToSeller': netToSeller,
    'platformGross': platformGross,
    'tierApplied': tierApplied,
    'warning': warning,
  };
}
