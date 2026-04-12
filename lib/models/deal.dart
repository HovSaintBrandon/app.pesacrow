class Deal {
  final String transactionId;
  final String sellerPhone;
  final String? buyerPhone;
  final int amount;
  final String description;
  final String status;
  final String createdAt;
  final List<String> proofs;
  // Lifecycle timestamps (nullable — backend may not return all of them yet)
  final String? paymentConfirmedAt;
  final String? deliveredAt;
  final String? approvedAt;
  final String? disbursementStatus;
  final Map<String, dynamic>? feeBreakdownData;

  Deal({
    required this.transactionId,
    required this.sellerPhone,
    this.buyerPhone,
    required this.amount,
    required this.description,
    required this.status,
    required this.createdAt,
    this.proofs = const [],
    this.paymentConfirmedAt,
    this.deliveredAt,
    this.approvedAt,
    this.disbursementStatus,
    this.feeBreakdownData,
  });

  factory Deal.fromJson(Map<String, dynamic> json) => Deal(
        transactionId: json['transactionId'] ?? '',
        sellerPhone: json['sellerPhone'] ?? '',
        buyerPhone: json['buyerPhone'],
        amount: (json['amount'] ?? 0) is int
            ? json['amount']
            : (json['amount'] as num).toInt(),
        description: json['description'] ?? '',
        status: json['status'] ?? '',
        createdAt: json['createdAt'] ?? '',
        proofs: (json['proofs'] as List?)?.map((e) => e.toString()).toList() ?? [],
        paymentConfirmedAt: json['paymentConfirmedAt'],
        deliveredAt: json['deliveredAt'],
        approvedAt: json['approvedAt'],
        disbursementStatus: json['disbursementStatus'],
        feeBreakdownData: json['feeBreakdown'],
      );
}
