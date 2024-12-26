const express = require('express');
const router = express.Router();
const Message = require('../models/message');
const User = require('../models/user');
const auth = require('../middleware/auth');

// Kullanıcının tüm mesajlarını getir
router.get('/', auth, async (req, res) => {
    try {
        const messages = await Message.find({
            $or: [
                { sender: req.user.userId },
                { receiver: req.user.userId }
            ]
        })
        .populate('sender', 'username email')
        .populate('receiver', 'username email')
        .sort({ createdAt: -1 });
        
        res.json(messages);
    } catch (error) {
        console.error('Mesaj listesi hatası:', error);
        res.status(500).json({ error: 'Mesajlar getirilemedi' });
    }
});

// İki kullanıcı arasındaki mesajları getir
router.get('/:userId', auth, async (req, res) => {
    try {
        const messages = await Message.find({
            $or: [
                { sender: req.user.userId, receiver: req.params.userId },
                { sender: req.params.userId, receiver: req.user.userId }
            ]
        })
        .populate('sender', 'username email')
        .populate('receiver', 'username email')
        .sort({ createdAt: 1 });
        
        // Okunmamış mesajları okundu olarak işaretle
        await Message.updateMany(
            {
                sender: req.params.userId,
                receiver: req.user.userId,
                read: false
            },
            { read: true }
        );
        
        res.json(messages);
    } catch (error) {
        console.error('Mesaj listesi hatası:', error);
        res.status(500).json({ error: 'Mesajlar getirilemedi' });
    }
});

// Yeni mesaj gönder
router.post('/', auth, async (req, res) => {
    try {
        const { receiverId, content } = req.body;
        
        // Alıcının varlığını kontrol et
        const receiver = await User.findById(receiverId);
        if (!receiver) {
            return res.status(404).json({ error: 'Alıcı bulunamadı' });
        }
        
        const message = new Message({
            sender: req.user.userId,
            receiver: receiverId,
            content
        });
        
        await message.save();
        
        const populatedMessage = await Message.findById(message._id)
            .populate('sender', 'username email')
            .populate('receiver', 'username email');
        
        // Socket.io ile gerçek zamanlı bildirim gönder
        req.app.get('io').to(`user:${receiverId}`).emit('newMessage', populatedMessage);
        
        res.status(201).json(populatedMessage);
    } catch (error) {
        console.error('Mesaj gönderme hatası:', error);
        res.status(500).json({ error: 'Mesaj gönderilemedi' });
    }
});

// Okunmamış mesaj sayısını getir
router.get('/unread/count', auth, async (req, res) => {
    try {
        const count = await Message.countDocuments({
            receiver: req.user.userId,
            read: false
        });
        
        res.json({ count });
    } catch (error) {
        console.error('Okunmamış mesaj sayısı hatası:', error);
        res.status(500).json({ error: 'Okunmamış mesaj sayısı getirilemedi' });
    }
});

module.exports = router; 