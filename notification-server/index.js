const express = require('express');
const cors = require('cors');
const admin = require('firebase-admin');
const dotenv = require('dotenv');

// .env dosyasını yükle
dotenv.config();

// Firebase Admin SDK'yı başlat
let serviceAccount;
if (process.env.FIREBASE_SERVICE_ACCOUNT_JSON) {
  serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON);
} else {
  serviceAccount = require('./firebase-service-account.json');
}

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const app = express();

// CORS ve JSON middleware'lerini ekle
app.use(cors());
app.use(express.json());

// Test endpoint'i
app.get('/', (req, res) => {
  res.send('Bildirim sunucusu çalışıyor!');
});

// Anlık mesaj bildirimi gönderme
app.post('/send-chat-notification', async (req, res) => {
  try {
    const { token, sender, message, chatId, messageType } = req.body;

    if (!token || !sender || !message) {
      return res.status(400).json({ 
        success: false, 
        error: 'Eksik parametreler' 
      });
    }

    const notificationData = {
      notification: {
        title: sender,
        body: messageType === 'image' ? '📷 Fotoğraf' : 
              messageType === 'file' ? '📎 Dosya' : 
              messageType === 'voice' ? '🎤 Sesli mesaj' : 
              messageType === 'video' ? '🎥 Video' : message,
        sound: 'default',
        priority: 'high',
        android_channel_id: 'chat_messages'
      },
      data: {
        chatId: chatId || '',
        messageType: messageType || 'text',
        click_action: 'FLUTTER_NOTIFICATION_CLICK'
      },
      android: {
        priority: 'high',
        notification: {
          sound: 'default',
          priority: 'high',
          channelId: 'chat_messages',
          visibility: 'private',
          vibrateTimingsMillis: [200, 500, 200],
          defaultSound: true
        }
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
            'mutable-content': 1,
            'content-available': 1
          }
        }
      },
      token
    };

    const response = await admin.messaging().send(notificationData);
    console.log('Bildirim gönderildi:', response);
    
    res.status(200).json({ 
      success: true, 
      messageId: response 
    });

  } catch (error) {
    console.error('Bildirim hatası:', error);
    
    if (error.code === 'messaging/invalid-registration-token') {
      await handleInvalidToken(token); // Token'ı veritabanından temizle
    }

    res.status(500).json({ 
      success: false, 
      error: error.message 
    });
  }
});

// Toplu bildirim gönderme (grup mesajları için)
app.post('/send-group-notification', async (req, res) => {
  try {
    const { tokens, sender, message, chatId, messageType } = req.body;

    if (!tokens || !tokens.length || !sender || !message) {
      return res.status(400).json({
        success: false,
        error: 'Eksik parametreler'
      });
    }

    const notificationData = {
      notification: {
        title: sender,
        body: messageType === 'image' ? '📷 Fotoğraf' : 
              messageType === 'file' ? '📎 Dosya' : 
              messageType === 'voice' ? '🎤 Sesli mesaj' : 
              messageType === 'video' ? '🎥 Video' : message,
        sound: 'default'
      },
      data: {
        chatId: chatId || '',
        messageType: messageType || 'text',
        click_action: 'FLUTTER_NOTIFICATION_CLICK'
      },
      android: {
        priority: 'high',
        notification: {
          sound: 'default',
          channelId: 'chat_messages',
          visibility: 'private'
        }
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1
          }
        }
      },
      tokens
    };

    const response = await admin.messaging().sendMulticast(notificationData);
    console.log('Grup bildirimi gönderildi:', response);

    res.status(200).json({
      success: true,
      successCount: response.successCount,
      failureCount: response.failureCount
    });

  } catch (error) {
    console.error('Grup bildirim hatası:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Sunucuyu başlat
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Bildirim sunucusu ${PORT} portunda çalışıyor`);
}); 