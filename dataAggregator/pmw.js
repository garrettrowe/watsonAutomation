const express = require('express');
const { createProxyMiddleware, responseInterceptor } = require('http-proxy-middleware');
var myArgs = process.argv.slice(2);
const url = new URL(myArgs[0]);
const uReg = new RegExp(url.origin, 'gim');
const app = express();

const options = {
  target: url.origin,
  changeOrigin: true,
  ws: true,
  selfHandleResponse: true,
  onProxyRes: responseInterceptor(async (responseBuffer, proxyRes, req, res) => {
    res.header("Access-Control-Allow-Origin", "*");
    res.header("Content-Security-Policy", " frame-ancestors https://*.daidemos.com");
    res.header("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept");
    res.statusCode = 200;
    const response = responseBuffer.toString('utf8'); // convert buffer to string
    return response.replace(uReg, "").replace(/target="_blank"/gim , "");
  }),
};
const ep = createProxyMiddleware(options);

app.use(function(req, res, next) {
  res.header("Access-Control-Allow-Origin", "*");
  res.header("Content-Security-Policy", " frame-ancestors https://*.daidemos.com");
  res.header("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept");
  next();
});
app.use('/', ep);
app.listen(3001);
