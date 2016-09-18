var http = require('http');

http.createServer(function (req, res) {
  console.log("Request", req.url);
  res.writeHead(200, {'Content-Type': 'text/plain'});
  res.end('OK');
}).listen(8080, "0.0.0.0");
