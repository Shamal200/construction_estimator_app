class QuotationSummary {
  const QuotationSummary({
    required this.directCost,
    required this.markup,
    required this.taxableSubtotal,
    required this.tax,
    required this.grandTotal,
  });

  final double directCost;
  final double markup;
  final double taxableSubtotal;
  final double tax;
  final double grandTotal;
}

class QuoteCalculations {
  static double calculateDirectCost({
    required double materialCost,
    required double labourCost,
    double quantity = 1,
  }) {
    return (materialCost + labourCost) * quantity;
  }

  static double calculateMarkupAmount({
    required double directCost,
    required double markupPercent,
  }) {
    return directCost * (markupPercent / 100);
  }

  static double calculateTaxableSubtotal({
    required double directCost,
    required double markupPercent,
    required double discount,
  }) {
    final markupAmount = calculateMarkupAmount(
      directCost: directCost,
      markupPercent: markupPercent,
    );

    return directCost + markupAmount - discount;
  }

  static double calculateTaxAmount({
    required double taxableSubtotal,
    required double taxPercent,
  }) {
    return taxableSubtotal * (taxPercent / 100);
  }

  static double calculateGrandTotal({
    required double taxableSubtotal,
    required double taxAmount,
  }) {
    return taxableSubtotal + taxAmount;
  }

  static QuotationSummary summarize({
    required double materialCost,
    required double labourCost,
    required double markupPercent,
    required double discount,
    required double taxPercent,
    double quantity = 1,
  }) {
    final directCost = calculateDirectCost(
      materialCost: materialCost,
      labourCost: labourCost,
      quantity: quantity,
    );

    final markup = calculateMarkupAmount(
      directCost: directCost,
      markupPercent: markupPercent,
    );

    final taxableSubtotal = calculateTaxableSubtotal(
      directCost: directCost,
      markupPercent: markupPercent,
      discount: discount,
    );

    final tax = calculateTaxAmount(
      taxableSubtotal: taxableSubtotal,
      taxPercent: taxPercent,
    );

    final grandTotal = calculateGrandTotal(
      taxableSubtotal: taxableSubtotal,
      taxAmount: tax,
    );

    return QuotationSummary(
      directCost: directCost,
      markup: markup,
      taxableSubtotal: taxableSubtotal,
      tax: tax,
      grandTotal: grandTotal,
    );
  }
}
