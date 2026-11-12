const express = require('express');
const cors = require('cors');
const products = require('./data/products.json');

const app = express();
app.disable('x-powered-by');

// Flutter web uses a variable local port. Native mobile clients do not use CORS.
// Only local browser origins are allowed; credentials are not enabled.
app.use(cors({
  origin(origin, callback) {
    const localOrigin = /^http:\/\/(localhost|127\.0\.0\.1|\[::1\])(:\d+)?$/;
    callback(null, !origin || localOrigin.test(origin));
  },
  methods: ['GET', 'HEAD', 'OPTIONS'],
}));

app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

app.get('/api/products', (req, res) => {
  // Keep the wrapper expected by the existing Flutter ProductApiImpl.
  res.json({ products, total: products.length });
});

app.get('/api/products/:id', (req, res) => {
  if (!/^[1-9]\d*$/.test(req.params.id) ||
      !Number.isSafeInteger(Number(req.params.id))) {
    return res.status(400).json({ error: 'Product ID must be a positive integer' });
  }

  const product = products.find((item) => item.id === Number(req.params.id));
  if (!product) {
    return res.status(404).json({ error: 'Product not found' });
  }
  res.json(product);
});

app.use((req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

module.exports = app;
