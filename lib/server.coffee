# dependencies
express = require 'express'
Firebase = require 'firebase'
FirebaseTokenGenerator = require 'firebase-token-generator'
LRU = require 'lru-cache'
merge = require 'deepmerge'
mongodb = require 'mongodb'
wrap = require 'asset-wrap'


# exports
exports = module.exports = (cfg) ->


  # configuration
  cfg = merge {
    root: '/api'
    cache:
      max: 100
      maxAge: 1000*60*5
    firebase:
      url: 'https://vn42xl9zsez.firebaseio-demo.com/'
      secret: null
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
  }, cfg


  # variables
  db = null
  fb = null


  # connect to firebase and mongodb
  connect = (next) ->
    return next() if db and fb
    m = cfg.mongodb
    url = "mongodb://#{m.user}:#{m.pass}@#{m.host}:#{m.port}/#{m.db}"
    url = url.replace ':@', '@'
    mongodb.MongoClient.connect url, m.options, (err, database) ->
      return next err if err
      db = database
      fb = new Firebase cfg.firebase.url
      if cfg.firebase.secret
        token_generator = new FirebaseTokenGenerator cfg.firebase.secret
        token = token_generator.createToken {}, {
          expires: new Date('2020-01-01 00:00:00 UTC').getTime()
          admin: true
        }
        fb.auth token, (err) ->
          next err
      else
        next()


  # middleware
  (req, res, next) ->
    connect (err) ->
      return next err if err


      # databases
      req.db = db
      req.fb = fb


      # helpers
      auth = (req, res, next) ->
        if req.query.token
          ref = new Firebase cfg.firebase.url
          ref.auth req.query.token, (err, user) ->
            delete req.query.token
            req.user = user
            next()
        else
          next()
      
      _cache = new LRU cfg.cache
      cache = (fn) ->
        max_age = cfg.cache.maxAge / 1000
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

      contentType = (type) ->
        res.set 'Content-Type', type

      hook = (time, method, arg) ->
        fn = cfg.hooks?[req.params.collection]?[time]?[method]
        if fn
          fn.apply req, [arg]
        else
          arg
  

      # routes
      router = new express.Router()


      # client javascript
      router.route 'GET', "#{cfg.root}/mongofb.js", (req, res, next) ->
        contentType 'text/javascript'
        cache (next) ->
          asset = new wrap.Snockets {
            src: "#{__dirname}/client.coffee"
          }, (err) ->
            return res.send 500, err if err
            next asset.data


      # firebase url
      router.route 'GET', "#{cfg.root}/Firebase", (req, res, next) ->
        res.send cfg.firebase.url


      # ObjectID for creating documents
      router.route 'GET', "#{cfg.root}/ObjectID", (req, res, next) ->
        # TODO: generator ObjectIDs in a better way
        tmp = db.collection 'tmp'
        tmp.insert {}, (err, docs) ->
          id = docs[0]._id
          tmp.remove {_id: id}, (err) ->
            res.send id.toString()


      # sync data from firebase
      # db.collection.update
      # db.collection.insert
      # db.collection.remove
      # the format is /sync/:collection/:id and not /:collection/:sync/:id to
      # match firebase urls. the key in firebase is /:collection/:id
      url = "#{cfg.root}/sync/:collection/:id*"
      router.route 'GET', url, auth, (req, res, next) ->
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
              doc = hook 'after', 'find', doc
              res.send doc
          else
            collection.remove qry, (err) ->
              return res.end 500, err if err
              res.send null


      # db.collection.find
      url = "#{cfg.root}/:collection/find"
      router.route 'GET', url, auth, (req, res, next) ->
        cache (next) ->
          # query
          qry = hook 'before', 'find', req.query

          # options
          qry.limit ?= 1000
          qry.limit = Math.max qry.limit, 1000
          opt = {limit: qry.limit}
          delete qry.limit

          # run query
          collection = db.collection req.params.collection
          collection.find(qry, opt).toArray (err, docs) ->
            return res.send 500, err if err
            docs = (hook('after', 'find', doc) for doc in docs)
            next docs


      # db.collection.findOne
      url = "#{cfg.root}/:collection/findOne"
      router.route 'GET', url, auth, (req, res, next) ->
        cache (next) ->
          qry = hook 'before', 'find', req.query
          collection = db.collection req.params.collection
          collection.findOne qry, (err, doc) ->
            return res.send 500, err if err
            return res.send 404 if not doc
            doc = hook 'after', 'find', doc
            next doc


      # db.collection.findById
      url = "#{cfg.root}/:collection/:id*"
      router.route 'GET', url, auth, (req, res, next) ->
        cache (next) ->
          target = unescape(req.params[1]).replace /\//g, '.' if req.params[1]
          qry = {_id: new mongodb.ObjectID req.params.id}
          prj = {}
          prj[target] = 1 if target

          collection = db.collection req.params.collection
          collection.findOne qry, prj, (err, doc) ->
            return res.send 500, err if err
            return res.send 404 if not doc
            doc = hook 'after', 'find', doc
            doc = doc?[key] for key in target.split '.' if target
            next doc


      # execute routes
      router._dispatch req, res, next

