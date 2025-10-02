const request = require('supertest');
const app = require('../app'); 
let server;

beforeAll(() => {
  server = app.listen(3000);
});

afterAll(() => {
  server.close();t
});

describe('Web server', () => {
  it('should return index.html content', async () => {
    const res = await request(server).get('/');
    expect(res.statusCode).toBe(200);
    expect(res.text).toContain('<!DOCTYPE html>'); 
  });
});
