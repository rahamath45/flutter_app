require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// PostgreSQL connection with SSL (required by Railway)
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: {
    rejectUnauthorized: false,
  },
});

// Auto-create users table on startup
async function initDatabase() {
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        name VARCHAR(255),
        age INTEGER NOT NULL,
        gender VARCHAR(50) NOT NULL,
        location VARCHAR(255) NOT NULL,
        contact VARCHAR(100) NOT NULL,
        password VARCHAR(255) NOT NULL,
        device_id VARCHAR(255) UNIQUE NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    console.log('✅ Users table ready');
  } catch (err) {
    console.error('❌ Failed to create users table:', err.message);
  }
}

// Health check
app.get('/', (req, res) => {
  res.json({ message: 'Home Remedies API Running!' });
});

// GET /api/users → List all users (debug endpoint)
app.get('/api/users', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM users ORDER BY created_at DESC');
    res.status(200).json({ success: true, count: result.rows.length, users: result.rows });
  } catch (err) {
    console.error('❌ List users error:', err.message);
    res.status(500).json({ error: 'Failed to list users' });
  }
});

// POST /api/save-user → Insert or update user by device_id
app.post('/api/save-user', async (req, res) => {
  const { name, age, gender, location, contact, password, device_id } = req.body;

  // Validate required fields
  if (!age || !gender || !location || !contact || !password || !device_id) {
    return res.status(400).json({ error: 'Missing required fields' });
  }

  try {
    const result = await pool.query(
      `INSERT INTO users (name, age, gender, location, contact, password, device_id)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       ON CONFLICT (device_id) DO UPDATE SET
         name = EXCLUDED.name,
         age = EXCLUDED.age,
         gender = EXCLUDED.gender,
         location = EXCLUDED.location,
         contact = EXCLUDED.contact,
         password = EXCLUDED.password
       RETURNING *`,
      [name || null, age, gender, location, contact, password, device_id]
    );

    console.log(`✅ User saved: ${device_id}`);
    res.status(200).json({ success: true, user: result.rows[0] });
  } catch (err) {
    console.error('❌ Save user error:', err.message);
    res.status(500).json({ error: 'Failed to save user' });
  }
});

// GET /api/user/:deviceId → Get user by device_id
app.get('/api/user/:deviceId', async (req, res) => {
  const { deviceId } = req.params;

  try {
    const result = await pool.query(
      'SELECT * FROM users WHERE device_id = $1',
      [deviceId]
    );

    if (result.rows.length > 0) {
      res.status(200).json({ success: true, user: result.rows[0] });
    } else {
      res.status(404).json({ success: false, message: 'User not found' });
    }
  } catch (err) {
    console.error('❌ Get user error:', err.message);
    res.status(500).json({ error: 'Failed to get user' });
  }
});

// DELETE /api/user/:deviceId → Delete user by device_id
app.delete('/api/user/:deviceId', async (req, res) => {
  const { deviceId } = req.params;

  try {
    const result = await pool.query(
      'DELETE FROM users WHERE device_id = $1 RETURNING *',
      [deviceId]
    );

    if (result.rows.length > 0) {
      console.log(`✅ User deleted: ${deviceId}`);
      res.status(200).json({ success: true, message: 'User deleted' });
    } else {
      res.status(404).json({ success: false, message: 'User not found' });
    }
  } catch (err) {
    console.error('❌ Delete user error:', err.message);
    res.status(500).json({ error: 'Failed to delete user' });
  }
});

// POST /api/validate-login → Validate login by contact + password
app.post('/api/validate-login', async (req, res) => {
  const { contact, password, device_id } = req.body;

  if (!contact || !password || !device_id) {
    return res.status(400).json({ error: 'Missing required fields' });
  }

  try {
    const result = await pool.query(
      'SELECT * FROM users WHERE contact = $1 AND password = $2',
      [contact, password]
    );

    if (result.rows.length > 0) {
      // Update device_id for the matched user
      await pool.query(
        'UPDATE users SET device_id = $1 WHERE contact = $2',
        [device_id, contact]
      );

      const updatedUser = { ...result.rows[0], device_id };
      console.log(`✅ Login validated: ${contact}`);
      res.status(200).json({ success: true, user: updatedUser });
    } else {
      res.status(401).json({ success: false, message: 'Invalid credentials' });
    }
  } catch (err) {
    console.error('❌ Validate login error:', err.message);
    res.status(500).json({ error: 'Failed to validate login' });
  }
});

// Start server
initDatabase().then(() => {
  app.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 Home Remedies API running on port ${PORT}`);
  });
});
