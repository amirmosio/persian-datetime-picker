extension PersianDigit on String {
  String get e2p {
    List<String> p = ["۰","۱", "۲", "۳", "۴", "۵", "۶", "۷", "۸", "۹"];
    String res = this;
    for (int i = 0; i <= 9; i++) res = res.replaceAll(i.toString(), p[i]);
    return res;
  }
}
