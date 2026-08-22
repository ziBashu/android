package com.zibashu.keyline.ime

import android.content.SharedPreferences
import android.content.res.Configuration
import android.view.View
import android.view.ViewGroup
import android.view.inputmethod.EditorInfo
import com.zibashu.keyline.dictionary.Dictionary
import com.zibashu.keyline.input.InputController
import com.zibashu.keyline.language.EnglishProvider
import com.zibashu.keyline.language.LanguageRegistry
import com.zibashu.keyline.settings.KeylineSettingsStore
import android.inputmethodservice.InputMethodService

class KeylineImeService : InputMethodService() {
    private lateinit var store: KeylineSettingsStore
    private lateinit var registry: LanguageRegistry
    private lateinit var host: KeyboardHostView
    private var controller: InputController? = null
    private var editor: InputConnectionEditor? = null

    private val prefsListener = SharedPreferences.OnSharedPreferenceChangeListener { _, _ ->
        reloadChrome()
    }

    override fun onCreate() {
        setTheme(android.R.style.Theme_DeviceDefault_InputMethod)
        super.onCreate()
        store = KeylineSettingsStore(this)
        val dictionary = loadDictionary()
        registry = LanguageRegistry(listOf(EnglishProvider(dictionary)))
        store.register(prefsListener)
    }

    override fun onDestroy() {
        store.unregister(prefsListener)
        if (::host.isInitialized) host.dismissPopup()
        super.onDestroy()
    }

    override fun onCreateInputView(): View {
        host = KeyboardHostView(this)
        host.layoutParams = ViewGroup.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.WRAP_CONTENT,
        )
        reloadChrome()
        return host
    }

    override fun onStartInput(attribute: EditorInfo?, restarting: Boolean) {
        super.onStartInput(attribute, restarting)
        bind(attribute, restarting)
    }

    override fun onStartInputView(info: EditorInfo?, restarting: Boolean) {
        super.onStartInputView(info, restarting)
        bind(info, restarting)
        reloadChrome()
        setInputView(host)
    }

    override fun onFinishInputView(finishingInput: Boolean) {
        host.dismissPopup()
        controller?.onHide()
        super.onFinishInputView(finishingInput)
    }

    override fun onFinishInput() {
        controller?.onHide()
        super.onFinishInput()
    }

    override fun onEvaluateFullscreenMode(): Boolean = false

    override fun onEvaluateInputViewShown(): Boolean {
        super.onEvaluateInputViewShown()
        return true
    }

    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        if (::host.isInitialized) {
            reloadChrome()
            setInputView(host)
        }
    }

    private fun bind(info: EditorInfo?, restarting: Boolean) {
        val editorInfo = info ?: EditorInfo()
        val connectionEditor = editor ?: InputConnectionEditor(
            connection = { currentInputConnection },
            editorInfo = editorInfo,
        )
        connectionEditor.editorInfo = editorInfo
        editor = connectionEditor

        val settings = store.load()
        val language = registry.get(settings.languageId)
        val existing = controller
        if (existing == null) {
            val next = InputController(
                editor = connectionEditor,
                language = language,
                settings = settings,
            )
            controller = next
            if (::host.isInitialized) host.bindController(next)
        } else {
            existing.settings = settings
        }
        controller?.onStartInput(restarting)
        if (::host.isInitialized) {
            host.bindController(controller)
        }
    }

    private fun reloadChrome() {
        if (!::host.isInitialized) return
        val snapshot = store.load()
        controller?.settings = snapshot
        host.applyChrome(snapshot, isSystemDark())
        host.bindController(controller)
    }

    private fun isSystemDark(): Boolean {
        val night = resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK
        return night == Configuration.UI_MODE_NIGHT_YES
    }

    private fun loadDictionary(): Dictionary {
        return try {
            assets.open("en_dict.txt").bufferedReader().use { reader ->
                Dictionary.fromLines(reader.readText())
            }
        } catch (_: Exception) {
            Dictionary.fromLines(EnglishProvider.FALLBACK_DICT)
        }
    }
}
