import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/ranking_provider.dart';
import '../../data/animals_data.dart';
import '../../data/repositories/game_record_repository.dart';
import '../../domain/ranking/ranking_repository.dart';
import '../../domain/ranking/week_id.dart';
import '../widgets/game_background.dart';
import '../widgets/outlined_text.dart';
import '../controllers/auth_controller.dart';
import '../../core/theme/text_styles.dart';
import 'onboarding_auth_screen.dart';

// One-shot load — avoids Firestore stream restart loop on transient errors.
// Global ranking doesn't need real-time updates while the user is viewing it.
final _globalRankingProvider =
    FutureProvider.autoDispose<List<RankingEntry>>((ref) {
      final repo = ref.watch(rankingRepositoryProvider);
      return repo.getWeeklyTop(RankingType.globalTime);
    });

class RankingScreen extends ConsumerWidget {
  const RankingScreen({super.key, this.initialTab = 0});
  final int initialTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GameBackground(
      child: DefaultTabController(
        length: 3,
        initialIndex: initialTab,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(
              'Ranking',
              style: GoogleFonts.fredoka(fontSize: 22, color: Colors.white),
            ),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            bottom: TabBar(
              labelStyle: GoogleFonts.fredoka(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: GoogleFonts.fredoka(fontSize: 14),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              tabs: const [
                Tab(text: 'Pessoal'),
                Tab(text: 'Global'),
                Tab(text: 'Lendas'),
              ],
            ),
          ),
          body: const TabBarView(
            children: [
              _PersonalRankingTab(),
              _GlobalRankingTab(),
              _LegendsRankingTab(),
            ],
          ),
        ),
      ),
    );
  }
}

class _PersonalRankingTab extends ConsumerWidget {
  const _PersonalRankingTab();

