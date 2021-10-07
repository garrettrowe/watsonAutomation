const express = require('express');
const { createProxyMiddleware, responseInterceptor } = require('http-proxy-middleware');
var myArgs = process.argv.slice(2);
const utarget = myArgs[1];
const lurl = myArgs[0];

const uReg = new RegExp(lurl, 'gim');
const app = express();
var lastHost = "";
var pageHost = "";
var hosts = [];

function onError(err, req, res, target) {
  res.writeHead(500, {
    'Content-Type': 'text/plain',
  });
  res.end('Something went wrong:' + err);
}

JSON.safeStringify = (obj, indent = 2) => {
  let cache = [];
  const retVal = JSON.stringify(
    obj,
    (key, value) =>
      typeof value === "object" && value !== null
        ? cache.includes(value)
          ? undefined 
          : cache.push(value) && value 
        : value,
    indent
  );
  cache = null;
  return retVal;
};

function relayRequestHeaders(proxyReq, req) {
  try{
    Object.keys(req.headers).forEach(function (key) {
      if ( ["user-agent", "cookie", "accept", "accept-language", "content-type", "referer"].includes(key)){
          proxyReq.setHeader(key, req.headers[key]);
          //console.log("req key: " + key + " val: " + req.headers[key]);
        } 
    });
  }catch(f){}
}

const options = {
  target: utarget,
  changeOrigin: true,
  secure: false,
  toProxy: true,
  followRedirects: true,
  proxyTimeout: 12000,
  timeout: 12000,
  onError: onError,
  onProxyReq: relayRequestHeaders,
  ws: true,
  pathRewrite: function (path, req) {   
    for (var i in hosts){
      var aReg = new RegExp("/" + hosts[i], '');
      path = path.replace(aReg, "");
    }
    if(path =="")
      path = "/";

    path = path.replace(uReg, "https://");
    path = path.replace(/\/+/gm, "/");
    path = path.replace(/(%22)*"*$/, "");
    return path;
  },
  router: function(req) {
    var a = req.url.replace("/","").replace(/[\/\?].*/gi,"");
    if (req.headers && req.headers.referer && !a.includes(".")){
      a = req.headers.referer.replace(/https?:\/\/.*?\//,"").replace(/\/.*/gi,"");
    }
    if (a.trim() == "" || !a.includes(".")){
      a = lastHost;
    }else{
      lastHost = a;
      hosts.push(a);
      hosts = [...new Set(hosts)];
    }
    return 'https://' + a;
  },
  selfHandleResponse: true,
  onProxyRes: responseInterceptor(async (responseBuffer, proxyRes, req, res) => {
    try{
      Object.keys(proxyRes.headers).forEach(function (key) {
        if (  ["user-agent", "cookie", "accept", "accept-language", "content-type", "location","referer"].includes(key)){
          res.header(key, proxyRes.headers[key]);
        }
      });
      res.header("Access-Control-Allow-Origin", "*");
      res.header("Content-Security-Policy", "default-src *  data: blob: filesystem: about: ws: wss: 'unsafe-inline' 'unsafe-eval' 'unsafe-dynamic'; script-src * data: blob: 'unsafe-inline' 'unsafe-eval'; connect-src * data: blob: 'unsafe-inline'; img-src * data: blob: 'unsafe-inline'; frame-src * data: blob: ; style-src * data: blob: 'unsafe-inline'; font-src * data: blob: 'unsafe-inline'; frame-ancestors * data: blob: 'unsafe-inline';"); 
      res.header("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept");

      var t = proxyRes.headers["location"];
      if (t != undefined) {
        var tul = new URL(t);
        const tulReg = new RegExp(tul.origin, 'gim')
        res.header("location", t.replace(/https?:\/\//gim, lurl));
      }
      var response = responseBuffer.toString('utf8'); 
      var rUrl = new URL("https://" + lastHost);

      if(proxyRes.headers["content-type"].includes("text")){
        rUrl = new URL(proxyRes.responseUrl);
        pageHost = rUrl.host;
        response = response.replace(/https?:\/\//gim, lurl);
        //response = response.replace(/target="_blank"/gim , "");
        response = response.replace(/href *= *"\/\//gim , 'href="' + lurl);
        response = response.replace(/url\(\/\//gim, "url(" + lurl);
        response = response.replace(/src *= *"\/\//gim, "src=" + lurl);
        response = response.replace(/href *= *"\//gim , 'href="' + lurl + rUrl.host.replace(/\/$/,"") + "/");
        response = response.replace(/url\(\//gim, "url(" + lurl + rUrl.host.replace(/\/$/,"") + "/");
        response = response.replace(/src *= *"\//gim, "src=" + lurl + rUrl.host.replace(/\/$/,"") + "/");
        return response;
      }
    }catch(f){
    }
    return responseBuffer;
  }),
};
const ep = createProxyMiddleware(options);

app.use(function(req, res, next) {
  next();
});
app.use('/', ep);
app.listen(3001);
