'use strict';
// Chạy thử trên máy: node server.js (dùng đúng các hàm của lib/vnpay.js như trên Vercel)
const http = require('http'), fs = require('fs'), path = require('path');
try {
  for (const l of fs.readFileSync(path.join(__dirname, '.env'), 'utf8').split(/\r?\n/)) {
    const m = l.match(/^\s*([A-Z0-9_]+)\s*=\s*(.*?)\s*$/);
    if (m && !(m[1] in process.env)) process.env[m[1]] = m[2].replace(/^["']|["']$/g, '');
  }
} catch { }
const V = require('./lib/vnpay'), cfgApi = require('./api/config'), PORT = +process.env.PORT || 3000, PUBLIC = path.join(__dirname, 'public');
const ROUTES = {
  'GET /admin': (req, res) => serveStatic(res, '/admin.html'),
  'POST /api/vnpay/create': V.createPayment,
  'GET /vnpay-return': V.vnpayReturn,
  'GET /vnpay-ipn': V.vnpayIpn,
  'GET /api/order': V.order,
  'GET /api/orders': V.order,
  'GET /api/config': cfgApi
};
const MIME = { '.html': 'text/html; charset=utf-8', '.js': 'text/javascript; charset=utf-8', '.css': 'text/css; charset=utf-8', '.svg': 'image/svg+xml', '.png': 'image/png', '.jpg': 'image/jpeg', '.webp': 'image/webp', '.ico': 'image/x-icon' };
function serveStatic(res, pathname) {
  let rel; try { rel = decodeURIComponent(pathname) } catch { rel = '/' }
  if (rel.endsWith('/')) rel += 'index.html';
  const file = path.normalize(path.join(PUBLIC, rel));
  const send = (f, code) => fs.readFile(f, (e, data) => {
    if (e) { res.writeHead(404); return res.end('404') }
    res.writeHead(code, { 'Content-Type': MIME[path.extname(f)] || 'application/octet-stream', 'Cache-Control': 'no-cache' }); res.end(data) });
  if (!file.startsWith(PUBLIC + path.sep)) return send(path.join(PUBLIC, '404.html'), 404);
  fs.stat(file, (e, st) => e || !st.isFile() ? send(path.join(PUBLIC, '404.html'), 404) : send(file, 200));
}
http.createServer(async (req, res) => {
  const u = new URL(req.url, 'http://' + (req.headers.host || 'localhost')); req.query = Object.fromEntries(u.searchParams);
  // Hỗ trợ /api/orders/:ref
  if (req.method === 'GET' && u.pathname.startsWith('/api/orders/')) {
    const ref = u.pathname.replace('/api/orders/', '');
    if (ref) req.query.ref = ref;
    try { return await V.order(req, res); } catch (e) { console.error(e); res.statusCode = 500; return res.end('{"error":"Lỗi máy chủ."}'); }
  }
  const h = ROUTES[req.method + ' ' + u.pathname];
  try { if (h) return await h(req, res) } catch (e) { console.error(e); res.statusCode = 500; return res.end('{"error":"Lỗi máy chủ."}') }
  if (req.method === 'GET' || req.method === 'HEAD') return serveStatic(res, u.pathname);
  res.statusCode = 405; res.end();
}).listen(PORT, () => console.log(`Astro Cinema chạy thử tại http://localhost:${PORT}`));
