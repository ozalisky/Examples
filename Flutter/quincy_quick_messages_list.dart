import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:nda/cubits/cubits.dart';
import 'package:nda/mixins/mixins.dart';
import 'package:nda/modals/modals.dart';
import 'package:nda/screens/screens.dart';
import 'package:nda/styles/styles.dart';
import 'package:nda/widgets/widgets.dart';
import 'package:nda/proto/apps/vc/vc.dart' as vc;

/// The page designed to show all [QuickMessages].
class NDAQuickMessagesList extends StatefulWidget {
  const NDAQuickMessagesList._({Key? key}) : super(key: key);

  static PageRoute<String> route() => ModalPageRoute(
        settings: const RouteSettings(name: 'ChatsQuickMessagesList'),
        builder: (_) => const NDAQuickMessagesList._(),
      );

  @override
  _NDAQuickMessagesListState createState() => _NDAQuickMessagesListState();
}

class _NDAQuickMessagesListState extends State<NDAQuickMessagesList>
    with NetworkStateMixin {
  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    searchController.addListener(onSearchChanged);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkTheme = theme.brightness.isDark;

    return KeyboardDismisser(
      child: Scaffold(
        backgroundColor: theme.cardColor,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          toolbarHeight: Dimension.defaultToolbarHeight,
          leadingWidth: Dimension.defaultLeadingWidth,
          leading: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.chevron_left,
                  color: theme.primaryColor,
                  size: Dimension.iconMd,
                ),
                AccessibilityWrapper(
                  child: Text(
                    FlutterI18n.translate(
                      context,
                      'cta.back',
                    ),
                    style: const TextStyle(
                      fontFamily: FontFamily.sfProText,
                      fontSize: 17,
                      height: 1.29411765,
                      letterSpacing: -0.54,
                    ),
                  ),
                )
              ],
            ),
          ),
          centerTitle: true,
          title: Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
              FlutterI18n.translate(context, 'label.title.quickMessages'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: FontFamily.sfProText,
                fontSize: 17,
                height: 0.70588235,
                letterSpacing: -0.41,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          iconTheme: IconThemeData(
            color: theme.primaryColor,
            size: Dimension.iconSm,
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 19.0),
              child: InkWell(
                onTap: _handleAddPressed,
                child: Icon(
                  Icons.add,
                  color: theme.primaryColor,
                  size: 36,
                ),
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize:
                const Size.fromHeight(Dimension.defaultToolbarHeight),
            child: SearchBar(
              controller: searchController,
              margin: const EdgeInsets.only(
                left: Dimension.sm,
                right: Dimension.sm,
                bottom: 10,
              ),
              textFieldColor: theme.colorScheme.inverseSurface,
            ),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: BlocBuilder<NDAQuickMessagesCubit, NDAQuickMessagesState>(
                builder: (_, state) {
                  if (state.searchResults.isEmpty) {
                    return Center(
                      child: EmptyPlaceholder(
                        icon: const Icon(NDAIcons.quickMessage),
                        title: Text(
                          FlutterI18n.translate(
                            context,
                            'label.empty_qm_title',
                          ),
                        ),
                        subtitle: Text(
                          FlutterI18n.translate(
                            context,
                            'label.empty_qm_subtitle',
                          ),
                        ),
                        actionText: FlutterI18n.translate(
                          context,
                          'cta.create_quick_message',
                        ),
                        onPressed: _handleAddPressed,
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 20, 15, 20),
                    itemCount: state.searchResults.length,
                    itemBuilder: (context, index) {
                      final quickMessage = state.searchResults[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: FractionallySizedBox(
                            widthFactor:
                                MediaQuery.of(context).isTablet ? 0.5 : 1,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Flexible(
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: Dimension.xs,
                                    ),
                                    child: IntrinsicWidth(
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          minWidth: 120,
                                        ),
                                        child: GestureDetector(
                                          behavior: HitTestBehavior.translucent,
                                          onTap: () => Navigator.of(context)
                                              .pop(quickMessage.message),
                                          onLongPress: () => _handleLongPress(
                                            quickMessage,
                                          ),
                                          child: ChatMessageBubble(
                                            isMessageOut: true,
                                            padding: const EdgeInsets.all(
                                              Dimension.sm,
                                            ),
                                            color: isDarkTheme
                                                ? Palette.darkOutChatBubbleColor
                                                : Palette.outMessageBackground,
                                            children: [
                                              Align(
                                                alignment:
                                                    Alignment.centerRight,
                                                child: Text(
                                                  quickMessage.message,
                                                  textAlign: TextAlign.left,
                                                  style: TextStyle(
                                                    fontSize: FontSize.lg,
                                                    height: 1.39,
                                                    color: theme.textTheme
                                                        .displaySmall?.color,
                                                  ),
                                                ),
                                              )
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
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
        ),
      ),
    );
  }

  void onSearchChanged() {
    context.read<NDAQuickMessagesCubit>().search(searchController.text);
  }

  void _handleAddPressed() {
    Navigator.push(
      context,
      ConversationQuickMessagesAdd.route(isNDA: true),
    );
  }

  void _handleLongPress(vc.QuickMessage qm) async {
    final quickMessagesCubit = context.read<NDAQuickMessagesCubit>();
    final option = await showQuickMessageSheet(context, showEdit: false);

    switch (option) {
      case QuickMessageActions.remove:
      default:
        quickMessagesCubit.removeQuickMessages(ids: [qm.id]);
        break;
    }
  }

  @override
  void dispose() {
    searchController
      ..removeListener(onSearchChanged)
      ..dispose();

    super.dispose();
  }
}
