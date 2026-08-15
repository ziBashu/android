/// Pack home slots (apps + multi-cell widgets) into a grid. Pure — tests drive this.
library;

import 'home_occupancy.dart';

class HomeCellSpan {
  const HomeCellSpan(this.cols, this.rows);
  final int cols;
  final int rows;
}

class PackedHomeCell {
  const PackedHomeCell({
    required this.id,
    required this.index,
    required this.col,
    required this.row,
    required this.colSpan,
    required this.rowSpan,
  });

  final String id;
  final int index;
  final int col;
  final int row;
  final int colSpan;
  final int rowSpan;

  int get cellCount => colSpan * rowSpan;
}

class HomeGridPack {
  HomeGridPack._();

  static HomeCellSpan spanOf(String id, int columns) {
    final w = HomeWidgetKindX.ofSlot(id);
    if (w == null) return const HomeCellSpan(1, 1);
    return HomeCellSpan(w.colSpan.clamp(1, columns), w.rowSpan.clamp(1, 4));
  }

  static List<PackedHomeCell> pack(List<String> slots, int columns) {
    final cols = columns.clamp(3, 6);
    final used = <String>{};
    final out = <PackedHomeCell>[];
    for (var i = 0; i < slots.length; i++) {
      final id = slots[i];
      final span = spanOf(id, cols);
      var placed = false;
      var r = 0;
      while (!placed && r < 80) {
        for (var c = 0; c <= cols - span.cols; c++) {
          if (_free(used, c, r, span.cols, span.rows, cols)) {
            _mark(used, c, r, span.cols, span.rows);
            out.add(
              PackedHomeCell(
                id: id,
                index: i,
                col: c,
                row: r,
                colSpan: span.cols,
                rowSpan: span.rows,
              ),
            );
            placed = true;
            break;
          }
        }
        r++;
      }
    }
    return out;
  }

  static int rowCount(List<PackedHomeCell> cells) {
    var max = 0;
    for (final c in cells) {
      final bottom = c.row + c.rowSpan;
      if (bottom > max) max = bottom;
    }
    return max;
  }

  static bool _free(
    Set<String> used,
    int col,
    int row,
    int w,
    int h,
    int columns,
  ) {
    for (var r = row; r < row + h; r++) {
      for (var c = col; c < col + w; c++) {
        if (c >= columns) return false;
        if (used.contains('$c,$r')) return false;
      }
    }
    return true;
  }

  static void _mark(Set<String> used, int col, int row, int w, int h) {
    for (var r = row; r < row + h; r++) {
      for (var c = col; c < col + w; c++) {
        used.add('$c,$r');
      }
    }
  }
}
