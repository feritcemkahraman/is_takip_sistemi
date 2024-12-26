const router = require('express').Router();
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const User = require('../models/User');

// Kayıt ol
router.post('/register', async (req, res) => {
    try {
        const { username, password, fullName } = req.body;
        
        // Kullanıcı var mı kontrol et
        const existingUser = await User.findOne({ username });
        if (existingUser) {
            return res.status(400).json({ error: 'Bu kullanıcı adı zaten kullanılıyor' });
        }
        
        // Şifreyi hashle
        const hashedPassword = await bcrypt.hash(password, 10);
        
        // Kullanıcıyı oluştur
        const user = new User({
            username,
            password: hashedPassword,
            fullName
        });
        
        await user.save();
        
        // Token oluştur
        const token = jwt.sign(
            { userId: user._id },
            process.env.JWT_SECRET,
            { expiresIn: '30d' }
        );
        
        res.json({ 
            token, 
            user: { 
                id: user._id, 
                username, 
                fullName 
            } 
        });
    } catch (error) {
        console.error('Kayıt hatası:', error);
        res.status(500).json({ error: 'Kayıt işlemi başarısız' });
    }
});

// Giriş yap
router.post('/login', async (req, res) => {
    try {
        const { username, password } = req.body;
        
        // Kullanıcıyı bul
        const user = await User.findOne({ username });
        if (!user) {
            return res.status(401).json({ error: 'Kullanıcı bulunamadı' });
        }
        
        // Şifreyi kontrol et
        const validPassword = await bcrypt.compare(password, user.password);
        if (!validPassword) {
            return res.status(401).json({ error: 'Geçersiz şifre' });
        }
        
        // Token oluştur
        const token = jwt.sign(
            { userId: user._id },
            process.env.JWT_SECRET,
            { expiresIn: '30d' }
        );
        
        res.json({ 
            token, 
            user: { 
                id: user._id, 
                username, 
                fullName: user.fullName 
            } 
        });
    } catch (error) {
        console.error('Giriş hatası:', error);
        res.status(500).json({ error: 'Giriş işlemi başarısız' });
    }
});

module.exports = router; 