import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> calculateAgWindingUnbalance(String? ranStr, String? rbnStr, String? rcnStr) {
  final double? r = double.tryParse((ranStr ?? '').replaceAll(',', '.'));
  final double? s = double.tryParse((rbnStr ?? '').replaceAll(',', '.'));
  final double? t = double.tryParse((rcnStr ?? '').replaceAll(',', '.'));

  if (r == null || s == null || t == null) {
    return <String, dynamic>{'unbalance': null, 'status': 'Eksik', 'dominant_phase': null};
  }

  final double max = <double>[r, s, t].reduce((double a, double b) => a > b ? a : b);
  final double min = <double>[r, s, t].reduce((double a, double b) => a < b ? a : b);
  final double avg = (r + s + t) / 3.0;

  if (min == 0) return <String, dynamic>{'unbalance': 0.0, 'status': 'UYGUN', 'dominant_phase': null};

  final double unbalance = ((max - min) / min) * 100.0;
  final bool ok = unbalance <= 5.0;

  final double devR = (r - avg).abs();
  final double devS = (s - avg).abs();
  final double devT = (t - avg).abs();

  String? dominantPhase;
  if (devR > 1e-9 || devS > 1e-9 || devT > 1e-9) {
    if (devR >= devS && devR >= devT) {
      dominantPhase = 'RAN';
    } else if (devS >= devR && devS >= devT) {
      dominantPhase = 'RBN';
    } else {
      dominantPhase = 'RCN';
    }
  }

  return <String, dynamic>{
    'unbalance': unbalance,
    'status': ok ? 'UYGUN' : 'UYGUN DEĞİL',
    'dominant_phase': dominantPhase,
  };
}

void main() {
  group('AG Winding Unbalance Calculation Tests', () {
    test('returns Eksik when inputs are missing', () {
      expect(calculateAgWindingUnbalance(null, '10', '10')['status'], 'Eksik');
      expect(calculateAgWindingUnbalance('10', '', '10')['status'], 'Eksik');
    });

    test('returns UYGUN (0%) when all phases are equal', () {
      final res = calculateAgWindingUnbalance('10.5', '10.5', '10.5');
      expect(res['status'], 'UYGUN');
      expect(res['unbalance'], 0.0);
      expect(res['dominant_phase'], null);
    });

    test('returns UYGUN when unbalance <= 5%', () {
      final res = calculateAgWindingUnbalance('10.0', '10.4', '10.2');
      expect(res['status'], 'UYGUN');
      expect((res['unbalance'] as double).toStringAsFixed(2), '4.00');
      expect(res['dominant_phase'], 'RBN');
    });

    test('returns UYGUN DEĞİL when unbalance > 5%', () {
      final res = calculateAgWindingUnbalance('10.0', '11.0', '10.2');
      expect(res['status'], 'UYGUN DEĞİL');
      expect((res['unbalance'] as double).toStringAsFixed(2), '10.00');
      expect(res['dominant_phase'], 'RBN');
    });
  });
}
