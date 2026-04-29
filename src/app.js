const express = require('express');
const app = express();

app.use(express.json());

// Health check — required by ALB target group
app.get('/health', (req, res) => {
  res.json({ status: 'ok', version: process.env.APP_VERSION || '1.0.0' });
});

// Main API route
app.get('/api', (req, res) => {
  res.json({
    message: 'CI/CD Pipeline Demo API',
    environment: process.env.NODE_ENV,
    timestamp: new Date().toISOString()
  });
});

module.exports = app;