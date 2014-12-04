window.db = new mongofb.Database {
  server: '/db/1.0'
  firebase: 'https://vn42xl9zsez.firebaseio-demo.com'
}
window.cookies = db.collection 'cookies'

db.cache = false

# test Collection
cookies.insert {type: 'chocolate'}, (err, cookie) ->
  throw err if err
  window.cookie = cookie

  window.ref = cookie.get 'type'
  ref.on 'update', (val) ->
    console.log 'cookie.type updated to', val

  cookie.on 'update', (val) ->
    console.log 'cookie updated to', val

  ref.set "peanut butter: #{Math.random()}"

  # test PseudoCollection
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

  # test sync queries
  console.log 'sync 1', cookies.find()
  console.log 'sync 2', cookies.find {}
  console.log 'sync 3', cookies.find {}, {type: 1}
  console.log 'sync 4', cookies.find {}, {limit: 1}
  console.log 'sync 5', cookies.find {}, {type: 1}, {limit: 1}

  # test async queries
  cookies.find (err, cookies) ->
    console.log 'async 1', cookies
  cookies.find {}, (err, cookies) ->
    console.log 'async 2', cookies
  cookies.find {}, {type: 1}, (err, cookies) ->
    console.log 'async 3', cookies
  cookies.find {}, {limit: 1}, (err, cookies) ->
    console.log 'async 4', cookies
  cookies.find {}, {type: 1}, {limit: 1}, (err, cookies) ->
    console.log 'async 5', cookies

  ###
  window.ref1 = cookie.get 'test'
  window.ref2 = cookie.get 'test'

  ref1.on 'update', (v) -> console.log 'ref1 on value'
  ref2.on 'update', (v) -> console.log 'ref2 on value'
  ###
