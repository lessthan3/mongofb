window.db = new mongofb.Database {
  server: '/db/1.0'
  firebase: 'https://vn42xl9zsez.firebaseio-demo.com'
}
window.cookies = db.collection 'cookies'

db.cache = false

cookies.insert {type: 'chocolate'}, (err, cookie) ->
  throw err if err
  window.cookie = cookie

  cookie.on 'update', (val) ->
    console.log 'cookie updated to', val

  window.ref = cookie.get 'type'
  ref.on 'update', (val) ->
    console.log 'cookie.type updated to', val

  ref.set "peanut butter: #{Math.random()}"

