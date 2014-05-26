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


  window.chocolate_cookies = new mongofb.PseudoCollection db, 'cookies', {
    type: 'chocolate'
  }
  console.log 'looking for chocolate cookies'
  chocolate_cookies.findOne {}, (err, cookie) ->
    throw err if err
    console.log cookie

    console.log 'inserting chocolate cookie'
    chocolate_cookies.insert {}, (err, cookie) ->
      throw err if err
      console.log 'inserted chocolate cookie', cookie
