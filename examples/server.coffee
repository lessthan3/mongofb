express = require 'express'
mongofb = require '../lib/index'
wrap = require 'asset-wrap'

app = express()

mongofb app, {
  firebase:
    url: 'https://vn42xl9zsez.firebaseio-demo.com/'
  mongodb:
    host: 'localhost'
    port: 27017
  root: '/api/v1'
}
app.get '/', (req, res) ->
  res.send """
  <html>
    <body>
      <script type='text/javascript' src='http://cdnjs.cloudflare.com/ajax/libs/jquery/2.0.2/jquery.min.js'></script>
      <script type='text/javascript' src='https://cdn.firebase.com/v0/firebase.js'></script>
      <script type='text/javascript' src='/api/v2/mongofb.js'></script>
      <script type='text/javascript' src='/demo-client.js'></script>
    </body>
  </html>
  """

app.get "/demo-client.js", (req, res, next) ->
  asset = new wrap.Snockets {
    src: 'client.coffee'
  }, (err) ->
    return res.send 500, err if err
    res.send asset.data
app.listen 3000
