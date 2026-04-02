class BankAccount {
  final String bankName;
  final String accountNumber;
  final String accountHolder;
  // final String accountType;

  BankAccount({
    required this.bankName,
    required this.accountNumber,
    required this.accountHolder,
    // required this.accountType,
  });

  factory BankAccount.fromMap(Map<String, dynamic> map) {
    return BankAccount(
      bankName: map['bank_name'] ?? '',
      accountNumber: map['account_number'] ?? '',
      accountHolder: map['account_holder'] ?? '',
      // accountType: map['account_type'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bank_name': bankName,
      'account_number': accountNumber,
      'account_holder': accountHolder,
      // 'account_type': accountType,
    };
  }

}