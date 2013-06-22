_ = require 'underscore'
Firebase = require 'firebase'
FirebaseTokenGenerator = require 'firebase-token-generator'
merge = require 'deepmerge'
mongodb = require 'mongodb'
wrap = require 'asset-wrap'

module.exports = (app, config, next) ->

  # configuration
  config = merge {
    root: '/api'
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
    throw err if err

    # connect to firebase
    fb = new Firebase config.firebase.url
    token_generator = new FirebaseTokenGenerator config.firebase.secret
    token = token_generator.createToken {}, {
      expires: new Date('2020-01-01 00:00:00 UTC').getTime()
    }
    fb.auth token, ->

      # routes
      app.get "#{config.root}/mongofb.js", (req, res, next) ->
        asset = new wrap.Snockets {
          src: "#{__dirname}/client.coffee"
        }, (err) ->
          return res.send 500, err if err
          res.send asset.data

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
          doc = snapshot.val()
          doc._id = new mongodb.ObjectID doc._id
          qry = {_id: doc._id}
          opt = {safe: true, upsert: true}
          collection = db.collection req.params.collection
          collection.update qry, doc, opt, (err) ->
            return res.send 500, err if err
            res.send doc

      app.get "#{config.root}/:collection/find", (req, res, next) ->
        opt = {limit: 20}
        collection = db.collection req.params.collection
        collection.find(req.query, opt).toArray (err, docs) ->
          return res.send 500, err if err
          res.json docs

      app.get "#{config.root}/:collection/findOne*", (req, res, next) ->
        collection = db.collection req.params.collection
        collection.findOne req.query, (err, doc) ->
          return res.send 500, err if err
          res.json doc

      app.get "#{config.root}/:collection/:id*", (req, res, next) ->
        target = unescape(req.params[1]).replace /\//g, '.' if req.params[1]
        qry = {_id: new mongodb.ObjectID req.params.id}
        prj = {}
        prj[target] = 1 if target

        collection = db.collection req.params.collection
        collection.findOne qry, prj, (err, doc) ->
          return res.send 500, err if err
          doc = doc?[key] for key in target.split '.' if target
          res.json doc

