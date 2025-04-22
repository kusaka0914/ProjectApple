enum AccountType {
  personal,
  business;

  String get displayName {
    switch (this) {
      case AccountType.personal:
        return '個人アカウント';
      case AccountType.business:
        return '企業アカウント';
    }
  }
}
