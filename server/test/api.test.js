const { test, before, after } = require('node:test');
const assert = require('node:assert/strict');
const { once } = require('node:events');
const app = require('../app');
const products = require('../data/products.json');

let server;
let baseUrl;

before(async () => {
  server = app.listen(0, '127.0.0.1');
  await once(server, 'listening');
  baseUrl = `http://127.0.0.1:${server.address().port}`;
});

after(async () => {
  if (server) await new Promise((resolve, reject) => {
    server.close((error) => error ? reject(error) : resolve());
    server.closeIdleConnections();
  });
});

test('GET /health returns a healthy JSON response', async () => {
  const response = await fetch(`${baseUrl}/health`);
  assert.equal(response.status, 200);
  assert.match(response.headers.get('content-type'), /application\/json/);
  assert.deepEqual(await response.json(), { status: 'ok' });
});

test('GET /api/products returns the Flutter-compatible wrapper and local data', async () => {
  const response = await fetch(`${baseUrl}/api/products`);
  assert.equal(response.status, 200);
  assert.deepEqual(await response.json(), { products, total: products.length });
  assert.ok(products.length >= 8);
});

test('every product can be fetched individually', async () => {
  for (const product of products) {
    const response = await fetch(`${baseUrl}/api/products/${product.id}`);
    assert.equal(response.status, 200);
    assert.deepEqual(await response.json(), product);
  }
});

test('unknown product and route return JSON 404 responses', async () => {
  for (const [path, message] of [
    ['/api/products/999999', 'Product not found'],
    ['/missing', 'Route not found'],
  ]) {
    const response = await fetch(`${baseUrl}${path}`);
    assert.equal(response.status, 404);
    assert.deepEqual(await response.json(), { error: message });
  }
});

test('invalid product IDs return 400', async () => {
  for (const id of ['abc', '0', '-1', '1.5', '1abc', '9007199254740992']) {
    const response = await fetch(`${baseUrl}/api/products/${id}`);
    assert.equal(response.status, 400, id);
    assert.equal(typeof (await response.json()).error, 'string');
  }
});

test('CORS allows local web origins and denies external browser origins', async () => {
  for (const origin of ['http://localhost:53001', 'http://127.0.0.1:8080', 'http://[::1]:8080']) {
    const response = await fetch(`${baseUrl}/api/products`, { headers: { Origin: origin } });
    assert.equal(response.headers.get('access-control-allow-origin'), origin);
    assert.equal(response.headers.get('access-control-allow-credentials'), null);
  }
  const response = await fetch(`${baseUrl}/api/products`, {
    headers: { Origin: 'https://example.com' },
  });
  assert.equal(response.headers.get('access-control-allow-origin'), null);
});

test('local browser preflight is supported', async () => {
  const response = await fetch(`${baseUrl}/api/products`, {
    method: 'OPTIONS',
    headers: { Origin: 'http://localhost:8080', 'Access-Control-Request-Method': 'GET' },
  });
  assert.equal(response.status, 204);
  assert.equal(response.headers.get('access-control-allow-origin'), 'http://localhost:8080');
  assert.equal(response.headers.get('access-control-allow-methods'), 'GET,HEAD,OPTIONS');
});

test('sample data contains every field and nested type required by Product.fromJson', () => {
  assert.equal(new Set(products.map((product) => product.id)).size, products.length);
  for (const product of products) {
    for (const key of ['id', 'stock', 'minimumOrderQuantity']) {
      assert.ok(Number.isInteger(product[key]), key);
    }
    for (const key of ['price', 'discountPercentage', 'rating', 'weight']) {
      assert.equal(typeof product[key], 'number', key);
      assert.ok(Number.isFinite(product[key]), key);
    }
    for (const key of ['title', 'description', 'category', 'brand', 'sku',
      'warrantyInformation', 'shippingInformation', 'availabilityStatus', 'returnPolicy', 'thumbnail']) {
      assert.equal(typeof product[key], 'string', key);
      assert.ok(product[key].length > 0, key);
    }
    for (const key of ['tags', 'images']) {
      assert.ok(Array.isArray(product[key]) && product[key].length > 0, key);
      assert.ok(product[key].every((value) => typeof value === 'string'), key);
    }
    for (const key of ['width', 'height', 'depth']) {
      assert.equal(typeof product.dimensions[key], 'number', key);
    }
    assert.ok(Array.isArray(product.reviews) && product.reviews.length > 0);
    for (const review of product.reviews) {
      assert.ok(Number.isInteger(review.rating));
      for (const key of ['comment', 'reviewerName', 'reviewerEmail', 'date']) {
        assert.equal(typeof review[key], 'string', key);
      }
      assert.ok(Number.isFinite(Date.parse(review.date)));
    }
    for (const key of ['createdAt', 'updatedAt', 'barcode', 'qrCode']) {
      assert.equal(typeof product.meta[key], 'string', key);
    }
    assert.ok(Number.isFinite(Date.parse(product.meta.createdAt)));
    assert.ok(Number.isFinite(Date.parse(product.meta.updatedAt)));
  }
});
