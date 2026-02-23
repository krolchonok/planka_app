import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../Provider/provider_list.dart';
import '../models/inputs.dart';
import 'board_list.dart';
import 'text_field.dart';

class KanbanBoard extends StatefulWidget {
  const KanbanBoard(
    this.list, {
    this.backgroundColor = Colors.white,
    this.cardPlaceHolderColor,
    this.boardScrollConfig,
    this.listScrollConfig,
    this.listPlaceHolderColor,
    this.boardDecoration,
    this.cardTransitionBuilder,
    this.listTransitionBuilder,
    this.cardTransitionDuration = const Duration(milliseconds: 150),
    this.listTransitionDuration = const Duration(milliseconds: 150),
    this.listDecoration,
    this.textStyle,
    this.onItemTap,
    this.displacementX = 0.0,
    this.displacementY = 0.0,
    this.onItemReorder,
    this.onListReorder,
    this.onListRename,
    this.onNewCardInsert,
    this.onItemLongPress,
    this.onListTap,
    this.onListLongPress,
    this.onListCreate,
    super.key,
  });

  final List<BoardListsData> list;
  final Color backgroundColor;
  final ScrollConfig? boardScrollConfig;
  final ScrollConfig? listScrollConfig;
  final Color? cardPlaceHolderColor;
  final Color? listPlaceHolderColor;
  final TextStyle? textStyle;
  final Decoration? listDecoration;
  final Decoration? boardDecoration;
  final void Function(int? cardIndex, int? listIndex)? onItemTap;
  final void Function(int? cardIndex, int? listIndex)? onItemLongPress;
  final void Function(int? listIndex)? onListTap;
  final void Function(int? listIndex)? onListLongPress;
  final void Function(String? title)? onListCreate;
  final void Function(int? oldCardIndex, int? newCardIndex, int? oldListIndex,
      int? newListIndex)? onItemReorder;
  final void Function(int? oldListIndex, int? newListIndex)? onListReorder;
  final void Function(String? oldName, String? newName)? onListRename;
  final void Function(String? cardIndex, String? listIndex, String? text)?
      onNewCardInsert;
  final Widget Function(Widget child, Animation<double> animation)?
      cardTransitionBuilder;
  final Widget Function(Widget child, Animation<double> animation)?
      listTransitionBuilder;
  final double displacementX;
  final double displacementY;
  final Duration cardTransitionDuration;
  final Duration listTransitionDuration;

  @override
  State<KanbanBoard> createState() => _KanbanBoardState();
}

class _KanbanBoardState extends State<KanbanBoard> {
  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: Board(
        widget.list,
        displacementX: widget.displacementX,
        displacementY: widget.displacementY,
        backgroundColor: widget.backgroundColor,
        boardDecoration: widget.boardDecoration,
        cardPlaceHolderColor: widget.cardPlaceHolderColor,
        listPlaceHolderColor: widget.listPlaceHolderColor,
        listDecoration: widget.listDecoration,
        boardScrollConfig: widget.boardScrollConfig,
        listScrollConfig: widget.listScrollConfig,
        textStyle: widget.textStyle,
        onItemTap: widget.onItemTap,
        onItemLongPress: widget.onItemLongPress,
        onListTap: widget.onListTap,
        onListLongPress: widget.onListLongPress,
        onItemReorder: widget.onItemReorder,
        onListReorder: widget.onListReorder,
        onListRename: widget.onListRename,
        onListCreate: widget.onListCreate,
        onNewCardInsert: widget.onNewCardInsert,
        cardTransitionBuilder: widget.cardTransitionBuilder,
        listTransitionBuilder: widget.listTransitionBuilder,
        cardTransitionDuration: widget.cardTransitionDuration,
        listTransitionDuration: widget.listTransitionDuration,
      ),
    );
  }
}

class Board extends ConsumerStatefulWidget {
  const Board(
    this.list, {
    this.backgroundColor = Colors.white,
    this.cardPlaceHolderColor,
    this.listPlaceHolderColor,
    this.boardDecoration,
    this.boardScrollConfig,
    this.listScrollConfig,
    this.cardTransitionBuilder,
    this.listTransitionBuilder,
    this.cardTransitionDuration = const Duration(milliseconds: 150),
    this.listTransitionDuration = const Duration(milliseconds: 150),
    this.listDecoration,
    this.textStyle,
    this.onItemTap,
    this.displacementX = 0.0,
    this.displacementY = 0.0,
    this.onItemReorder,
    this.onListReorder,
    this.onListRename,
    this.onNewCardInsert,
    this.onItemLongPress,
    this.onListTap,
    this.onListLongPress,
    this.onListCreate,
    super.key,
  });

