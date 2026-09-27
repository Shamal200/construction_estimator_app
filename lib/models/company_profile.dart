class CompanyProfile {
  const CompanyProfile({
    required this.id,
    required this.companyName,
    this.logoUrl = '',
    this.address = '',
    this.phone = '',
    this.email = '',
    this.website = '',
    this.taxRegistration = '',
    this.bankDetails = '',
    this.defaultQuotationTerms = '',
    this.defaultInvoiceTerms = '',
  });

  final String id;
  final String companyName;
  final String logoUrl;
  final String address;
  final String phone;
  final String email;
  final String website;
  final String taxRegistration;
  final String bankDetails;
  final String defaultQuotationTerms;
  final String defaultInvoiceTerms;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyName': companyName,
      'logoUrl': logoUrl,
      'address': address,
      'phone': phone,
      'email': email,
      'website': website,
      'taxRegistration': taxRegistration,
      'bankDetails': bankDetails,
      'defaultQuotationTerms': defaultQuotationTerms,
      'defaultInvoiceTerms': defaultInvoiceTerms,
    };
  }

  factory CompanyProfile.fromMap(Map<String, dynamic> map) {
    return CompanyProfile(
      id: map['id'] as String? ?? '',
      companyName: map['companyName'] as String? ?? '',
      logoUrl: map['logoUrl'] as String? ?? '',
      address: map['address'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      email: map['email'] as String? ?? '',
      website: map['website'] as String? ?? '',
      taxRegistration: map['taxRegistration'] as String? ?? '',
      bankDetails: map['bankDetails'] as String? ?? '',
      defaultQuotationTerms: map['defaultQuotationTerms'] as String? ?? '',
      defaultInvoiceTerms: map['defaultInvoiceTerms'] as String? ?? '',
    );
  }
}
