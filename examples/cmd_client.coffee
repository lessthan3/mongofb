mongofb = require '../lib/server'

db = new mongofb.client.Database {
  server: 'http://localhost:3000/db/1.0'
  firebase: 'https://vn42xl9zsez.firebaseio-demo.com'
}

db.cache = false
db.get("cookies").findOne (err, cookie) ->
  cookie.remove()




