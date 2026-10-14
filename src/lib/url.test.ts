import { expect, test } from 'vitest';
import { isValidUrl } from './url';

test('accepts http and https URLs', () => {
  expect(isValidUrl('http://example.com')).toBe(true);
  expect(isValidUrl('https://example.com/path?query=1')).toBe(true);
});

test('rejects malformed URLs', () => {
  expect(isValidUrl('not a url')).toBe(false);
  expect(isValidUrl('')).toBe(false);
});

test('rejects non-http(s) protocols', () => {
  expect(isValidUrl('javascript:alert(1)')).toBe(false);
  expect(isValidUrl('data:text/html,<script>alert(1)</script>')).toBe(false);
  expect(isValidUrl('file:///etc/passwd')).toBe(false);
});
