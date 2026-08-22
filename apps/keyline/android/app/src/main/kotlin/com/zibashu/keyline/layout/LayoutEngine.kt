package com.zibashu.keyline.layout

data class KeyRect(
    val key: KeyDefinition,
    val left: Int,
    val top: Int,
    val right: Int,
    val bottom: Int,
) {
    val width: Int get() = right - left
    val height: Int get() = bottom - top

    fun contains(x: Int, y: Int): Boolean =
        x >= left && x < right && y >= top && y < bottom

    fun overlaps(other: KeyRect): Boolean =
        left < other.right && other.left < right && top < other.bottom && other.top < bottom
}

/**
 * Proportional row layout. Positions are derived from weights and gaps, never
 * from hardcoded screen coordinates.
 */
object LayoutEngine {
    fun measure(
        layout: KeyboardLayout,
        width: Int,
        height: Int,
        gapPx: Int,
    ): List<KeyRect> {
        if (width <= 0 || height <= 0 || layout.rows.isEmpty()) return emptyList()
        val gap = gapPx.coerceAtLeast(0)
        val rowCount = layout.rows.size
        val innerH = (height - gap * (rowCount + 1)).coerceAtLeast(rowCount)
        val rowHeight = innerH / rowCount
        val leftoverH = innerH % rowCount
        val out = ArrayList<KeyRect>(layout.allKeys().size)
        var y = gap
        layout.rows.forEachIndexed { rowIndex, row ->
            val rh = rowHeight + if (rowIndex < leftoverH) 1 else 0
            val keyCount = row.keys.size
            if (keyCount == 0) {
                y += rh + gap
                return@forEachIndexed
            }
            val weightSum = row.leadingWeight + row.trailingWeight +
                row.keys.fold(0f) { acc, key -> acc + key.weight }
            val innerW = (width - gap * (keyCount + 1)).coerceAtLeast(keyCount)
            val unit = if (weightSum <= 0f) 0f else innerW / weightSum
            var x = gap + unit * row.leadingWeight
            row.keys.forEachIndexed { index, key ->
                val remainingKeys = keyCount - index
                val remainingGaps = remainingKeys - 1
                val trailingPx = unit * row.trailingWeight
                val maxRight = width - gap - trailingPx - remainingGaps * gap
                val desired = (unit * key.weight).toInt().coerceAtLeast(1)
                val left = x.toInt().coerceAtLeast(gap)
                var right = (left + desired).coerceAtMost(maxRight.toInt())
                if (index == keyCount - 1) {
                    right = (width - gap - trailingPx).toInt().coerceAtLeast(left + 1)
                }
                if (right <= left) right = left + 1
                out += KeyRect(key, left, y, right, y + rh)
                x = right + gap.toFloat()
            }
            y += rh + gap
        }
        return out
    }
}
