import 'package:dartchess/dartchess.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lichess_mobile/src/constants.dart';
import 'package:lichess_mobile/src/model/account/account_repository.dart';
import 'package:lichess_mobile/src/model/auth/auth_session.dart';
import 'package:lichess_mobile/src/model/game/archived_game.dart';
import 'package:lichess_mobile/src/model/game/game_repository_providers.dart';
import 'package:lichess_mobile/src/model/game/game_status.dart';
import 'package:lichess_mobile/src/model/user/user.dart';
import 'package:lichess_mobile/src/styles/lichess_colors.dart';
import 'package:lichess_mobile/src/styles/styles.dart';
import 'package:lichess_mobile/src/utils/l10n_context.dart';
import 'package:lichess_mobile/src/utils/navigation.dart';
import 'package:lichess_mobile/src/view/game/archived_game_screen.dart';
import 'package:lichess_mobile/src/view/game/game_list_tile.dart';
import 'package:lichess_mobile/src/view/game/standalone_game_screen.dart';
import 'package:lichess_mobile/src/widgets/list.dart';
import 'package:lichess_mobile/src/widgets/shimmer.dart';
import 'package:lichess_mobile/src/widgets/user_full_name.dart';
import 'package:timeago/timeago.dart' as timeago;

class RecentGames extends ConsumerWidget {
  const RecentGames({this.user, super.key});

  final LightUser? user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentGames = user != null
        ? ref.watch(userRecentGamesProvider(userId: user!.id))
        : ref.watch(accountRecentGamesProvider);

    final userId = user?.id ?? ref.watch(authSessionProvider)?.user.id;

    Widget getResultIcon(LightArchivedGame game, Side mySide) {
      if (game.status == GameStatus.aborted ||
          game.status == GameStatus.noStart) {
        return const Icon(
          CupertinoIcons.xmark_square_fill,
          color: LichessColors.grey,
        );
      } else {
        return game.winner == null
            ? const Icon(
                CupertinoIcons.equal_square_fill,
                color: LichessColors.brag,
              )
            : game.winner == mySide
                ? const Icon(
                    CupertinoIcons.plus_square_fill,
                    color: LichessColors.good,
                  )
                : const Icon(
                    CupertinoIcons.minus_square_fill,
                    color: LichessColors.red,
                  );
      }
    }

    return recentGames.when(
      data: (data) {
        if (data.isEmpty) {
          return kEmptyWidget;
        }
        return ListSection(
          header: Text(context.l10n.recentGames),
          hasLeading: true,
          children: data.map((game) {
            final mySide =
                game.white.user?.id == userId ? Side.white : Side.black;
            final me = game.white.user?.id == userId ? game.white : game.black;
            final opponent =
                game.white.user?.id == userId ? game.black : game.white;

            return GameListTile(
              game: game,
              mySide: userId == game.white.user?.id ? Side.white : Side.black,
              onTap: game.variant.isSupported
                  ? () {
                      pushPlatformRoute(
                        context,
                        rootNavigator: true,
                        builder: (context) => game.fullId != null
                            ? StandaloneGameScreen(
                                params: InitialStandaloneGameParams(
                                  id: game.fullId!,
                                ),
                              )
                            : ArchivedGameScreen(
                                gameData: game,
                                orientation: userId == game.white.user?.id
                                    ? Side.white
                                    : Side.black,
                              ),
                      );
                    }
                  : null,
              icon: game.perf.icon,
              playerTitle: UserFullNameWidget.player(
                user: opponent.user,
                aiLevel: opponent.aiLevel,
                rating: opponent.rating,
              ),
              subtitle: Text(
                timeago.format(game.lastMoveAt),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (me.analysis != null) ...[
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.chart_bar_alt_fill,
                          color: textShade(context, 0.5),
                        ),
                        Text(
                          me.analysis!.accuracy.toString(),
                          style: TextStyle(
                            fontSize: 10,
                            color: textShade(context, Styles.subtitleOpacity),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 5),
                  ],
                  getResultIcon(game, mySide),
                ],
              ),
            );
          }).toList(),
        );
      },
      error: (error, stackTrace) {
        debugPrint(
          'SEVERE: [RecentGames] could not recent games; $error\n$stackTrace',
        );
        return Padding(
          padding: Styles.bodySectionPadding,
          child: const Text('Could not load recent games.'),
        );
      },
      loading: () => Shimmer(
        child: ShimmerLoading(
          isLoading: true,
          child: ListSection.loading(
            itemsNumber: 10,
            header: true,
          ),
        ),
      ),
    );
  }
}
