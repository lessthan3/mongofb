window.db = new mongofb.Database '/api/v2'
window.cookies = db.collection 'cookies'

cookies.insert {type: 'chocolate'}, (err, cookie) ->
  throw err if err
  window.cookie = cookie

  cookie.on 'update', (val) ->
    console.log 'cookie updated to', val

  ref = cookie.get 'type'
  ref.on 'update', (val) ->
    console.log 'cookie.type updated to', val

  ref.set 'peanut butter'

