import 'package:flutter/material.dart';

import '../core/home_grid_pack.dart';

/// Mixed app + widget board. Widgets occupy several app cells.
class HomeMixedGrid extends StatelessWidget {
  const HomeMixedGrid({
    super.key,
    required this.slots,
    required this.columns,
    required this.aspect,
    required this.editing,
    required this.itemBuilder,
    required this.onMove,
    this.trailing,
  });

  final List<String> slots;
  final int columns;
  final double aspect;
  final bool editing;
  final Widget Function(String id, int index) itemBuilder;
  final void Function(int from, int to) onMove;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final packed = HomeGridPack.pack(slots, columns);
    final rows = HomeGridPack.rowCount(packed) + (editing && trailing != null ? 1 : 0);
    return LayoutBuilder(
      builder: (context, box) {
        const gap = 8.0;
        final cols = columns.clamp(3, 6);
        final cellW = (box.maxWidth - gap * (cols - 1)) / cols;
        final cellH = cellW / aspect;
        final height = rows <= 0 ? cellH : rows * cellH + (rows - 1) * gap;
        return SingleChildScrollView(
          physics: editing
              ? const NeverScrollableScrollPhysics()
              : const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: height,
            child: Stack(
              children: [
                for (final cell in packed)
                  Positioned(
                    left: cell.col * (cellW + gap),
                    top: cell.row * (cellH + gap),
                    width: cell.colSpan * cellW + (cell.colSpan - 1) * gap,
                    height: cell.rowSpan * cellH + (cell.rowSpan - 1) * gap,
                    child: _DragCell(
                      index: cell.index,
                      editing: editing,
                      onMove: onMove,
                      child: itemBuilder(cell.id, cell.index),
                    ),
                  ),
                if (editing && trailing != null)
                  Positioned(
                    left: 0,
                    top: HomeGridPack.rowCount(packed) * (cellH + gap),
                    width: cellW,
                    height: cellH,
                    child: trailing!,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DragCell extends StatelessWidget {
  const _DragCell({
    required this.index,
    required this.editing,
    required this.onMove,
    required this.child,
  });

  final int index;
  final bool editing;
  final void Function(int from, int to) onMove;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!editing) return child;
    return LongPressDraggable<int>(
      data: index,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(width: 72, height: 72, child: Opacity(opacity: 0.9, child: child)),
      ),
      childWhenDragging: Opacity(opacity: 0.25, child: child),
      child: DragTarget<int>(
        onWillAcceptWithDetails: (d) => d.data != index,
        onAcceptWithDetails: (d) => onMove(d.data, index),
        builder: (_, __, ___) => child,
      ),
    );
  }
}
