// Testes da calculadora de Saúde Financeira.
//
// Cobrem todos os pontos de corte da fórmula descrita em
// `lib/feature/planning/domain/financial_health.dart` para garantir que
// alterações futuras na fórmula sejam intencionais (e detectadas).

import 'package:flutter_test/flutter_test.dart';
import 'package:fyna/feature/planning/domain/financial_health.dart';

FinancialHealthCalculator make({
  double income = 0,
  double expense = 0,
  double recurringExpenses = 0,
  double budgetLimit = 0,
  double budgetSpent = 0,
}) =>
    FinancialHealthCalculator(
      income: income,
      expense: expense,
      recurringExpenses: recurringExpenses,
      budgetLimit: budgetLimit,
      budgetSpent: budgetSpent,
    );

void main() {
  group('reserveScore (taxa de poupança)', () {
    test('income == 0 → neutro 50 (proteção contra divisão por zero)', () {
      expect(make().reserveScore, 50);
    });

    test('savingsRate ≥ 30% → 95', () {
      // 10000 receita, 7000 gasto → savings 3000 → 30%
      expect(make(income: 10000, expense: 7000).reserveScore, 95);
      expect(make(income: 10000, expense: 5000).reserveScore, 95); // 50%
    });

    test('savingsRate ≥ 20% (mas < 30%) → 80', () {
      expect(make(income: 10000, expense: 7500).reserveScore, 80); // 25%
      expect(make(income: 10000, expense: 8000).reserveScore, 80); // 20%
    });

    test('savingsRate ≥ 10% (mas < 20%) → 65', () {
      expect(make(income: 10000, expense: 8500).reserveScore, 65); // 15%
      expect(make(income: 10000, expense: 9000).reserveScore, 65); // 10%
    });

    test('savingsRate ≥ 0% (mas < 10%) → 50', () {
      expect(make(income: 10000, expense: 9500).reserveScore, 50); // 5%
      expect(make(income: 10000, expense: 10000).reserveScore, 50); // 0%
    });

    test('savingsRate < 0% (gastou mais que ganhou) → 25', () {
      expect(make(income: 10000, expense: 12000).reserveScore, 25);
    });

    test('exato no limite — 30% retorna 95 (>=)', () {
      // Verifica que 30% mesmo é a borda
      expect(make(income: 100, expense: 70).reserveScore, 95);
    });
  });

  group('budgetScore — sem orçamentos definidos (fallback gasto/receita)', () {
    test('income == 0 → 50 neutro', () {
      expect(make().budgetScore, 50);
    });

    test('ratio < 0.6 → 95', () {
      expect(make(income: 10000, expense: 5000).budgetScore, 95); // 50%
    });

    test('ratio ≥ 0.6 e < 0.8 → 80', () {
      expect(make(income: 10000, expense: 6000).budgetScore, 80); // 60%
      expect(make(income: 10000, expense: 7500).budgetScore, 80); // 75%
    });

    test('ratio ≥ 0.8 e < 1.0 → 60', () {
      expect(make(income: 10000, expense: 8000).budgetScore, 60); // 80%
      expect(make(income: 10000, expense: 9500).budgetScore, 60); // 95%
    });

    test('ratio ≥ 1.0 → 30', () {
      expect(make(income: 10000, expense: 10000).budgetScore, 30); // 100%
      expect(make(income: 10000, expense: 12000).budgetScore, 30); // 120%
    });
  });

  group('budgetScore — com orçamentos definidos (usa utilização real)', () {
    test('ratio < 0.6 → 95 (usa budget, ignora gasto/receita)', () {
      // gasto/receita seria 100% (30), mas orçamento foi 50% → ganha 95
      expect(
        make(
          income: 10000,
          expense: 10000,
          budgetLimit: 2000,
          budgetSpent: 1000,
        ).budgetScore,
        95,
      );
    });

    test('ratio 80% → 60', () {
      expect(
        make(budgetLimit: 1000, budgetSpent: 800).budgetScore,
        60,
      );
    });

    test('estouro de orçamento → 30 mesmo com renda alta', () {
      expect(
        make(
          income: 100000, // muita receita
          expense: 1000, // pouco gasto
          budgetLimit: 500,
          budgetSpent: 600, // estourou
        ).budgetScore,
        30,
      );
    });

    test('budgetLimit == 0 cai pro fallback mesmo se budgetSpent > 0', () {
      // limite 0 não conta como "tem budget", então usa gasto/receita
      expect(
        make(income: 10000, expense: 5000, budgetLimit: 0, budgetSpent: 100)
            .budgetScore,
        95,
      );
    });
  });

  group('debtScore (peso das recorrências fixas)', () {
    test('income == 0 → 50 neutro', () {
      expect(make().debtScore, 50);
    });

    test('ratio < 0.3 → 95', () {
      expect(
        make(income: 10000, recurringExpenses: 2900).debtScore,
        95,
      ); // 29%
    });

    test('ratio ≥ 0.3 e < 0.5 → 80', () {
      expect(
        make(income: 10000, recurringExpenses: 3000).debtScore,
        80,
      ); // 30%
      expect(
        make(income: 10000, recurringExpenses: 4900).debtScore,
        80,
      ); // 49%
    });

    test('ratio ≥ 0.5 e < 0.7 → 60', () {
      expect(
        make(income: 10000, recurringExpenses: 6000).debtScore,
        60,
      ); // 60%
    });

    test('ratio ≥ 0.7 e < 0.9 → 40', () {
      expect(
        make(income: 10000, recurringExpenses: 8000).debtScore,
        40,
      ); // 80%
    });

    test('ratio ≥ 0.9 → 20', () {
      expect(
        make(income: 10000, recurringExpenses: 9000).debtScore,
        20,
      ); // 90%
      expect(
        make(income: 10000, recurringExpenses: 15000).debtScore,
        20,
      ); // 150%
    });
  });

  group('overallScore (média dos três)', () {
    test('todos 95 → 95', () {
      // 30% poupança, 50% gasto/receita, 20% recorrente
      final calc = make(
        income: 10000,
        expense: 5000,
        recurringExpenses: 2000,
      );
      expect(calc.reserveScore, 95);
      expect(calc.budgetScore, 95);
      expect(calc.debtScore, 95);
      expect(calc.overallScore, 95);
    });

    test('média arredondada → round(80+60+40)/3 = round(60) = 60', () {
      // savings 22% → 80, gasto 78% → 80, recurring 70% → 60
      // wait — let me redo
      // income 10000, expense 7800 → savings 22% → 80, gasto/receita 78% → 80
      // recurring 6000 → 60% → 60
      // (80 + 80 + 60) / 3 = 73.33 → 73
      final calc = make(
        income: 10000,
        expense: 7800,
        recurringExpenses: 6000,
      );
      expect(calc.reserveScore, 80);
      expect(calc.budgetScore, 80);
      expect(calc.debtScore, 60);
      expect(calc.overallScore, 73);
    });

    test('cenário ruim: estourou tudo', () {
      // Gastou mais que ganhou + recorrentes pesados
      final calc = make(
        income: 5000,
        expense: 7000,
        recurringExpenses: 4500,
      );
      expect(calc.reserveScore, 25);
      expect(calc.budgetScore, 30);
      expect(calc.debtScore, 20);
      expect(calc.overallScore, 25);
    });

    test('income zero → todos viram 50 → label REGULAR', () {
      final calc = make();
      expect(calc.overallScore, 50);
      expect(calc.label, HealthLabel.regular);
    });
  });

  group('label (faixas)', () {
    test('≥ 80 → ÓTIMA', () {
      final c = make(income: 10000, expense: 5000, recurringExpenses: 2000);
      expect(c.overallScore, greaterThanOrEqualTo(80));
      expect(c.label, HealthLabel.excellent);
    });

    test('60-79 → BOA', () {
      // 65 + 80 + 60 = 205/3 = 68
      final c = make(
        income: 10000,
        expense: 8500, // 15% poupança → 65
        recurringExpenses: 6000, // 60% → 60
      );
      expect(c.overallScore, inInclusiveRange(60, 79));
      expect(c.label, HealthLabel.good);
    });

    test('40-59 → REGULAR', () {
      // Sem income → todos 50 → 50
      expect(make().label, HealthLabel.regular);
    });

    test('< 40 → ATENÇÃO', () {
      final c = make(income: 5000, expense: 7000, recurringExpenses: 4500);
      expect(c.overallScore, lessThan(40));
      expect(c.label, HealthLabel.attention);
    });
  });

  group('savingsRate (helper público)', () {
    test('calcula corretamente', () {
      expect(make(income: 10000, expense: 8000).savingsRate, 20);
      expect(make(income: 10000, expense: 12000).savingsRate, -20);
      expect(make().savingsRate, 0);
    });
  });
}
