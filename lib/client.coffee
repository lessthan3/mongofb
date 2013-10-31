#
# Mongo Firebase
# mongofb.js
#
# Database
# Collection
# CollectionRef
# Document
# DocumentRef
#

if typeof window != 'undefined'
  exports = window.mongofb = {}
  extend = (target, object) ->
    $.extend true, target, object
  Firebase = window.Firebase
  fetch = (args) ->
    result = null
    if args.next
      success = (data) -> args.next null, data
      error = (jqXHR, textStatus, err) -> args.next err
      async = true
    else
      success = (data) -> result = data
      error = -> result = null
      async = false
    $.ajax {
      url: args.url
      cache: args.cache
      type: 'GET'
      data: args.params
      success: success
      error: error
      async: async
    }
    return result

else
  exports = module.exports = {}
  extend = require 'node.extend'
  request = require 'request'
  Firebase = require 'firebase'
  fetch = (args) ->
    request {
      url: args.url
      qs: args.params
      method: 'GET'
    }, (err, resp, body) =>
      if args.json then body = JSON.parse body
      args.next err, body

exports.utils =
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
          return false if not exports.utils.isEquals a[k], b[k]
        when 'function'
          return false if a[k].toString() != b[k].toString()
        else
          return false if a[k] != b[k]
    true
  startsWith: (str, target) ->
    str.slice(0, target.length) == target

class exports.EventEmitter
  constructor: ->
    @events = {}

  emit: (event, args...) ->
    if @events[event]
      callback(args...) for callback in @events[event]

  on: (event, callback) ->
    @events[event] ?= []
    @events[event].push callback

  off: (event, callback=null) ->
    @events[event] ?= []
    @events[event] = @events[event].filter (fn) ->
      callback isnt null and fn isnt callback

class exports.Database
  constructor: (cfg) ->
    if typeof cfg == 'string'
      @api = cfg
      @request 'Firebase', false, (url) ->
        @firebase = new Firebase url
    else
      @api = cfg.server
      @firebase = new Firebase cfg.firebase
    @cache = true

  connect: (next) ->
    @request 'Firebase', false, (url) =>
      @firebase = new Firebase url
      next()

  collection: (name) ->
    new exports.Collection @, name

  get: (path) ->
    path = path.split /[\/\.]/g
    collection = @collection path[0]
    return collection if path.length == 1
    collection.get path[1..].join '/'

  request: ->
    json = true
    resource = ''
    next = null
    params = {}

    for arg in arguments
      switch typeof arg
        when 'boolean' then json = arg
        when 'string' then resource = arg
        when 'function' then next = arg
        when 'object' then params = arg

    url = "#{@api}/#{resource}"
    return fetch {
      cache: @cache
      json: json
      next: next
      params: params
      resource: resource
      url: url
    }

class exports.Collection
  constructor: (@database, @name) ->
    @ref = new exports.CollectionRef @

  get: (path) ->
    path = path.split /[\/\.]/g
    doc = collection.findById path[0]
    return doc if path.length == 1
    doc.get path[1..].join '/'

  insert: (doc, priority, next) ->
    if typeof priority == 'function'
      next = priority
      priority = null
    @database.request 'ObjectID', {
      _: "#{Date.now()}-#{Math.random()}"
    }, (err, id) =>
      return next?(err) if err
      doc._id = id
      ref = @database.firebase.child "#{@name}/#{id}"
      ref.set doc, (err) =>
        return next?(err) if err
        ref.setPriority priority if priority
        @database.request "sync/#{@name}/#{id}", {
          _: Date.now()
        }, (err, doc) =>
          return next?(err) if err
          next?(null, new exports.Document @, doc)

  find: (query, next) ->
    if next
      @database.request "#{@name}/find", query, (err, docs) =>
        return next err if err
        docs = (new exports.Document @, doc for doc in docs)
        next null, docs
    else
      docs = @database.request "#{@name}/find", query
      docs ?= []
      return (new exports.Document @, doc for doc in docs)

  findById: (id, next) ->
    if next
      @database.request "#{@name}/#{id}", (err, doc) =>
        return next err if err
        return next null, null if not doc
        next null, new exports.Document @, doc
    else
      doc = @database.request "#{@name}/#{id}"
      return null if not doc
      return new exports.Document @, doc

  findOne: (query, next) ->
    if next
      @database.request "#{@name}/findOne", query, (err, doc) =>
        return next err if err
        return next null, null if not doc
        next null, new exports.Document @, doc
    else
      doc = @database.request "#{@name}/findOne", query
      return null if not doc
      return new exports.Document @, doc

  list: (priority, limit=1) ->
    @ref.endAt priority
    @ref.limit limit
    @ref

  remove: (_id, next) ->
    ref = @database.firebase.child "#{@name}/#{_id}"
    ref.set null, (err) =>
      return next?(err) if err
      @database.request "sync/#{@name}/#{_id}", (err, doc) =>
        return next?(err) if err
        next?(null)

