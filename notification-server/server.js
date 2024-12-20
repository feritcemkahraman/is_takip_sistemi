const express = require('express');
const admin = require('firebase-admin');
const cors = require('cors');
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

// Middleware
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
    res.status(200).json({ success: true, messageId: response });
  } catch (error) {
    console.error('Bildirim gönderilirken hata oluştu:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Sunucu ${PORT} portunda çalışıyor`);
}); 