  final List<BoardListsData> list;
  final Color backgroundColor;
  final Color? cardPlaceHolderColor;
  final Color? listPlaceHolderColor;
  final TextStyle? textStyle;
  final Decoration? listDecoration;
  final Decoration? boardDecoration;
  final ScrollConfig? boardScrollConfig;
  final ScrollConfig? listScrollConfig;
  final void Function(int? cardIndex, int? listIndex)? onItemTap;
  final void Function(int? cardIndex, int? listIndex)? onItemLongPress;
  final void Function(int? listIndex)? onListTap;
  final void Function(int? listIndex)? onListLongPress;
  final void Function(String? newName)? onListCreate;
  final void Function(int? oldCardIndex, int? newCardIndex, int? oldListIndex,
      int? newListIndex)? onItemReorder;
  final void Function(int? oldListIndex, int? newListIndex)? onListReorder;
  final void Function(String? oldName, String? newName)? onListRename;
  final void Function(String? cardIndex, String? listIndex, String? text)?
      onNewCardInsert;
  final Widget Function(Widget child, Animation<double> animation)?
      cardTransitionBuilder;
  final Widget Function(Widget child, Animation<double> animation)?
      listTransitionBuilder;
  final double displacementX;
  final double displacementY;
  final Duration cardTransitionDuration;
  final Duration listTransitionDuration;

  @override
  ConsumerState<Board> createState() => _BoardState();
}

class _BoardState extends ConsumerState<Board> {
  int _lastAutoListIndex = -1;
  bool _isSnapping = false;
  Timer? _snapDebounce;
  final GlobalKey _createListKey = GlobalKey();

  void _scheduleSnap() {
    if (_isSnapping) return;
    _snapDebounce?.cancel();
    _snapDebounce = Timer(const Duration(milliseconds: 140), () {
      if (mounted) {
        _snapToClosestList();
      }
    });
  }

  Future<void> _snapToClosestList() async {
    if (_isSnapping) return;
    final boardProv = ref.read(ProviderList.boardProvider);
    if (!boardProv.board.controller.hasClients || boardProv.board.lists.isEmpty) {
      return;
    }

    final controller = boardProv.board.controller;
    final viewport = controller.position.viewportDimension;
    if (viewport <= 0) return;
    final viewportCenter = controller.offset + (viewport / 2);
    final boardBox = context.findRenderObject() as RenderBox?;
    if (boardBox == null) return;
    final boardOrigin = boardBox.localToGlobal(Offset.zero).dx;

    double? closestCenter;
    double minDistance = double.infinity;

    for (int i = 0; i < boardProv.board.lists.length; i++) {
      final listContext = boardProv.board.lists[i].context;
      final listRender = listContext?.findRenderObject() as RenderBox?;
      if (listRender == null || !listRender.hasSize) continue;

      final listLeftInViewport =
          listRender.localToGlobal(Offset.zero).dx - boardOrigin;
      final listCenterInContent =
          controller.offset + listLeftInViewport + (listRender.size.width / 2);
      final distance = (listCenterInContent - viewportCenter).abs();
      if (distance < minDistance) {
        minDistance = distance;
        closestCenter = listCenterInContent;
      }
    }

    // Include "Create list" tile in snap candidates to prevent bouncing back
    // when user scrolls to the end of board.
    final createListRender =
        _createListKey.currentContext?.findRenderObject() as RenderBox?;
    if (createListRender != null && createListRender.hasSize) {
      final createListLeftInViewport =
          createListRender.localToGlobal(Offset.zero).dx - boardOrigin;
      final createListCenterInContent = controller.offset +
          createListLeftInViewport +
          (createListRender.size.width / 2);
      final createListDistance =
          (createListCenterInContent - viewportCenter).abs();
      if (createListDistance < minDistance) {
        minDistance = createListDistance;
        closestCenter = createListCenterInContent;
      }
    }

    if (closestCenter == null) return;

    final targetOffset = (closestCenter - (viewport / 2))
        .clamp(0.0, controller.position.maxScrollExtent)
        .toDouble();

    if ((controller.offset - targetOffset).abs() < 1) return;

    _isSnapping = true;
    try {
      await controller.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    } finally {
      _isSnapping = false;
    }
  }

