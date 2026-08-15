package com.zibashu.morphos

import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification

class MorphNotificationListener : NotificationListenerService() {
    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        if (sbn == null) return
        MorphNotificationStore.upsert(sbn)
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        if (sbn == null) return
        MorphNotificationStore.remove(sbn.key)
    }

    override fun onListenerConnected() {
        try {
            activeNotifications?.forEach { MorphNotificationStore.upsert(it) }
        } catch (_: Exception) {
        }
    }
}
