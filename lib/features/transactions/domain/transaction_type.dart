enum TransactionType {
  sale,
  expense;

  String get label => switch (this) {
        TransactionType.sale => 'Vente',
        TransactionType.expense => 'Dépense',
      };

  String get storageValue => switch (this) {
        TransactionType.sale => 'vente',
        TransactionType.expense => 'depense',
      };

  static TransactionType fromStorageValue(String value) {
    return switch (value) {
      'vente' => TransactionType.sale,
      'depense' => TransactionType.expense,
      _ => TransactionType.expense,
    };
  }
}
