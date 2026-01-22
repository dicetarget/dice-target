import 'package:flutter/material.dart';

class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

  Widget _h(BuildContext context, String t) => Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 6),
        child: Text(
          t,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final body = Theme.of(context).textTheme.bodyLarge;

    return Scaffold(
      appBar: AppBar(title: const Text('Rules')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: DefaultTextStyle(
              style: body ?? const TextStyle(fontSize: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _h(context, 'Ziel'),
                  const Text('Erreiche die Zielzahl exakt. Am Ende muss genau 1 Würfel übrig sein, der der Zielzahl entspricht.'),

                  _h(context, 'Setup'),
                  const Text('Du bekommst 5 Würfel (1–6) und eine Zielzahl:\nEasy: 1–50\nMedium: 1–100\nHard: 1–200'),

                  _h(context, 'Zug'),
                  const Text(
                    'Tippe 2 oder mehr Würfel an und wähle eine Operation (+ − × ÷).\n'
                    'Die ausgewählten Würfel verschmelzen zu einem neuen Würfel.\n'
                    'Dieser neue Würfel bleibt sichtbar und kann weiter kombiniert werden.',
                  ),

                  _h(context, 'Deterministische Berechnung'),
                  const Text(
                    'Die ausgewählten Werte werden absteigend sortiert (größte Zahl zuerst) und dann links-nach-rechts reduziert:\n'
                    '(((v1 op v2) op v3) op ...)',
                  ),

                  _h(context, 'Regeln für Operationen'),
                  const Text(
                    '+ und × sind immer erlaubt.\n'
                    '−: pro Schritt wird automatisch die Richtung gewählt, die kein negatives Ergebnis erzeugt.\n'
                    '÷: nur Ganzzahl-Division ohne Rest; pro Schritt wird automatisch die teilbare Richtung gewählt.\n'
                    'Wenn kein gültiger Schritt möglich ist, ist der Zug ungültig.',
                  ),

                  _h(context, 'Impossible'),
                  const Text(
                    'Impossible prüft den aktuellen Würfelzustand.\n'
                    'Wenn das Ziel nicht erreichbar ist: Gewinn.\n'
                    'Wenn es erreichbar ist: Niederlage und die Lösung wird angezeigt.',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
