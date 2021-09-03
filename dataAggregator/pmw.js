const express = require('express');
const { createProxyMiddleware, responseInterceptor } = require('http-proxy-middleware');
var myArgs = process.argv.slice(2);
const url = new URL(myArgs[0]);
const uReg = new RegExp(url.origin, 'gim');
const app = express();

function onProxyRes(proxyRes, req, res) {
  delete proxyRes.headers['content-security-policy'];
  delete proxyRes.headers['link'];
  delete proxyRes.headers['strict-transport-security'];
  delete proxyRes.headers['x-frame-options'];
  delete proxyRes.headers['x-xss-protection'];
  delete proxyRes.headers['x-content-type-options'];
  delete proxyRes.headers['Access-Control-Allow-Headers'];
  proxyRes.headers['Access-Control-Allow-Origin'] = '*'; 
}

const options = {
  target: url.origin,
  changeOrigin: true,
  ws: true,
  selfHandleResponse: true,
  onProxyRes: responseInterceptor(async (responseBuffer, proxyRes, req, res) => {
    const response = responseBuffer.toString('utf8'); // convert buffer to string
    return response.replace(uReg, "");
  }),
};
const ep = createProxyMiddleware(options);

app.use(function(req, res, next) {
  res.header("Access-Control-Allow-Origin", "*");
  res.header("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept");
  next();
});
app.use('/', ep);
app.listen(3001);
