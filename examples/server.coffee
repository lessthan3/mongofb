express = require 'express'
mongofb = require '../lib/server'
wrap = require 'asset-wrap'

app = express()
app.use mongofb {
  firebase:
    url: 'https://vn42xl9zsez.firebaseio-demo.com/'
  mongodb:
    host: 'localhost'
    port: 27017
  root: '/api/v2'
}
app.get '/', (req, res) ->
  asset = new wrap.Snockets {
    src: "#{__dirname}/client.coffee"
  }, (err) ->
    return res.send 500, err if err
    res.send """
    <html>
      <body>
        <div>
          <pre>
            #{asset.data}
          </pre>
        </div>
        <script type='text/javascript' src='http://cdnjs.cloudflare.com/ajax/libs/jquery/2.0.2/jquery.min.js'></script>
        <script type='text/javascript' src='https://cdn.firebase.com/v0/firebase.js'></script>
        <script type='text/javascript' src='/api/v2/mongofb.js'></script>
        <script type='text/javascript'>#{asset.data}</script>
      </body>
    </html>
    """

app.listen 3000
console.log "listening: 3000"
