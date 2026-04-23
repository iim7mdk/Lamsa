class BankAccount {
  final String id;
  final String bankName;
  final int accountNumber;
  final String accountHolder;

  BankAccount({
    required this.id,
    required this.bankName,
    required this.accountNumber,
    required this.accountHolder,
  });

  factory BankAccount.fromMap(String id, Map<String, dynamic> map) {
    final rawAccountNumber = map['accountNumber'];

    return BankAccount(
      id: id,
      bankName: map['bankName'] ?? '',
      accountNumber: rawAccountNumber is int
          ? rawAccountNumber
          : int.tryParse(rawAccountNumber?.toString() ?? '') ?? 0,
      accountHolder: map['accountHolder'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bankName': bankName,
      'accountNumber': accountNumber,
      'accountHolder': accountHolder,
    };
  }
}