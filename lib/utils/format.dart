/// Format harga dolar: 1234.5 -> $1,234.50
String money(double v) {
  final fixed = v.toStringAsFixed(2);
  final parts = fixed.split('.');
  final whole = parts[0];
  final buf = StringBuffer();
  for (var i = 0; i < whole.length; i++) {
    final left = whole.length - i;
    buf.write(whole[i]);
    if (left > 1 && left % 3 == 1) buf.write(',');
  }
  return '\$${buf.toString()}.${parts[1]}';
}
