require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const http = require('http');
const socketIO = require('socket.io');
const path = require('path');

// Services
const NotificationService = require('./services/notification');

// Routes
const authRoutes = require('./routes/auth');
const taskRoutes = require('./routes/tasks');
const messageRoutes = require('./routes/messages');
const uploadRoutes = require('./routes/uploads');

const app = express();
const server = http.createServer(app);
const io = socketIO(server, {
    cors: {
        origin: "*",
        methods: ["GET", "POST"]
    }
});

// Socket.IO'yu Express uygulamasına ekle
app.set('io', io);

// Bildirim servisini oluştur ve Express uygulamasına ekle
const notificationService = new NotificationService(io);
app.set('notifications', notificationService);

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Statik dosya servisi
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

// MongoDB bağlantısı
mongoose.connect(process.env.MONGODB_URI)
    .then(() => console.log('MongoDB bağlantısı başarılı'))
    .catch(err => console.error('MongoDB bağlantı hatası:', err));

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/tasks', taskRoutes);
app.use('/api/messages', messageRoutes);
app.use('/api/uploads', uploadRoutes);

// Socket.IO
io.on('connection', (socket) => {
    console.log('Yeni bağlantı:', socket.id);
    
    // Kullanıcı odası
    socket.on('joinUser', (userId) => {
        socket.join(`user:${userId}`);
        console.log(`Kullanıcı odaya katıldı: user:${userId}`);
    });
    
    // Görev odası
    socket.on('joinTask', (taskId) => {
        socket.join(`task:${taskId}`);
        console.log(`Göreve katıldı: task:${taskId}`);
    });
    
    socket.on('leaveTask', (taskId) => {
        socket.leave(`task:${taskId}`);
        console.log(`Görevden ayrıldı: task:${taskId}`);
    });
    
    // Mesaj yazıyor bildirimi
    socket.on('typing', (data) => {
        socket.to(`user:${data.receiverId}`).emit('userTyping', {
            userId: data.userId,
            typing: data.typing
        });
    });
    
    socket.on('disconnect', () => {
        console.log('Bağlantı koptu:', socket.id);
    });
});

// Error handling
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({ error: 'Bir şeyler ters gitti!' });
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
    console.log(`Server ${PORT} portunda çalışıyor`);
}); 