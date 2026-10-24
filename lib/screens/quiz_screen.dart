/// Quiz built only from real catalogue data. Silhouettes are used only for
/// art confirmed to be a transparent cut-out; everything else is a normal
/// question where the picture never gives away the answer.
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../ads/ads.dart';
import '../models/unit.dart';
import '../state/catalog_store.dart';
import '../state/engagement_store.dart';
import '../theme.dart';
import '../widgets/common.dart';

class QuizQuestion {
  QuizQuestion({
    required this.prompt,
    required this.options,
    required this.answer,
    this.imageUrl,
    this.silhouette = false,
  });
  final String prompt;
  final List<String> options;
  final String answer;
  final String? imageUrl;
  final bool silhouette;
}

class QuizBuilder {
  QuizBuilder(this.cat, [Random? rng]) : rng = rng ?? Random();
  final CatalogStore cat;
  final Random rng;

  List<String> _options(String answer, Iterable<String> pool) {
    final others = pool.where((n) => n != answer).toSet().toList()..shuffle(rng);
    return ([answer, ...others.take(3)])..shuffle(rng);
  }

  QuizQuestion? _silhouette() {
    final pool = [
      for (final k in [UnitKind.hero, UnitKind.pet, UnitKind.equipment])
        ...cat.units(k).where((u) => u.imageUrl != null && cat.silhouetteKeys.contains(u.key)),
    ];
    if (pool.length < 4) return null;
    final u = pool[rng.nextInt(pool.length)];
    final names = cat.units(u.kind).map((e) => e.name);
    if (names.toSet().length < 4) return null;
    return QuizQuestion(
      prompt: 'Who or what is this?',
      options: _options(u.name, names),
      answer: u.name,
      imageUrl: u.imageUrl,
      silhouette: true,
    );
  }

  QuizQuestion? _equipmentHero() {
    final eq = cat.units(UnitKind.equipment).where((u) => u.hero != null).toList();
    final heroes = eq.map((e) => e.hero!).toSet();
    if (eq.isEmpty || heroes.length < 4) return null;
    final u = eq[rng.nextInt(eq.length)];
    return QuizQuestion(
      prompt: 'Which hero wears the ${u.name}?',
      options: _options(u.hero!, heroes),
      answer: u.hero!,
      imageUrl: u.imageUrl,
    );
  }

  QuizQuestion? _housing() {
    final troops = cat
        .units(UnitKind.troop)
        .where((u) => !u.isBuilderBase && (u.housingSpace ?? 0) > 0)
        .toList();
    final spaces = troops.map((u) => '${u.housingSpace}').toSet();
    if (troops.isEmpty || spaces.length < 4) return null;
    final u = troops[rng.nextInt(troops.length)];
    return QuizQuestion(
      prompt: 'How much housing space does one ${u.name} take?',
      options: _options('${u.housingSpace}', spaces),
      answer: '${u.housingSpace}',
      imageUrl: u.imageUrl,
    );
  }

  QuizQuestion? _unlockTh() {
    final units = [
      ...cat.units(UnitKind.troop).where((u) => !u.isBuilderBase && !u.isSeasonal),
      ...cat.units(UnitKind.spell),
    ].where((u) => u.unlockTownhall != null).toList();
    final ths = units.map((u) => 'Town Hall ${u.unlockTownhall}').toSet();
    if (units.isEmpty || ths.length < 4) return null;
    final u = units[rng.nextInt(units.length)];
    final a = 'Town Hall ${u.unlockTownhall}';
    return QuizQuestion(
      prompt: 'At which Town Hall level does ${u.name} unlock?',
      options: _options(a, ths),
      answer: a,
      imageUrl: u.imageUrl,
    );
  }

