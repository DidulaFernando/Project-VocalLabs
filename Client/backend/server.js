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



// User Login Route
app.post('/login', (req, res) => {
    const { email, password } = req.body;
  
    const sql = 'SELECT * FROM users WHERE email = ?';
    db.query(sql, [email], (err, results) => {
      if (err) return res.status(500).send('Database error');
      if (results.length === 0) return res.status(404).send('User not found');
  
      const user = results[0];
      console.log("Stored Password in DB:", user.password);
      console.log("Entered Password:", password);
  
      const passwordIsValid = bcrypt.compareSync(password, user.password);
      console.log("Password Match:", passwordIsValid);
  
      if (!passwordIsValid) return res.status(401).send('Invalid password');
  
      const token = jwt.sign({ id: user.id }, 'secret', { expiresIn: 86400 });
      res.send({ auth: true, token });
    });
  });

// Start Server
app.listen(port, () => {
  console.log(`🚀 Server running on port ${port}`);
});
