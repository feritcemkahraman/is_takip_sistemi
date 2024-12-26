const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const upload = require('../middleware/upload');
const fs = require('fs');
const path = require('path');

// Dosya yükleme klasörünü oluştur
const uploadDir = 'uploads';
if (!fs.existsSync(uploadDir)) {
    fs.mkdirSync(uploadDir);
}

// Dosya yükle
router.post('/', auth, upload.single('file'), async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ error: 'Dosya yüklenemedi' });
        }
        
        const fileInfo = {
            filename: req.file.filename,
            originalname: req.file.originalname,
            path: req.file.path,
            size: req.file.size,
            mimetype: req.file.mimetype
        };
        
        res.status(201).json(fileInfo);
    } catch (error) {
        console.error('Dosya yükleme hatası:', error);
        res.status(500).json({ error: 'Dosya yüklenemedi' });
    }
});

// Çoklu dosya yükle
router.post('/multiple', auth, upload.array('files', 5), async (req, res) => {
    try {
        if (!req.files || req.files.length === 0) {
            return res.status(400).json({ error: 'Dosyalar yüklenemedi' });
        }
        
        const filesInfo = req.files.map(file => ({
            filename: file.filename,
            originalname: file.originalname,
            path: file.path,
            size: file.size,
            mimetype: file.mimetype
        }));
        
        res.status(201).json(filesInfo);
    } catch (error) {
        console.error('Dosya yükleme hatası:', error);
        res.status(500).json({ error: 'Dosyalar yüklenemedi' });
    }
});

// Dosyayı indir
router.get('/:filename', auth, (req, res) => {
    try {
        const filePath = path.join(uploadDir, req.params.filename);
        
        if (!fs.existsSync(filePath)) {
            return res.status(404).json({ error: 'Dosya bulunamadı' });
        }
        
        res.download(filePath);
    } catch (error) {
        console.error('Dosya indirme hatası:', error);
        res.status(500).json({ error: 'Dosya indirilemedi' });
    }
});

// Dosyayı sil
router.delete('/:filename', auth, (req, res) => {
    try {
        const filePath = path.join(uploadDir, req.params.filename);
        
        if (!fs.existsSync(filePath)) {
            return res.status(404).json({ error: 'Dosya bulunamadı' });
        }
        
        fs.unlinkSync(filePath);
        res.json({ message: 'Dosya başarıyla silindi' });
    } catch (error) {
        console.error('Dosya silme hatası:', error);
        res.status(500).json({ error: 'Dosya silinemedi' });
    }
});

module.exports = router; 