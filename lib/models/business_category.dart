enum BusinessCategory {
  it('IT・通信'),
  finance('金融・保険'),
  manufacturing('製造'),
  retail('小売・流通'),
  service('サービス'),
  construction('建設・不動産'),
  medical('医療・福祉'),
  education('教育'),
  other('その他');

  final String displayName;
  const BusinessCategory(this.displayName);
}