class exports.CollectionRef extends exports.EventEmitter
  constructor: (@collection) ->
    @database = @collection.database
    @ref = @database.firebase.child @collection.name

  endAt: (priority) ->
    @ref = @ref.endAt priority

  limit: (num) ->
    @ref = @ref.limit num

  startAt: (priority) ->
    @ref = @ref.startAt priority

  on: (event, callback) ->
    super event, callback

    if @events.insert?.length > 0
      @ref.off 'child_added'
      @ref.on 'child_added', (snapshot) =>
        @emit 'insert', snapshot.val()

    if @events.remove?.length > 0
      @ref.off 'child_removed'
      @ref.on 'child_removed', (snapshot) =>
        @emit 'remove', snapshot.val()

  off: (event, callback=null) ->
    super event, callback

    if @events.insert?.length == 0
      @ref.off 'child_added'

    if @events.remove?.length == 0
      @ref.off 'child_removed'

class exports.Document
  constructor: (@collection, @data) ->
    @database = @collection.database
    @key = "#{@collection.name}/#{@data._id}"
    @ref = new exports.DocumentRef @

  emit: (event, args...) ->
    @ref.emit event, args...

  get: (path) ->
    @ref.get path

  name: ->
    @ref.name()
    
  on: (event, callback) ->
    @ref.on event, callback

  off: (event, callback) ->
    @ref.off event, callback

  refresh: (next) ->
    @ref.refresh next

  remove: (next) ->
    @collection.remove @data._id, next

  save: (next) ->
    @ref.set @data, next

  set: (value, next=null) ->
    @ref.set value, next

  val: ->
    @ref.val()

class exports.DocumentRef extends exports.EventEmitter
  constructor: (@document, @path='') ->
    super()
    @collection = @document.collection
    @database = @collection.database

    # @path[0] doesn't work in ie6, must use @path[0..0]
    if typeof @path is 'string'
      @path = @path[1..] if @path[0..0] == '/'
      @path = @path.split /[\/\.]/g if typeof @path is 'string'
    @key = "#{@document.key}/#{@path.join '/'}".replace /\/$/, ''
    @data = @document.data
    @data = @data?[k] for k in @path when k isnt ''
    @ref = @database.firebase.child @key

  get: (path) ->
    temp = @path.slice 0
    while exports.utils.startsWith path, '..'
      temp.pop()
      path = path[2..]
      path = path[1..] if exports.utils.startsWith path, '/'
    new exports.DocumentRef @document, "#{temp.join '/'}/#{path}"

  name: ->
    if @path.length == 0 then @data._id else @path[@path.length-1]

  # value: emit now and when updated
  # update: emit only when updated
  on: (event, callback) ->
    super event, callback

    if @events.update?.length > 0 or @events.value?.length > 0
      @emit 'value', @data
      @ref.off 'value'
      @ref.on 'value', (snapshot) =>
        return if exports.utils.isEquals @data, snapshot.val()
        @updateData snapshot.val()
        @emit 'update', @data
        @emit 'value', @data

  off: (event, callback=null) ->
    super event, callback

    unless @events.update?.length and @events.value?.length
      @ref.off 'value'

  parent: ->
    new exports.DocumentRef @document, @path[0...@path.length-1]

  refresh: (next) ->
    @ref.once 'value', (snapshot) =>
      @updateData snapshot.val()
      next?()

  set: (value, next) ->
    ref = @database.firebase.child @key
    ref.set value, (err) =>
      return next?(err) if err
      @database.request "sync/#{@key}", (err, doc) =>
        return next?(err) if err
        @updateData value
        next?(null)

  updateData: (data) ->

    # update DocumentRef data
    @data = data

    # update Document data
    if @path.length == 0
      @document.data = data
    else
      [keys..., key] = @path
      target = @document.data
      for k in keys
        target[k] ?= {}
        target = target[k]
      target[key] = data

  val: ->
    if Array.isArray @data
      extend [], @data
    else if typeof @data == 'object'
      extend {}, @data
    else
      @data