  String _formatMs(int ms) {
    final s = ms ~/ 1000;
    final m = s ~/ 60;
    final rem = s % 60;
    return '${m.toString().padLeft(2, '0')}:${rem.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(gameRecordRepositoryProvider);
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          ColoredBox(
            color: AppColors.primary,
            child: TabBar(
              labelStyle: GoogleFonts.fredoka(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: GoogleFonts.fredoka(fontSize: 14),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              tabs: const [
                Tab(text: 'Por Tempo'),
                Tab(text: 'Por Pontuação'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _RecordList(
                  records: repo.topByTime,
                  valueLabel: (r) => _formatMs(r.elapsedMs),
                ),
                _RecordList(
                  records: repo.topByScore,
                  valueLabel: (r) => '${r.score} pts',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordList extends StatelessWidget {
  final List records;
  final String Function(dynamic) valueLabel;
  const _RecordList({required this.records, required this.valueLabel});

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return Center(
        child: OutlinedText(
          text: 'Jogue sua primeira partida para aparecer aqui!',
          style: GoogleFonts.fredoka(fontSize: 14),
          textAlign: TextAlign.center,
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: records.length,
      itemBuilder: (context, i) {
        final r = records[i];
        return Card(
          color: Colors.white.withValues(alpha: 0.88),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primary,
              child: Text(
                '${i + 1}',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(
              valueLabel(r),
              style: GoogleFonts.fredoka(fontSize: 18),
            ),
            trailing: Text(
              '${r.playedAt.day}/${r.playedAt.month}',
              style: GoogleFonts.nunito(fontSize: 12, color: Colors.grey),
            ),
          ),
        );
      },
    );
  }
}

class _LegendsRankingTab extends ConsumerWidget {
  const _LegendsRankingTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(authControllerProvider) != null;
    return Column(
      children: [
        if (!isLoggedIn)
          _LoginBanner(message: 'Faça login para aparecer neste ranking.'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              _LegendsCard(
                type: RankingType.legends4096Time,
                animal: animalForLevel(12),
                title: 'Lendas 4096',
                emptyMessage:
                    'Chegue ao nível 12 para entrar no ranking de Lendas 4096!',
                formatValue: (v) {
                  final s = v ~/ 1000;
                  final m = s ~/ 60;
                  final rem = s % 60;
                  return '${m.toString().padLeft(2, '0')}:${rem.toString().padLeft(2, '0')}';
                },
              ),
              const SizedBox(height: 16),
              _LegendsCard(
                type: RankingType.legends8192Count,
                animal: animalForLevel(13),
                title: 'Lendas 8192',
                emptyMessage:
                    'Chegue ao nível 13 para entrar no ranking de Lendas 8192!',
                formatValue: (v) => '$v ${v == 1 ? 'vez' : 'vezes'}',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LegendsCard extends ConsumerStatefulWidget {
  final RankingType type;
  final dynamic animal;
  final String title;
  final String emptyMessage;
  final String Function(int) formatValue;

  const _LegendsCard({
    required this.type,
    required this.animal,
    required this.title,
    required this.emptyMessage,
    required this.formatValue,
  });

  @override
  ConsumerState<_LegendsCard> createState() => _LegendsCardState();
}

class _LegendsCardState extends ConsumerState<_LegendsCard> {
  late Future<List<RankingEntry>> _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(legendsRankingRepositoryProvider).getWeeklyTop(widget.type);
  }

  void _retry() {
    setState(() {
      _future = ref.read(legendsRankingRepositoryProvider).getWeeklyTop(widget.type);
    });
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(legendsRankingRepositoryProvider);
    return Card(
      color: Colors.white.withValues(alpha: 0.92),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.asset(widget.animal.tilePngPath, height: 40),
                const SizedBox(width: 8),
                Text(
                  widget.title,
                  style: GoogleFonts.fredoka(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF3E2723),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<RankingEntry>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return TextButton(
                    onPressed: _retry,
                    child: const Text('Tentar novamente'),
                  );
                }
                final entries = snapshot.data ?? [];
                if (entries.isEmpty) {
                  return Text(
                    widget.emptyMessage,
                    style: GoogleFonts.nunito(fontSize: 13),
                  );
                }
                return Column(
                  children: [
                    ...entries
                        .take(3)
                        .map(
                          (e) => _EntryRow(entry: e, formatValue: widget.formatValue),
                        ),
                    FutureBuilder<RankingEntry?>(
                      future: repo.getPlayerEntry(widget.type),
                      builder: (context, snap) {
                        final player = snap.data;
                        if (player == null) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              widget.emptyMessage,
                              style: GoogleFonts.nunito(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        }
                        if (player.rank <= 3) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: _EntryRow(
                            entry: player,
                            formatValue: widget.formatValue,
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginBanner extends ConsumerWidget {
  const _LoginBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      color: Colors.black38,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.white70, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: outlinedWhiteTextStyle(GoogleFonts.fredoka(fontSize: 13)),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const OnboardingAuthScreen(showSkip: false),
              ),
            ),
            child: Text(
              'Entrar',
              style: outlinedWhiteTextStyle(
                GoogleFonts.fredoka(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFFF8C42),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlobalRankingTab extends ConsumerWidget {
  const _GlobalRankingTab();

  String _formatMs(int ms) {
    final s = ms ~/ 1000;
    final m = s ~/ 60;
    final rem = s % 60;
    return '${m.toString().padLeft(2, '0')}:${rem.toString().padLeft(2, '0')}';
  }

  String _timeUntilReset() {
    final now = DateTime.now().toUtc();
    final end = WeekId.weekEndsAt(now);
    final diff = end.difference(now);
    if (diff.inDays >= 1) return '${diff.inDays}d ${diff.inHours % 24}h';
    return '${diff.inHours}h ${diff.inMinutes % 60}min';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(authControllerProvider) != null;
    final entriesAsync = ref.watch(_globalRankingProvider);

    return Column(
      children: [
        ColoredBox(
          color: AppColors.primary.withValues(alpha: 0.85),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.timer_outlined,
                  color: Colors.white70,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  'Reinício em ${_timeUntilReset()}',
                  style: outlinedWhiteTextStyle(
                    GoogleFonts.fredoka(fontSize: 13, color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!isLoggedIn)
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Entre na sua conta para ver e participar do Ranking Global.',
                  style: outlinedWhiteTextStyle(
                    GoogleFonts.fredoka(fontSize: 16, color: Colors.white),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          )
        else
          Expanded(
            child: entriesAsync.when(
              skipLoadingOnRefresh: false,
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Erro ao carregar ranking.',
                      style: outlinedWhiteTextStyle(
                        GoogleFonts.fredoka(fontSize: 16, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => ref.invalidate(_globalRankingProvider),
                      child: Text(
                        'Tentar novamente',
                        style: outlinedWhiteTextStyle(
                          GoogleFonts.fredoka(
                            fontSize: 15,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              data: (entries) {
                if (entries.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Forme o 2048 para entrar no ranking desta semana!',
                        style: outlinedWhiteTextStyle(
                          GoogleFonts.fredoka(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: entries.length,
                  itemBuilder: (_, i) {
                    final e = entries[i];
                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: e.isLocalPlayer
                            ? AppColors.primary.withValues(alpha: 0.25)
                            : Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        dense: true,
                        leading: Text(
                          '${e.rank}º',
                          style: outlinedWhiteTextStyle(
                            GoogleFonts.fredoka(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: e.rank <= 3
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        title: Text(
                          e.playerName,
                          style: outlinedWhiteTextStyle(
                            GoogleFonts.fredoka(
                              fontSize: 15,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        trailing: Text(
                          _formatMs(e.value),
                          style: outlinedWhiteTextStyle(
                            GoogleFonts.fredoka(
                              fontSize: 15,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}

class _EntryRow extends StatelessWidget {
  final RankingEntry entry;
  final String Function(int) formatValue;
  const _EntryRow({required this.entry, required this.formatValue});

  String _medal(int rank) => switch (rank) {
    1 => '🥇',
    2 => '🥈',
    3 => '🥉',
    _ => '#${entry.rank}',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: entry.isLocalPlayer
          ? BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            )
          : null,
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              _medal(entry.rank),
              style: const TextStyle(fontSize: 16),
            ),
          ),
          Expanded(
            child: Text(
              entry.playerName,
              style: GoogleFonts.nunito(fontSize: 14),
            ),
          ),
          Text(
            formatValue(entry.value),
            style: GoogleFonts.fredoka(fontSize: 14),
          ),
        ],
      ),
    );
  }
}
