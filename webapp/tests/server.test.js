const request = require('supertest');
const app = require('../app'); // note: import app, not server
let server;

beforeAll(() => {
  server = app.listen(3000); // start server for test
});

afterAll(() => {
  server.close(); // close server after test
});

describe('Web server', () => {
  it('should return index.html content', async () => {
    const res = await request(server).get('/');
    expect(res.statusCode).toBe(200);
    expect(res.text).toContain('<!DOCTYPE html>'); // simple check
  });
});
