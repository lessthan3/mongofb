#
# Mongo Firebase
# mongofb.js
#
# Database
# Collection
# Document
# Ref
#

window.mongofb = {}

window.mongofb.utils =
  isEquals: (a, b) ->
    return false if a and not b
    return false if b and not a
    for k of a
      return false if typeof b[k] is 'undefined'
    for k of b
      return false if typeof a[k] is 'undefined'

    for k of a
      switch typeof a[k]
        when 'object'
          return false if not mongofb.utils.isEquals a[k], b[k]
        when 'function'
          return false if a[k].toString() != b[k].toString()
        else
          return false if a[k] != b[k]
    true
  startsWith: (str, target) ->
    str.slice(0, target.length) == target
  trim: (str, chars) ->
    re = new RegExp '\^' + chars + '+|' + chars + '+$', 'g'
    str.replace re, ''

class mongofb.Database
  constructor: (@api) ->
    @connect()

  collection: (name) ->
    new mongofb.Collection @, name

  connect: (next) ->
    @request 'Firebase', (err, url) =>
      throw err if err
      @firebase = new Firebase url
      next()

  waitForConnection: (next) ->
    fn = =>
      return next() if @firebase
      setTimeout fn, 100
    fn()

  request: (resource, params, next) ->
    next = params if not next
    $.ajax {
      url: "#{@api}/#{resource}"
      type: 'GET'
      data: params
      success: (data, textStatus, jqXHR) =>
        next null, data
      error: (jqXHR, textStatus, error) =>
        next error
    }

class mongofb.Collection
  constructor: (@database, @name) ->

  insert: (doc, next) ->
    @database.waitForConnection =>
      @database.request 'ObjectID', (err, id) =>
        return next err if err
        doc._id = id
        ref = @database.firebase.child "#{@name}/#{id}"
        ref.set doc, (err) =>
          return next err if err
          @database.request "update/#{@name}/#{id}", (err, doc) =>
            return next err if err
            next null, new mongofb.Document @, doc

  find: (query, next) ->
    @database.request "#{@name}/find", query, (err, docs) =>
      return next err if err
      docs = (new mongofb.Document @, doc for doc in docs)
      next null, docs

  findById: (id, next) ->
    @database.request "#{@name}/#{id}", (err, doc) =>
      return next err if err
      return next null, null if not doc
      next null, new mongofb.Document @, doc

  findOne: (query, next) ->
    @database.request "#{@name}/findOne", query, (err, doc) =>
      return next err if err
      return next null, null if not doc
      next null, new mongofb.Document @, doc

class mongofb.Document
  constructor: (@collection, @data) ->
    @database = @collection.database
    @key = "#{@collection.name}/#{@data._id}"
    @ref = new mongofb.Ref @
    @ref.on 'update', =>
      @data = @ref.val()

  emit: (event) ->
    @ref.emit event

  get: (path) ->
    @ref.get path

  on: (event, callback) ->
    @ref.on event, callback

  off: (event, callback) ->
    @ref.off event, callback

  save: (next) ->
    @ref.set @data, next

  val: ->
    @ref.val()

class mongofb.Ref
  constructor: (@document, @path='') ->
    @collection = @document.collection
    @database = @collection.database
    @events = {}

    # @path[0] doesn't work in ie6, must use @path[0..0]
    if typeof @path is 'string'
      @path = @path[1..] if @path[0..0] == '/'
      @path = @path.split /[\/\.]/g if typeof @path is 'string'
    @key = "#{@document.key}/#{@path.join '/'}"
    @data = @document.data
    @data = @data?[k] for k in @path when k isnt ''
    @listen()

  emit: (event) ->
    if @events[event]
      callback() for callback in @events[event]

  get: (path) ->
    temp = @path.slice 0
    while mongofb.utils.startsWith path, '..'
      temp.pop()
      path = mongofb.utils.strip path, '..'
      path = mongofb.utils.strip path, '/'
    new mongofb.Ref @document, "#{temp.join '/'}/#{path}"

  listen: ->
    @database.waitForConnection =>
      ref = @database.firebase.child @key
      ref.on 'value', (snapshot) =>
        return if mongofb.utils.isEquals @data, snapshot.val()
        @data = snapshot.val()
        @emit 'update'

  on: (event, callback) ->
    @events[event] ?= []
    @events[event].push callback

  off: (event, callback) ->
    @events[event] ?= []
    @events[event].filter (fn) -> fn isnt callback

  parent: ->
    new Ref @path[0...@path.length-1]

  set: (value, next) ->
    @database.waitForConnection =>
      ref = @database.firebase.child "#{@document.key}/#{@path.join '/'}"
      ref.set value, (err) =>
        return next?(err) if err
        @database.request "update/#{@key}", (err, doc) ->
          return next?(err) if err
          next?(null)

  val: ->
    @data

