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

// Bildirim gönderme endpoint'i
app.post('/send-notification', async (req, res) => {
  try {
    const { token, title, body, data } = req.body;

    if (!token) {
      console.error('FCM token eksik');
      return res.status(400).json({ 
        success: false, 
        error: 'FCM token gerekli' 
      });
    }

    if (!title || !body) {
      console.error('Başlık veya mesaj içeriği eksik');
      return res.status(400).json({ 
        success: false, 
        error: 'Başlık ve mesaj içeriği gerekli' 
      });
    }

    console.log(`Bildirim gönderiliyor - Token: ${token.substring(0, 10)}...`);
    console.log(`Başlık: ${title}`);
    console.log(`İçerik: ${body}`);
    
    const message = {
      notification: {
        title,
        body,
      },
      data: data || {},
      token,
    };

    const response = await admin.messaging().send(message);
    console.log('Bildirim başarıyla gönderildi:', response);
    
    res.status(200).json({ 
      success: true, 
      messageId: response,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Bildirim gönderme hatası:', error);
    
    // Firebase'den gelen hataları daha detaylı işle
    if (error.code === 'messaging/invalid-argument') {
      return res.status(400).json({
        success: false,
        error: 'Geçersiz bildirim parametreleri',
        details: error.message
      });
    } else if (error.code === 'messaging/invalid-registration-token') {
      return res.status(400).json({
        success: false,
        error: 'Geçersiz FCM token',
        details: error.message
      });
    } else if (error.code === 'messaging/registration-token-not-registered') {
      return res.status(400).json({
        success: false,
        error: 'FCM token artık geçerli değil',
        details: error.message
      });
    }

    res.status(500).json({ 
      success: false, 
      error: 'Bildirim gönderilirken bir hata oluştu',
      details: error.message
    });
  }
});

// Sunucuyu başlat
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Sunucu ${PORT} portunda çalışıyor`);
}); 