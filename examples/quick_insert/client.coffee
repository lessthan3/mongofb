window.db = new mongofb.Database {
  server: '/db/1.0'
  firebase: 'https://vn42xl9zsez.firebaseio-demo.com'
}
window.cookies = db.collection 'cookies'

for i in [0..100]
  ( ->
    now = "#{Date.now()}-#{Math.random()}"
    cookies.database.request 'ObjectID', false, {
      _: now
    }, (err, id) =>
      console.log id, now
  )()
