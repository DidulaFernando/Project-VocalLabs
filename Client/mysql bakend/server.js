require('dotenv').config();
const express = require('express');
const mysql = require('mysql2');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const cors = require('cors');
const bodyParser = require('body-parser');
const multer = require('multer');
const path = require('path');

const app = express();
app.use(cors());
app.use(bodyParser.json());

// MySQL Database Connection
const db = mysql.createConnection({
    host: process.env.DB_HOST,
    user: process.env.DB_USER,
    password: process.env.DB_PASS,
    database: process.env.DB_NAME
});

db.connect(err => {
    if (err) {
        console.error('Database connection failed:', err);
    } else {
        console.log('Connected to MySQL Database');
    }
});

// Multer configuration to handle audio file uploads
const storage = multer.diskStorage({
    destination: function (req, file, cb) {
        cb(null, 'uploads/'); // Store files in 'uploads' folder
    },
    filename: function (req, file, cb) {
        const fileExtension = path.extname(file.originalname);
        const fileName = Date.now() + fileExtension; // Generate unique file name
        cb(null, fileName);
    }
});

const upload = multer({ storage: storage });

// Login Route
app.post('/api/login', (req, res) => {
    const { email, password } = req.body;

    if (!email || !password) {
        return res.status(400).json({ error: 'Email and password are required' });
    }

    // Check if user exists
    db.query('SELECT * FROM users WHERE email = ?', [email], async (err, results) => {
        if (err) return res.status(500).json({ error: 'Database error' });
        if (results.length === 0) return res.status(401).json({ error: 'Invalid credentials' });

        const user = results[0];

        // Check password
        const isMatch = await bcrypt.compare(password, user.password);
        if (!isMatch) return res.status(401).json({ error: 'Invalid credentials' });

        // Generate JWT Token
        const token = jwt.sign({ id: user.id, email: user.email }, process.env.JWT_SECRET, { expiresIn: '1h' });

        // Return user profile
        res.json({ token, user: { id: user.id, name: user.name, email: user.email } });
    });
});

// Route to upload audio file
app.post('/api/upload-audio', upload.single('audio'), (req, res) => {
    if (!req.file) {
        return res.status(400).json({ error: 'No file uploaded' });
    }

    const audioPath = req.file.path; // Path where the file is stored on the server

    // Assuming the logged-in user is sending the request (authentication should be handled)
    const userId = req.body.userId;

    // Store the audio file path in the database
    db.query('INSERT INTO user_audio (user_id, audio_path) VALUES (?, ?)', [userId, audioPath], (err, results) => {
        if (err) {
            console.error('Error saving audio to database:', err);
            return res.status(500).json({ error: 'Error saving audio to database' });
        }

        res.status(200).json({ message: 'Audio file uploaded successfully', audioId: results.insertId });
    });
});

// Start Server
const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
