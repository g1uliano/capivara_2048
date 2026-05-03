import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/ranking_provider.dart';
import '../../data/animals_data.dart';
import '../../data/repositories/game_record_repository.dart';
import '../../domain/ranking/ranking_repository.dart';
import '../widgets/game_background.dart';
import '../widgets/outlined_text.dart';

class RankingScreen extends ConsumerWidget {
  const RankingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GameBackground(
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: OutlinedText(
              text: 'Ranking',
              style: GoogleFonts.fredoka(fontSize: 22),
            ),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            bottom: const TabBar(
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              tabs: [
                Tab(text: 'Pessoal'),
                Tab(text: 'Lendas'),
              ],
            ),
          ),
          body: const TabBarView(
            children: [
              _PersonalRankingTab(),
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
          TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(text: 'Por Tempo'),
              Tab(text: 'Por Pontuação'),
            ],
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
        child: Text(
          'Jogue sua primeira partida para aparecer aqui!',
          style: GoogleFonts.nunito(fontSize: 14),
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
              child: Text('${i + 1}', style: const TextStyle(color: Colors.white)),
            ),
            title: Text(valueLabel(r), style: GoogleFonts.fredoka(fontSize: 18)),
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
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _LegendsCard(
          type: RankingType.legends4096Time,
          animal: animalForLevel(12),
          title: 'Lendas 4096',
          emptyMessage: 'Chegue ao nível 12 para entrar no ranking de Lendas 4096!',
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
          emptyMessage: 'Chegue ao nível 13 para entrar no ranking de Lendas 8192!',
          formatValue: (v) => '$v ${v == 1 ? 'vez' : 'vezes'}',
        ),
      ],
    );
  }
}

class _LegendsCard extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(rankingRepositoryProvider);
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
                Image.asset(animal.tilePngPath, height: 40),
                const SizedBox(width: 8),
                OutlinedText(
                  text: title,
                  style: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<RankingEntry>>(
              future: repo.getWeeklyTop(type),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return TextButton(
                    onPressed: () => (context as Element).markNeedsBuild(),
                    child: const Text('Tentar novamente'),
                  );
                }
                final entries = snapshot.data ?? [];
                if (entries.isEmpty) {
                  return Text(emptyMessage, style: GoogleFonts.nunito(fontSize: 13));
                }
                return Column(
                  children: [
                    ...entries.take(3).map((e) => _EntryRow(entry: e, formatValue: formatValue)),
                    FutureBuilder<RankingEntry?>(
                      future: repo.getPlayerEntry(type),
                      builder: (context, snap) {
                        final player = snap.data;
                        if (player == null) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(emptyMessage,
                                style: GoogleFonts.nunito(fontSize: 12, color: Colors.grey)),
                          );
                        }
                        if (player.rank <= 3) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: _EntryRow(entry: player, formatValue: formatValue),
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

class _EntryRow extends StatelessWidget {
  final RankingEntry entry;
  final String Function(int) formatValue;
  const _EntryRow({required this.entry, required this.formatValue});

  String _medal(int rank) => switch (rank) { 1 => '🥇', 2 => '🥈', 3 => '🥉', _ => '#${entry.rank}' };

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
            child: Text(_medal(entry.rank), style: const TextStyle(fontSize: 16)),
          ),
          Expanded(child: Text(entry.playerName, style: GoogleFonts.nunito(fontSize: 14))),
          Text(formatValue(entry.value), style: GoogleFonts.fredoka(fontSize: 14)),
        ],
      ),
    );
  }
}
