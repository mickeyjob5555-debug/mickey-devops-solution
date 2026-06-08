'use strict';

// Minimal synthetic API service for the DevOps practical test.
// It exposes:
//   GET /        -> liveness-ish "hello"
//   GET /healthz -> readiness: actually pings MongoDB and fails if unreachable
//
// Configuration is read from the environment. The interesting bit for the test
// is that /healthz performs a real round-trip to Mongo, so a deployment is only
// truly "Ready" when the DB wiring (connection string, auth, replica set) is correct.

const http = require('http');
const { MongoClient } = require('mongodb');

const PORT = parseInt(process.env.PORT || '3000', 10);
const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017';
const MONGO_DB = process.env.MONGO_DB || 'api_service';

// A single shared client. Connection options (pool size, timeouts) are
// intentionally minimal here — tuning them is part of the exercise.
let client;
async function getClient() {
  if (!client) {
    client = new MongoClient(MONGO_URI);
    await client.connect();
  }
  return client;
}

async function pingMongo() {
  const c = await getClient();
  await c.db(MONGO_DB).command({ ping: 1 });
}

const server = http.createServer(async (req, res) => {
  if (req.url === '/healthz') {
    try {
      await pingMongo();
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ status: 'ok', db: 'reachable' }));
    } catch (err) {
      res.writeHead(503, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ status: 'degraded', db: String(err && err.message) }));
    }
    return;
  }

  res.writeHead(200, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify({ service: 'api-service', message: 'hello' }));
});

server.listen(PORT, () => {
  // eslint-disable-next-line no-console
  console.log(`api-service listening on :${PORT}`);
});
