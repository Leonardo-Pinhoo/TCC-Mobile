import 'package:intl/intl.dart';

/// Formatações de data, hora e moeda no padrão brasileiro.
class Fmt {
  const Fmt._();

  static final DateFormat _clock = DateFormat('HH:mm:ss');
  static final DateFormat _hhmm = DateFormat('HH:mm');
  static final DateFormat _isoDate = DateFormat('yyyy-MM-dd');
  static final DateFormat _dayMonth = DateFormat('dd/MM');
  static final DateFormat _full = DateFormat('dd/MM/yyyy HH:mm');
  static final NumberFormat _currency =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$', decimalDigits: 2);
  static final NumberFormat _compactCurrency =
      NumberFormat.compactCurrency(locale: 'pt_BR', symbol: 'R\$', decimalDigits: 1);

  static String clock(DateTime value) => _clock.format(value);
  static String hhmm(DateTime value) => _hhmm.format(value);
  static String isoDate(DateTime value) => _isoDate.format(value);
  static String dayMonth(DateTime value) => _dayMonth.format(value);
  static String full(DateTime value) => _full.format(value);
  static String currency(double value) => _currency.format(value);
  static String compactCurrency(double value) => _compactCurrency.format(value);

  static String percent(double ratio, {int decimals = 0}) =>
      '${(ratio * 100).toStringAsFixed(decimals)}%';

  /// "agora", "2 min atrás", "1 h atrás", "3 d atrás".
  static String timeAgo(DateTime value, {DateTime? reference}) {
    final Duration diff = (reference ?? DateTime.now()).difference(value);
    // O corte é em minutos inteiros para casar com a unidade da faixa
    // seguinte: cortar em segundos deixava 30s–59s cair aqui como
    // "0 min atrás".
    if (diff.isNegative || diff.inMinutes < 1) return 'agora';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min atrás';
    if (diff.inHours < 24) return '${diff.inHours} h atrás';
    if (diff.inDays < 30) return '${diff.inDays} d atrás';
    return isoDate(value);
  }

  /// Duração em minutos apresentada como "1h 36min".
  static String duration(int minutes) {
    if (minutes < 60) return '${minutes}min';
    final int hours = minutes ~/ 60;
    final int rest = minutes % 60;
    return rest == 0 ? '${hours}h' : '${hours}h ${rest}min';
  }

  /// Rótulo do dia relativo à data atual.
  static String dayLabel(DateTime value, {DateTime? reference}) {
    final DateTime now = reference ?? DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime target = DateTime(value.year, value.month, value.day);
    final int diff = today.difference(target).inDays;
    if (diff == 0) return 'Hoje';
    if (diff == 1) return 'Ontem';
    return _isoDate.format(value);
  }
}
