window.db = new mongofb.Database '/api/v2'
window.apps = db.collection 'apps'
window.cookies = db.collection 'cookies'

collectionsTest = ->
  console.log 'insert'
  apps.insert {foo: 'bar'}, (err, app) ->
    console.log err
    console.log app

    console.log 'findById'
    apps.findById app._id, (err, app) ->
      console.log err
      console.log app

      console.log 'findOne'
      apps.findOne {foo: 'bar'}, (err, app) ->
        console.log err
        console.log app

        console.log 'find'
        apps.find {foo: 'bar'}, (err, apps) ->
          console.log err
          console.log apps

documentsTest = ->
  getCookie = (next) ->
    console.log 'find cookie'
    cookies.findOne {owner: 'bryant'}, (err, cookie) ->
      console.log err
      console.log cookie
      return next cookie if cookie
      cookies.insert {owner: 'bryant'}, (err, cookie) ->
        console.log err
        console.log cookie
        next cookie
  getCookie (doc) ->
    window.cookie = doc
    console.log 'got cookie'
    console.log doc.val()
    doc.on 'update', ->
      console.log 'cookie updated'
    ref = doc.get('foo')
    console.log ref.val()
    ref.on 'update', ->
      console.log 'cookie.foo updated'
    ref.set 'bar'

#collectionsTest()
documentsTest()