  QuizQuestion? _flying() {
    final troops = cat.units(UnitKind.troop).where((u) => !u.isBuilderBase).toList();
    final fliers = troops.where((u) => u.isFlying).toList();
    final walkers = troops.where((u) => !u.isFlying).map((u) => u.name).toSet().toList();
    if (fliers.isEmpty || walkers.length < 3) return null;
    final u = fliers[rng.nextInt(fliers.length)];
    walkers.shuffle(rng);
    return QuizQuestion(
      prompt: 'Which of these troops flies?',
      options: ([u.name, ...walkers.take(3)])..shuffle(rng),
      answer: u.name,
    );
  }

  List<QuizQuestion> round(int count) {
    final makers = [_silhouette, _silhouette, _equipmentHero, _housing, _unlockTh, _flying];
    final out = <QuizQuestion>[];
    var guard = 0;
    while (out.length < count && guard++ < count * 20) {
      final q = makers[rng.nextInt(makers.length)]();
      if (q != null && !out.any((o) => o.prompt == q.prompt && o.answer == q.answer)) out.add(q);
    }
    return out;
  }
}

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, this.daily = false});

  /// Daily challenge: 5 questions, the same for everyone on a given day,
  /// playable once per day, feeds the streak.
  final bool daily;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  static const _roundSize = 10;
  static const _dailySize = 5;
  static const _bestKey = 'quiz_best';

  List<QuizQuestion> _questions = const [];
  int _index = 0;
  int _score = 0;
  String? _picked;
  int _best = 0;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      if (mounted) setState(() => _best = p.getInt(_bestKey) ?? 0);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _newRound());
  }

  void _newRound() {
    final cat = context.read<CatalogStore>();
    if (!cat.isReady) {
      // The catalogue may already be loading; wait for it to finish rather
      // than relying on load() (which returns early while busy).
      void onChange() {
        if (!cat.isReady && cat.error == null) return;
        cat.removeListener(onChange);
        if (mounted && cat.isReady) _newRound();
      }

      cat.addListener(onChange);
      cat.load();
      return;
    }
    if (widget.daily && context.read<EngagementStore>().playedToday) {
      setState(() => _finished = true);
      return;
    }
    setState(() {
      _questions = widget.daily
          ? QuizBuilder(cat, Random(daySeed())).round(_dailySize)
          : QuizBuilder(cat).round(_roundSize);
      _index = 0;
      _score = 0;
      _picked = null;
      _finished = false;
    });
  }

  Future<void> _pick(String option) async {
    if (_picked != null) return;
    final q = _questions[_index];
    setState(() {
      _picked = option;
      if (option == q.answer) _score++;
    });
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;
    if (_index + 1 < _questions.length) {
      setState(() {
        _index++;
        _picked = null;
      });
    } else {
      setState(() => _finished = true);
      if (widget.daily) context.read<EngagementStore>().completeDaily(_score);
      if (!widget.daily && _score > _best) {
        _best = _score;
        (await SharedPreferences.getInstance()).setInt(_bestKey, _score);
      }
      // End of a round is the only place an interstitial may appear.
      Ads.onQuizRoundEnd();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cat = context.watch<CatalogStore>();
    return Scaffold(
      appBar: AppBar(title: Text(widget.daily ? 'Daily challenge' : 'Quiz')),
      body: SafeArea(child: _body(cat)),
    );
  }

  Widget _body(CatalogStore cat) {
    if (!cat.isReady) {
      return cat.error != null
          ? MessageView.error('The quiz needs the unit catalogue.', () => cat.load(force: true))
          : const LoadingView(label: 'Preparing questions…');
    }
    if (_finished && widget.daily) return _dailyResults();
    if (_questions.isEmpty) {
      return MessageView(
        icon: Icons.quiz_outlined,
        title: 'Not enough data',
        message: 'There is not enough data for a full quiz right now.',
        actionLabel: 'Try again',
        onAction: _newRound,
      );
    }
    if (_finished) return _results();
    final q = _questions[_index];
    final t = Theme.of(context).textTheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Text('Question ${_index + 1} of ${_questions.length}', style: t.bodyMedium),
                const Spacer(),
                Text('Score $_score',
                    style: const TextStyle(fontFamily: displayFont, fontSize: 18, color: Palette.gold)),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (_index + (_picked == null ? 0 : 1)) / _questions.length,
                minHeight: 6,
                backgroundColor: Palette.stone,
                color: Palette.gold,
              ),
            ),
            const SizedBox(height: 20),
            if (q.imageUrl != null) _QuestionArt(question: q, revealed: _picked != null),
            const SizedBox(height: 18),
            Text(q.prompt, style: t.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: 18),
            for (final o in q.options)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _OptionButton(
                  label: o,
                  state: _picked == null
                      ? _OptState.idle
                      : o == q.answer
                          ? _OptState.correct
                          : o == _picked
                              ? _OptState.wrong
                              : _OptState.dim,
                  onTap: () => _pick(o),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _dailyResults() {
    final e = context.watch<EngagementStore>();
    final t = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_fire_department_rounded, size: 64, color: Palette.gold),
            const SizedBox(height: 12),
            Text('${e.liveStreak}-day streak', style: t.headlineSmall),
            const SizedBox(height: 8),
            Text('Today: ${e.lastDailyScore} / $_dailySize',
                style: t.displaySmall?.copyWith(color: Palette.gold, fontSize: 40)),
            const SizedBox(height: 6),
            Text('Best streak: ${e.bestStreak} days. A new challenge unlocks at midnight.',
                style: t.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 22),
            FilledButton(
              onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const QuizScreen())),
              child: const Text('Play a free round'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _results() {
    final t = Theme.of(context).textTheme;
    final perfect = _score == _questions.length;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(perfect ? Icons.emoji_events_rounded : Icons.flag_circle_rounded,
                size: 64, color: Palette.gold),
            const SizedBox(height: 12),
            Text(perfect ? 'Flawless victory!' : 'Round complete', style: t.headlineSmall),
            const SizedBox(height: 8),
            Text('$_score / ${_questions.length}',
                style: t.displaySmall?.copyWith(color: Palette.gold, fontSize: 52)),
            const SizedBox(height: 6),
            Text('Best score: $_best', style: t.bodyMedium),
            const SizedBox(height: 22),
            FilledButton(onPressed: _newRound, child: const Text('Play again')),
          ],
        ),
      ),
    );
  }
}

