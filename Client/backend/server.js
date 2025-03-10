const express = require('express');
const mysql = require('mysql');
const bodyParser = require('body-parser');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const cors = require('cors');

const app = express();
const port = 3000;

app.use(bodyParser.json());
app.use(cors());

// Connect to MySQL Database
const db = mysql.createConnection({
  host: 'localhost',
  user: 'root',
  password: 'Oshan12345', // Replace with your MySQL password
  database: 'flutter_auth'
});

db.connect(err => {
  if (err) {
    console.error('MySQL connection failed:', err);
  } else {
    console.log('✅ MySQL Connected...');
  }
});

// User Registration Route
app.post('/register', (req, res) => {
  const { name, email, password } = req.body;
  const hashedPassword = bcrypt.hashSync(password, 8);

  const sql = 'INSERT INTO users (name, email, password) VALUES (?, ?, ?)';
  db.query(sql, [name, email, hashedPassword], (err, result) => {
    if (err) {
      console.error('Error registering user:', err); // Log the error
      return res.status(500).send('Error registering user');
    }
    res.send({ message: 'User registered successfully!' });
  });
});



// Start Server
app.listen(port, () => {
  console.log(`🚀 Server running on port ${port}`);
});
