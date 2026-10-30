import 'package:flutter/material.dart';
import '../models.dart';
import 'feedback_sheet.dart';

/// Soru metni + şıklar. [reveal] true ise doğru/yanlış renkleri gösterilir.
class QuestionBody extends StatelessWidget {
  final Question q;
  final List<String> letters;
  final String? chosen;
  final bool reveal;
  final ValueChanged<String>? onPick;
  const QuestionBody({
    super.key,
    required this.q,
    required this.letters,
    this.chosen,
    this.reveal = false,
    this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(q.text, style: Theme.of(context).textTheme.titleMedium),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => FeedbackSheet.open(context, q),
            icon: const Icon(Icons.flag_outlined, size: 18),
            label: const Text('Hata bildir'),
          ),
        ),
        for (var i = 0; i < letters.length; i++) _opt(context, cs, i),
      ],
    );
  }

  Widget _opt(BuildContext context, ColorScheme cs, int i) {
    final l = letters[i];
    final label = String.fromCharCode(65 + i);
    Color? bg;
    Color border = cs.outlineVariant;
    if (reveal && l == q.answer) {
      bg = Colors.green.withValues(alpha: .18);
      border = Colors.green;
    } else if (reveal && l == chosen) {
      bg = Colors.red.withValues(alpha: .18);
      border = Colors.red;
    } else if (!reveal && l == chosen) {
      border = cs.primary;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: bg ?? cs.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: border, width: 1.5),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: (onPick == null || reveal || chosen != null) ? null : () => onPick!(l),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(radius: 14, child: Text(label, style: const TextStyle(fontSize: 13))),
                const SizedBox(width: 12),
                Expanded(child: Text(q.options[l] ?? '')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Cevaptan sonra yeni bilgi kazandıran bölüm: açıklama, Türkçe çeviri, kelimeler.
class LearnPanel extends StatefulWidget {
  final Question q;
  final List<String> letters;
  const LearnPanel({super.key, required this.q, required this.letters});
  @override
  State<LearnPanel> createState() => _LearnPanelState();
}

class _LearnPanelState extends State<LearnPanel> {
  bool tr = false;

  @override
  Widget build(BuildContext context) {
    final q = widget.q;
    final hasTr = q.textTr.isNotEmpty || q.vocab.isNotEmpty;
    final style = Theme.of(context).textTheme.bodyMedium;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          color: Theme.of(context).colorScheme.secondaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Doğru cevap: ${q.answer}) ${q.options[q.answer] ?? ''}',
              style: style?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        if (q.explanation.isNotEmpty)
          Card(child: Padding(padding: const EdgeInsets.all(12), child: Text(q.explanation, style: style))),
        if (hasTr)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => tr = !tr),
              icon: const Icon(Icons.translate),
              label: Text(tr ? 'Çeviriyi gizle' : 'Çevir'),
            ),
          ),
        if (hasTr && tr) ...[
          if (q.textTr.isNotEmpty)
            Card(child: Padding(padding: const EdgeInsets.all(12), child: Text(q.textTr, style: style))),
          if (q.optionsTr.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < widget.letters.length; i++)
                      if (q.optionsTr[widget.letters[i]] != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text('${String.fromCharCode(65 + i)}) ${q.optionsTr[widget.letters[i]]}',
                              style: style?.copyWith(
                                  fontWeight: widget.letters[i] == q.answer ? FontWeight.w700 : null)),
                        ),
                  ],
                ),
              ),
            ),
          if (q.vocab.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Kelimeler', style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 6),
                    for (final v in q.vocab)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(children: [
                          Expanded(flex: 4, child: Text(v.word, style: const TextStyle(fontWeight: FontWeight.w600))),
                          Expanded(flex: 5, child: Text(v.tr)),
                        ]),
                      ),
                  ],
                ),
              ),
            ),
          if (q.note.isNotEmpty)
            Card(child: Padding(padding: const EdgeInsets.all(12), child: Text(q.note, style: style))),
        ],
      ],
    );
  }
}
