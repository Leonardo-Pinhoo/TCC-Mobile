import 'package:rfid_live/core/utils/formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final DateTime reference = DateTime(2026, 9, 15, 15, 36, 24);

  group('timeAgo', () {
    test('usa o texto da tela para leituras recentes', () {
      expect(Fmt.timeAgo(reference, reference: reference), 'agora');
      expect(
        Fmt.timeAgo(reference.subtract(const Duration(minutes: 2)),
            reference: reference),
        '2 min atrás',
      );
      expect(
        Fmt.timeAgo(reference.subtract(const Duration(hours: 6)),
            reference: reference),
        '6 h atrás',
      );
      expect(
        Fmt.timeAgo(reference.subtract(const Duration(days: 3)),
            reference: reference),
        '3 d atrás',
      );
    });

    test('datas futuras não geram valores negativos', () {
      expect(
        Fmt.timeAgo(reference.add(const Duration(minutes: 5)),
            reference: reference),
        'agora',
      );
    });
  });

  test('clock e isoDate seguem o formato das telas', () {
    expect(Fmt.clock(reference), '15:36:24');
    expect(Fmt.isoDate(reference), '2026-09-15');
    expect(Fmt.hhmm(reference), '15:36');
  });

  test('duration converte minutos em horas legíveis', () {
    expect(Fmt.duration(45), '45min');
    expect(Fmt.duration(60), '1h');
    expect(Fmt.duration(96), '1h 36min');
  });

  test('percent arredonda conforme a casa pedida', () {
    expect(Fmt.percent(0.3333), '33%');
    expect(Fmt.percent(0.8333, decimals: 1), '83.3%');
  });

  test('dayLabel identifica hoje e ontem', () {
    expect(Fmt.dayLabel(reference, reference: reference), 'Hoje');
    expect(
      Fmt.dayLabel(reference.subtract(const Duration(days: 1)),
          reference: reference),
      'Ontem',
    );
    expect(
      Fmt.dayLabel(reference.subtract(const Duration(days: 5)),
          reference: reference),
      '2026-09-10',
    );
  });

  test('currency usa o padrão brasileiro', () {
    final String formatted = Fmt.currency(2450);
    expect(formatted, contains('R\$'));
    expect(formatted, contains('2.450,00'));
  });
}
