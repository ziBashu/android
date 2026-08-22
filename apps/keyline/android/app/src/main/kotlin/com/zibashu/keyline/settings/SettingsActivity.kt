package com.zibashu.keyline.settings

import android.app.Activity
import android.content.res.Configuration
import android.graphics.Typeface
import android.os.Bundle
import android.util.TypedValue
import android.view.Gravity
import android.widget.LinearLayout
import android.widget.RadioButton
import android.widget.RadioGroup
import android.widget.ScrollView
import android.widget.Switch
import android.widget.TextView
import com.zibashu.keyline.theme.KeylinePalette

class SettingsActivity : Activity() {
    private lateinit var store: KeylineSettingsStore
    private lateinit var snapshot: KeylineSettingsSnapshot

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        store = KeylineSettingsStore(this)
        snapshot = store.load()
        setContentView(buildUi())
    }

    private fun buildUi(): ScrollView {
        val dark = isSystemDark()
        val colors = KeylinePalette.resolve(snapshot.theme, dark)
        val density = resources.displayMetrics.density
        val pad = (20 * density).toInt()

        val column = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(pad, pad, pad, pad)
            setBackgroundColor(colors.keyboardBackground)
        }

        column.addView(heading("KEYLINE", colors.keyLabel, 26f))
        column.addView(body("from ziBashu", colors.suggestionHighlight, 14f))
        column.addView(space(12))
        column.addView(
            body(
                "KEYLINE never sends what you type to a server. The dictionary, corrections, and settings stay on this device.",
                colors.keyLabel,
                15f,
            ),
        )
        column.addView(space(20))

        column.addView(heading("Appearance", colors.keyLabel, 18f))
        column.addView(space(8))
        column.addView(
            enumGroup(
                "Theme",
                listOf("System" to ThemeMode.SYSTEM, "Light" to ThemeMode.LIGHT, "Dark" to ThemeMode.DARK),
                snapshot.theme,
                colors,
            ) { snapshot = snapshot.copy(theme = it); persist(); recreate() },
        )
        column.addView(
            enumGroup(
                "Keyboard height",
                listOf(
                    "Compact" to KeyboardHeight.COMPACT,
                    "Normal" to KeyboardHeight.NORMAL,
                    "Tall" to KeyboardHeight.TALL,
                ),
                snapshot.height,
                colors,
            ) { snapshot = snapshot.copy(height = it); persist() },
        )
        column.addView(
            enumGroup(
                "Key size / spacing",
                listOf(
                    "Compact" to KeySpacing.COMPACT,
                    "Normal" to KeySpacing.NORMAL,
                    "Large" to KeySpacing.LARGE,
                ),
                snapshot.spacing,
                colors,
            ) { snapshot = snapshot.copy(spacing = it); persist() },
        )

        column.addView(space(16))
        column.addView(heading("Behavior", colors.keyLabel, 18f))
        column.addView(space(8))
        column.addView(switchRow("Key vibration", snapshot.vibration, colors) {
            snapshot = snapshot.copy(vibration = it); persist()
        })
        column.addView(switchRow("Key sound", snapshot.sound, colors) {
            snapshot = snapshot.copy(sound = it); persist()
        })
        column.addView(switchRow("Suggestions", snapshot.suggestions, colors) {
            snapshot = snapshot.copy(suggestions = it); persist()
        })
        column.addView(switchRow("Auto-correction", snapshot.autoCorrection, colors) {
            snapshot = snapshot.copy(autoCorrection = it); persist()
        })
        column.addView(switchRow("Auto-capitalization", snapshot.autoCapitalization, colors) {
            snapshot = snapshot.copy(autoCapitalization = it); persist()
        })

        column.addView(space(16))
        column.addView(heading("Language", colors.keyLabel, 18f))
        column.addView(space(8))
        column.addView(body("English", colors.keyLabel, 16f))
        column.addView(
            body(
                "Additional languages can be added later as independent language packs. V1 ships English only.",
                colors.suggestionHighlight,
                13f,
            ),
        )

        val scroll = ScrollView(this)
        scroll.setBackgroundColor(colors.keyboardBackground)
        scroll.addView(column)
        return scroll
    }

    private fun persist() {
        store.save(snapshot)
    }

    private fun heading(text: String, color: Int, size: Float): TextView =
        TextView(this).apply {
            this.text = text
            setTextColor(color)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, size)
            typeface = Typeface.create(Typeface.SANS_SERIF, Typeface.BOLD)
            setPadding(0, (8 * resources.displayMetrics.density).toInt(), 0, 0)
        }

    private fun body(text: String, color: Int, size: Float): TextView =
        TextView(this).apply {
            this.text = text
            setTextColor(color)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, size)
            setLineSpacing(0f, 1.25f)
            setPadding(0, (4 * resources.displayMetrics.density).toInt(), 0, (4 * resources.displayMetrics.density).toInt())
        }

    private fun space(dp: Int) = TextView(this).apply {
        height = (dp * resources.displayMetrics.density).toInt()
    }

    private fun <T : Enum<T>> enumGroup(
        title: String,
        options: List<Pair<String, T>>,
        selected: T,
        colors: com.zibashu.keyline.theme.KeylineColors,
        onPick: (T) -> Unit,
    ): LinearLayout {
        val box = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL }
        box.addView(body(title, colors.suggestionHighlight, 13f))
        val group = RadioGroup(this).apply { orientation = LinearLayout.VERTICAL }
        options.forEachIndexed { index, (label, value) ->
            val btn = RadioButton(this).apply {
                text = label
                isChecked = value == selected
                setTextColor(colors.keyLabel)
                id = index + 1
                setOnClickListener { onPick(value) }
            }
            group.addView(btn, LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f))
        }
        box.addView(group)
        return box
    }

    private fun switchRow(
        title: String,
        checked: Boolean,
        colors: com.zibashu.keyline.theme.KeylineColors,
        onChange: (Boolean) -> Unit,
    ): LinearLayout {
        val row = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(0, (8 * resources.displayMetrics.density).toInt(), 0, (8 * resources.displayMetrics.density).toInt())
        }
        val label = TextView(this).apply {
            text = title
            setTextColor(colors.keyLabel)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
        }
        val toggle = Switch(this).apply {
            isChecked = checked
            setOnCheckedChangeListener { _, isChecked -> onChange(isChecked) }
        }
        row.addView(label, LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f))
        row.addView(toggle)
        return row
    }

    private fun isSystemDark(): Boolean {
        val night = resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK
        return night == Configuration.UI_MODE_NIGHT_YES
    }
}