class _QuestionArt extends StatelessWidget {
  const _QuestionArt({required this.question, required this.revealed});
  final QuizQuestion question;
  final bool revealed;

  @override
  Widget build(BuildContext context) {
    Widget art = ArtImage(question.imageUrl);
    if (question.silhouette && !revealed) {
      art = ColorFiltered(
        colorFilter: const ColorFilter.mode(Color(0xFF0B0F1A), BlendMode.srcIn),
        child: art,
      );
    }
    return Container(
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: glowDecoration(question.silhouette ? Palette.elixir : Palette.gold, radius: 24),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: KeyedSubtree(key: ValueKey(revealed), child: art),
      ),
    );
  }
}

enum _OptState { idle, correct, wrong, dim }

class _OptionButton extends StatelessWidget {
  const _OptionButton({required this.label, required this.state, required this.onTap});
  final String label;
  final _OptState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (bg, border, fg) = switch (state) {
      _OptState.idle => (Palette.stone, Palette.line, Palette.ink),
      _OptState.correct => (Palette.grass.withValues(alpha: 0.22), Palette.grass, Palette.ink),
      _OptState.wrong => (Palette.ember.withValues(alpha: 0.22), Palette.ember, Palette.ink),
      _OptState.dim => (Palette.stone, Palette.line, Palette.inkFaint),
    };
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: state == _OptState.idle ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border, width: 1.4),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(label,
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5, color: fg)),
              ),
              if (state == _OptState.correct) const Icon(Icons.check_circle_rounded, color: Palette.grass),
              if (state == _OptState.wrong) const Icon(Icons.cancel_rounded, color: Palette.ember),
            ],
          ),
        ),
      ),
    );
  }
}
