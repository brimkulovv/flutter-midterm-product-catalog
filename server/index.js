const app = require('./app');

const port = Number(process.env.PORT || 3000);
if (!Number.isInteger(port) || port < 1 || port > 65535) {
  throw new Error('PORT must be an integer between 1 and 65535');
}

// Listen on all interfaces so an Android emulator or a phone on the LAN can connect.
const server = app.listen(port, '0.0.0.0', () => {
  console.log(`Product API running at http://localhost:${port}`);
});

server.on('error', (error) => {
  console.error(`Unable to start Product API: ${error.message}`);
  process.exitCode = 1;
});
