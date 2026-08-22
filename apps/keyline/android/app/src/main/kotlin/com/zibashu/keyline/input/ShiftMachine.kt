package com.zibashu.keyline.input

enum class ShiftMode {
    OFF,
    SHIFTED,
    CAPS_LOCK,
}

class ShiftMachine(
    private val doubleTapMs: Long = 400L,
) {
    var mode: ShiftMode = ShiftMode.OFF
        private set

    private var lastShiftTapAt: Long = 0L
    private var lastWasShiftTap: Boolean = false

    fun tapShift(nowMs: Long) {
        when (mode) {
            ShiftMode.CAPS_LOCK -> {
                mode = ShiftMode.OFF
                lastWasShiftTap = false
            }
            ShiftMode.SHIFTED -> {
                mode = if (lastWasShiftTap && nowMs - lastShiftTapAt <= doubleTapMs) {
                    lastWasShiftTap = false
                    ShiftMode.CAPS_LOCK
                } else {
                    lastWasShiftTap = false
                    ShiftMode.OFF
                }
            }
            ShiftMode.OFF -> {
                if (lastWasShiftTap && nowMs - lastShiftTapAt <= doubleTapMs) {
                    mode = ShiftMode.CAPS_LOCK
                    lastWasShiftTap = false
                } else {
                    mode = ShiftMode.SHIFTED
                    lastWasShiftTap = true
                    lastShiftTapAt = nowMs
                }
            }
        }
    }

    fun onCharacterCommitted() {
        if (mode == ShiftMode.SHIFTED) {
            mode = ShiftMode.OFF
        }
        lastWasShiftTap = false
    }

    fun apply(text: String): String {
        if (text.isEmpty() || mode == ShiftMode.OFF) return text
        return buildString(text.length) {
            for (ch in text) {
                append(if (ch.isLetter()) ch.uppercaseChar() else ch)
            }
        }
    }

    fun setFromAutoCap(shouldCap: Boolean) {
        if (mode == ShiftMode.CAPS_LOCK) return
        mode = if (shouldCap) ShiftMode.SHIFTED else ShiftMode.OFF
        lastWasShiftTap = false
    }

    fun reset() {
        mode = ShiftMode.OFF
        lastWasShiftTap = false
        lastShiftTapAt = 0L
    }
}
