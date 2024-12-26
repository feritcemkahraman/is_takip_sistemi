const express = require('express');
const router = express.Router();
const Task = require('../models/task');
const auth = require('../middleware/auth');

// Tüm görevleri getir
router.get('/', auth, async (req, res) => {
    try {
        const tasks = await Task.find({
            $or: [
                { creator: req.user.userId },
                { assignedTo: req.user.userId }
            ]
        }).populate('creator', 'username email')
          .populate('assignedTo', 'username email')
          .sort({ createdAt: -1 });
        
        res.json(tasks);
    } catch (error) {
        console.error('Görev listesi hatası:', error);
        res.status(500).json({ error: 'Görevler getirilemedi' });
    }
});

// Yeni görev oluştur
router.post('/', auth, async (req, res) => {
    try {
        const { title, description, dueDate, assignedTo, priority } = req.body;
        
        const task = new Task({
            title,
            description,
            dueDate,
            assignedTo,
            priority,
            creator: req.user.userId
        });
        
        await task.save();
        
        const populatedTask = await Task.findById(task._id)
            .populate('creator', 'username email')
            .populate('assignedTo', 'username email');
        
        res.status(201).json(populatedTask);
    } catch (error) {
        console.error('Görev oluşturma hatası:', error);
        res.status(500).json({ error: 'Görev oluşturulamadı' });
    }
});

// Görevi güncelle
router.put('/:id', auth, async (req, res) => {
    try {
        const { title, description, status, dueDate, assignedTo, priority } = req.body;
        
        const task = await Task.findOne({
            _id: req.params.id,
            $or: [
                { creator: req.user.userId },
                { assignedTo: req.user.userId }
            ]
        });
        
        if (!task) {
            return res.status(404).json({ error: 'Görev bulunamadı' });
        }
        
        if (title) task.title = title;
        if (description) task.description = description;
        if (status) task.status = status;
        if (dueDate) task.dueDate = dueDate;
        if (assignedTo) task.assignedTo = assignedTo;
        if (priority) task.priority = priority;
        
        await task.save();
        
        const updatedTask = await Task.findById(task._id)
            .populate('creator', 'username email')
            .populate('assignedTo', 'username email');
        
        res.json(updatedTask);
    } catch (error) {
        console.error('Görev güncelleme hatası:', error);
        res.status(500).json({ error: 'Görev güncellenemedi' });
    }
});

// Görevi sil
router.delete('/:id', auth, async (req, res) => {
    try {
        const task = await Task.findOneAndDelete({
            _id: req.params.id,
            creator: req.user.userId
        });
        
        if (!task) {
            return res.status(404).json({ error: 'Görev bulunamadı' });
        }
        
        res.json({ message: 'Görev başarıyla silindi' });
    } catch (error) {
        console.error('Görev silme hatası:', error);
        res.status(500).json({ error: 'Görev silinemedi' });
    }
});

// Göreve yorum ekle
router.post('/:id/comments', auth, async (req, res) => {
    try {
        const { text } = req.body;
        
        const task = await Task.findOne({
            _id: req.params.id,
            $or: [
                { creator: req.user.userId },
                { assignedTo: req.user.userId }
            ]
        });
        
        if (!task) {
            return res.status(404).json({ error: 'Görev bulunamadı' });
        }
        
        task.comments.push({
            user: req.user.userId,
            text
        });
        
        await task.save();
        
        const updatedTask = await Task.findById(task._id)
            .populate('creator', 'username email')
            .populate('assignedTo', 'username email')
            .populate('comments.user', 'username email');
        
        res.json(updatedTask);
    } catch (error) {
        console.error('Yorum ekleme hatası:', error);
        res.status(500).json({ error: 'Yorum eklenemedi' });
    }
});

module.exports = router; 