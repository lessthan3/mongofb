_ = require 'underscore'
Firebase = require 'firebase'
FirebaseTokenGenerator = require 'firebase-token-generator'
LRU = require 'lru-cache'
merge = require 'deepmerge'
mongodb = require 'mongodb'
wrap = require 'asset-wrap'

module.exports = (app, config, next) ->

  # configuration
  config = merge {
    root: '/api'
    cache:
      max: 100
      maxAge: 1000*60*5
    firebase:
      url: 'https://vn42xl9zsez.firebaseio-demo.com/'
    mongodb:
      db: 'test'
      host: 'localhost'
      pass: ''
      port: 27017
      user: 'admin'
      options:
        db:
          native_parser: false
        server:
          auto_reconnect: true
          poolSize: 1
          socketOptions:
            keepAlive: 120
  }, config

  # connect to mongodb
  m = config.mongodb
  url = "mongodb://#{m.user}:#{m.pass}@#{m.host}:#{m.port}/#{m.db}"
  url = url.replace ':@', '@'
  mongodb.MongoClient.connect url, m.options, (err, db) ->
    return next err if err

    # connect to firebase
    fb = new Firebase config.firebase.url
    token_generator = new FirebaseTokenGenerator config.firebase.secret
    token = token_generator.createToken {}, {
      expires: new Date('2020-01-01 00:00:00 UTC').getTime()
      admin: true
    }
    fb.auth token, ->

      # helpers
      auth = (req, res, next) ->
        if req.query.token
          ref = new Firebase config.firebase.url
          ref.auth req.query.token, (err, user) ->
            delete req.query.token
            req.user = user
            next()
        else
          next()
      
      _cache = new LRU config.cache
      cache = (req, res, fn) ->
        max_age = config.cache.maxAge / 1000
        max_age = 0 if req.query.bust == '1'
        val = 'private, max-age=0, no-cache, no-store, must-revalidate'
        val = "public, max-age=#{max_age}, must-revalidate" if max_age > 0
        res.set 'Cache-Control', val
        key = req.url.replace '&bust=1', ''
        if req.query.bust == '1'
          _cache.del key
          delete req.query.bust
        return res.send _cache.get(key) if _cache.has(key)
        delete req.query._
        fn (data) ->
          _cache.set key, data
          res.send data

      hook = (arg, time, method) ->
        @db = db
        @fb = fb
        fn = config.hooks?[@params.collection]?[time]?[method]
        if fn
          fn.apply @, [arg]
        else
          arg

      # routes
      app.get "#{config.root}/mongofb.js", (req, res, next) ->
        res.header 'Content-Type', 'text/javascript'
        cache req, res, (next) ->
          asset = new wrap.Snockets {
            src: "#{__dirname}/client.coffee"
          }, (err) ->
            return res.send 500, err if err
            next asset.data

      app.get "#{config.root}/Firebase", (req, res, next) ->
        res.send config.firebase.url

      app.get "#{config.root}/ObjectID", (req, res, next) ->
        # TODO: generator ObjectIDs in a better way
        tmp = db.collection 'tmp'
        tmp.insert {}, (err, docs) ->
          id = docs[0]._id
          tmp.remove {_id: id}, (err) ->
            res.send id.toString()

      app.get "#{config.root}/update/:collection/:id*", (req, res, next) ->
        target = unescape(req.params[1]) if req.params[1]
        # TODO: if target, only update that part of the document

        ref = fb.child "#{req.params.collection}/#{req.params.id}"
        ref.once 'value', (snapshot) ->
          collection = db.collection req.params.collection
          qry = {_id: new mongodb.ObjectID req.params.id}
          doc = snapshot.val()
          if doc
            doc._id = qry._id
            opt = {safe: true, upsert: true}
            collection.update qry, doc, opt, (err) ->
              return res.send 500, err if err
              doc = hook.apply req, [doc, 'after', 'find']
              res.send doc
          else
            collection.remove qry, (err) ->
              return res.end 500, err if err
              res.send null

      app.get "#{config.root}/:collection/find", auth, (req, res, next) ->
        cache req, res, (next) ->
          # query
          qry = hook.apply req, [req.query, 'before', 'find']

          # options
          qry.limit ?= 1000
          qry.limit = Math.max qry.limit, 1000
          opt = {limit: qry.limit}
          delete qry.limit

          # run query
          collection = db.collection req.params.collection
          collection.find(qry, opt).toArray (err, docs) ->
            return res.send 500, err if err
            docs = (hook.apply req, [doc, 'after', 'find'] for doc in docs)
            next docs

      app.get "#{config.root}/:collection/findOne*", auth, (req, res, next) ->
        cache req, res, (next) ->
          qry = hook.apply req, [req.query, 'before', 'find']
          collection = db.collection req.params.collection
          collection.findOne qry, (err, doc) ->
            return res.send 500, err if err
            return res.send 404 if not doc
            doc = hook.apply req, [doc, 'after', 'find']
            next doc

      app.get "#{config.root}/:collection/:id*", auth, (req, res, next) ->
        cache req, res, (next) ->
          target = unescape(req.params[1]).replace /\//g, '.' if req.params[1]
          qry = {_id: new mongodb.ObjectID req.params.id}
          prj = {}
          prj[target] = 1 if target

          collection = db.collection req.params.collection
          collection.findOne qry, prj, (err, doc) ->
            return res.send 500, err if err
            return res.send 404 if not doc
            doc = hook.apply req, [doc, 'after', 'find']
            doc = doc?[key] for key in target.split '.' if target
            next doc

      next null, db, fb if next