  @override
  void initState() {
    var boardProv = ref.read(ProviderList.boardProvider);
    var boardListProv = ref.read(ProviderList.boardListProvider);
    boardProv.initializeBoard(
        data: widget.list,
        boardScrollConfig: widget.boardScrollConfig,
        listScrollConfig: widget.listScrollConfig,
        displacementX: widget.displacementX,
        displacementY: widget.displacementY,
        backgroundColor: widget.backgroundColor,
        boardDecoration: widget.boardDecoration,
        cardPlaceHolderColor: widget.cardPlaceHolderColor,
        listPlaceHolderColor: widget.listPlaceHolderColor,
        listDecoration: widget.listDecoration,
        textStyle: widget.textStyle,
        onItemTap: widget.onItemTap,
        onItemLongPress: widget.onItemLongPress,
        onListTap: widget.onListTap,
        onListLongPress: widget.onListLongPress,
        onItemReorder: widget.onItemReorder,
        onListReorder: widget.onListReorder,
        onListRename: widget.onListRename,
        onNewCardInsert: widget.onNewCardInsert,
        cardTransitionBuilder: widget.cardTransitionBuilder,
        listTransitionBuilder: widget.listTransitionBuilder,
        cardTransitionDuration: widget.cardTransitionDuration,
        listTransitionDuration: widget.listTransitionDuration);

    for (var element in boardProv.board.lists) {
      // List Scroll Listener
      element.scrollController.addListener(() {
        if (boardListProv.scrolling) {
          if (boardListProv.scrollingDown) {
            boardProv.valueNotifier.value = Offset(
                boardProv.valueNotifier.value.dx,
                boardProv.valueNotifier.value.dy + 0.00001);
          } else {
            boardProv.valueNotifier.value = Offset(
                boardProv.valueNotifier.value.dx,
                boardProv.valueNotifier.value.dy + 0.00001);
          }
        }
      });
    }

    // Board Scroll Listener
    boardProv.board.controller.addListener(() {
      if (!boardProv.board.isElementDragged && !boardProv.board.isListDragged) {
        _scheduleSnap();
      }

      if (boardProv.scrolling) {
        if (boardProv.scrollingLeft && boardProv.board.isListDragged) {
          for (var element in boardProv.board.lists) {
            if (element.context == null) break;
            var of = (element.context!.findRenderObject() as RenderBox)
                .localToGlobal(Offset.zero);
            element.x = of.dx - boardProv.board.displacementX! - 10;
            element.width = element.context!.size!.width - 30;
            element.y = of.dy - widget.displacementY + 24;
          }
          boardListProv.moveListLeft();
        } else if (boardProv.scrollingRight && boardProv.board.isListDragged) {
          for (var element in boardProv.board.lists) {
            if (element.context == null) break;
            var of = (element.context!.findRenderObject() as RenderBox)
                .localToGlobal(Offset.zero);
            element.x = of.dx - boardProv.board.displacementX! - 10;
            element.width = element.context!.size!.width - 30;
            element.y = of.dy - widget.displacementY + 24;
          }
          boardListProv.moveListRight();
        }
      }

      // Auto-detect the currently visible list by board horizontal offset
      // and notify host screen, so actions can target the active list.
      if (widget.onListTap != null && boardProv.board.lists.isNotEmpty) {
        final firstWidth = boardProv.board.lists.first.width ??
            (MediaQuery.of(context).size.width * 0.9);
        final itemExtent = firstWidth + 45; // list left+right spacing in this layout
        if (itemExtent > 0) {
          final rawIndex = (boardProv.board.controller.offset / itemExtent).round();
          final visibleIndex = rawIndex
              .clamp(0, boardProv.board.lists.length - 1)
              .toInt();
          if (visibleIndex != _lastAutoListIndex) {
            _lastAutoListIndex = visibleIndex;
            widget.onListTap!(visibleIndex);
          }
        }
      }
    });

    super.initState();
  }

