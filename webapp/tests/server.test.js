const request = require('supertest');
const app = require('../server');

describe('Web server', () => {
  it('should return index.html content', async () => {
    const res = await request(app).get('/');
    expect(res.statusCode).toBe(200);
    expect(res.text).toContain('<!DOCTYPE html>');
  });
});
