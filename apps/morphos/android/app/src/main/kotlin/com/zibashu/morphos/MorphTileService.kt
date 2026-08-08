package com.zibashu.morphos

import android.graphics.drawable.Icon
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import android.os.Build

/**
 * Phase 6 — Quick Settings tile: cycle global morph orientation.
 * Modes: sensor → portrait → landscape → reverseLandscape → sensor
 */
class MorphTileService : TileService() {

    override fun onStartListening() {
        super.onStartListening()
        refreshTile()
    }

    override fun onClick() {
        super.onClick()
        val modes = listOf(
            "sensor",
            "portrait",
            "landscape",
            "reverseLandscape",
        )
        val current = MorphOrientationStore.globalMode(this)
        val idx = modes.indexOf(current).let { if (it < 0) 0 else it }
        val next = modes[(idx + 1) % modes.size]
        MorphOrientationStore.setGlobalMode(this, next)
        MorphOrientationStore.setEnabled(this, true)
        MorphOrientationApplier.apply(this, next)
        MorphOrientationService.reapply(this)
        refreshTile()
    }

    private fun refreshTile() {
        val tile = qsTile ?: return
        val mode = MorphOrientationStore.globalMode(this)
        val enabled = MorphOrientationStore.isEnabled(this)
        tile.label = "MorphOS"
        tile.subtitle = if (Build.VERSION.SDK_INT >= 29) {
            if (enabled) mode else "off · $mode"
        } else {
            null
        }
        tile.state = if (enabled) Tile.STATE_ACTIVE else Tile.STATE_INACTIVE
        tile.contentDescription = "MorphOS orientation: $mode"
        try {
            tile.icon = Icon.createWithResource(this, R.mipmap.ic_launcher)
        } catch (_: Exception) {
            // ignore
        }
        tile.updateTile()
    }
}