  @override
  void dispose() {
    _snapDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var boardProv = ref.read(ProviderList.boardProvider);
    var boardListProv = ref.read(ProviderList.boardListProvider);
    final colorScheme = Theme.of(context).colorScheme;
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      boardProv.board.setstate = () => setState(() {});
      var box = context.findRenderObject() as RenderBox;
      boardProv.board.displacementX =
          box.localToGlobal(Offset.zero).dx - 10; //- margin
      boardProv.board.displacementY =
          box.localToGlobal(Offset.zero).dy + 24; // statusbar
    });
    return Listener(
      onPointerUp: (event) {
        if (boardProv.board.isElementDragged || boardProv.board.isListDragged) {
          if (boardProv.board.isElementDragged) {
            ref.read(ProviderList.cardProvider).reorderCard();
          }
          if (boardProv.board.isListDragged) {
            ref.read(ProviderList.boardListProvider).reorderListFromKanBanBoard();
          }
          boardProv.setcanDrag(value: false, listIndex: 0, itemIndex: 0);
          setState(() {});
        } else {
          _scheduleSnap();
        }
      },
      onPointerMove: (event) {
        if (boardProv.board.isElementDragged) {
          if (event.delta.dx > 0) {
            boardProv.boardScroll();
          } else {
            boardProv.boardScroll();
          }
        } else if (boardProv.board.isListDragged) {
          if (event.delta.dx > 0) {
            boardProv.boardScroll();
            boardListProv.moveListRight();
          } else {
            boardProv.boardScroll();
            boardListProv.moveListLeft();
          }
        }
        boardProv.valueNotifier.value = Offset(
            event.delta.dx + boardProv.valueNotifier.value.dx,
            event.delta.dy + boardProv.valueNotifier.value.dy);
      },
      child: GestureDetector(
        onTap: () {
          if (boardProv.board.newCardFocused == true) {
            ref.read(ProviderList.cardProvider).saveNewCard();
          }
        },
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            decoration: widget.boardDecoration ??
                BoxDecoration(color: widget.backgroundColor),
            child: Stack(
              fit: StackFit.passthrough,
              clipBehavior: Clip.none,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 1200,
                        child: ScrollConfiguration(
                          behavior: ScrollConfiguration.of(context).copyWith(
                            dragDevices: {
                              PointerDeviceKind.mouse,
                              PointerDeviceKind.touch,
                            },
                          ),
                          child: NotificationListener<ScrollNotification>(
                            onNotification: (notification) {
                              final isHorizontal =
                                  notification.metrics.axis == Axis.horizontal;
                              if (!isHorizontal || notification.depth != 0) {
                                return false;
                              }
                              if (notification is ScrollEndNotification) {
                                _snapToClosestList();
                              }
                              return false;
                            },
                            child: SingleChildScrollView(
                              controller: boardProv.board.controller,
                              physics: const ClampingScrollPhysics(),
                              scrollDirection: Axis.horizontal,
                              child: Transform(
                              alignment: Alignment.topLeft,
                              transform: Matrix4(1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(width: 15),
                                  // Render all lists if any exist
                                  ...boardProv.board.lists.map((e) {
                                    return BoardList(index: boardProv.board.lists.indexOf(e));
                                  }),

                                    // Always show the "Add List" widget after the lists (or alone if there are no lists)
                                    boardListProv.newList ?
                                    Container(
                                      key: _createListKey,
                                      margin: const EdgeInsets.only(top: 20),
                                      padding: const EdgeInsets.only(bottom: 20),
                                      width: MediaQuery.of(context).size.width * 0.9,
                                      decoration: BoxDecoration(
                                        color: colorScheme.surfaceContainerHigh,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: colorScheme.outlineVariant),
                                      ),
                                      child: Wrap(
                                        children: [
                                          SizedBox(
                                            height: 50,
                                            width: 300,
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                IconButton(
                                                  onPressed: () {
                                                    setState(() {
                                                      boardListProv.newList = false;
                                                      boardProv.board.newCardTextController.clear();
                                                    });
                                                  },
                                                  icon: const Icon(Icons.close),
                                                ),
                                                IconButton(
                                                  onPressed: () {
                                                    setState(() {
                                                      boardListProv.newList = false;
                                                      // Create New List Here
                                                      if (widget.onListCreate != null) {
                                                        widget.onListCreate!(boardProv.board.newCardTextController.text);
                                                      }
                                                      boardProv.board.newCardTextController.clear();
                                                    });
                                                  },
                                                  icon: const Icon(Icons.done),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            width: 300,
                                            color: colorScheme.surface,
                                            margin: const EdgeInsets.only(top: 20, right: 10, left: 10),
                                            child: const TField(), // Replace TField with your text field implementation
                                          ),
                                        ],
                                      ),
                                    )
                                        : GestureDetector(
                                      onTap: () {
                                        if (boardProv.board.newCardFocused == true) {
                                          ref.read(ProviderList.cardProvider).saveNewCard();
                                        }
                                        boardListProv.newList = true;
                                        setState(() {});
                                      },
                                      child: Container(
                                        key: _createListKey,
                                        height: 50,
                                        width: MediaQuery.of(context).size.width * 0.9,
                                        margin: const EdgeInsets.only(top: 20),
                                        decoration: BoxDecoration(
                                          color: colorScheme.primaryContainer,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: colorScheme.outlineVariant),
                                        ),
                                        child: Center(
                                          child: Text(
                                            'create_list'.tr(),
                                            style: (widget.textStyle ?? Theme.of(context).textTheme.titleMedium)
                                                ?.copyWith(color: colorScheme.onPrimaryContainer),
                                          ),
                                        ),
                                      ),
                                    ),
                                  const SizedBox(width: 15),
                                ],
                              ),
                            ),
                          ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                ValueListenableBuilder(
                  valueListenable: boardProv.valueNotifier,
                  builder: (ctx, Offset value, child) {
                    if (boardProv.board.isElementDragged) {
                      boardListProv.maybeListScroll();
                    }
                    return boardProv.board.isElementDragged || boardProv.board.isListDragged
                        ? Positioned(
                            left: value.dx,
                            top: value.dy,
                            child: Opacity(
                              opacity: 0.4,
                              child: boardProv.draggedItemState!.child,
                            ),
                          )
                        : Container();
                  },
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
