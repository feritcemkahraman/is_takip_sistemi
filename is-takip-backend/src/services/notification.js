class NotificationService {
    constructor(io) {
        this.io = io;
    }

    // Görev bildirimi gönder
    sendTaskNotification(userId, notification) {
        this.io.to(`user:${userId}`).emit('taskNotification', notification);
    }

    // Mesaj bildirimi gönder
    sendMessageNotification(userId, notification) {
        this.io.to(`user:${userId}`).emit('messageNotification', notification);
    }

    // Genel bildirim gönder
    sendGeneralNotification(userId, notification) {
        this.io.to(`user:${userId}`).emit('generalNotification', notification);
    }

    // Tüm kullanıcılara bildirim gönder
    sendBroadcastNotification(notification) {
        this.io.emit('broadcastNotification', notification);
    }

    // Görev güncellemesi bildirimi
    sendTaskUpdateNotification(taskId, update) {
        this.io.to(`task:${taskId}`).emit('taskUpdate', update);
    }

    // Yorum bildirimi
    sendCommentNotification(taskId, comment) {
        this.io.to(`task:${taskId}`).emit('newComment', comment);
    }
}

module.exports = NotificationService; 