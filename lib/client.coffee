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

class mongofb.EventEmitter
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
    @events[event].filter (fn) -> callback isnt null and fn isnt callback

class mongofb.Database
  constructor: (@api) ->
    @connect()
    @cache = true

  collection: (name) ->
    new mongofb.Collection @, name

  connect: ->
    url = @request 'Firebase'
    @firebase = new Firebase url

  get: (path) ->
    path = path.split /[\/\.]/g
    collection = @collection path[0]
    return collection if path.length == 1
    collection.get path[1..].join '/'

  request: ->
    for arg in arguments
      switch typeof arg
        when 'string' then resource = arg
        when 'function' then next = arg
        when 'object' then params = arg

    result = null
    if next
      success = (data) -> next null, data
      error = (jqXHR, textStatus, err) -> next err
      async = true
    else
      success = (data) -> result = data
      error = -> result = null
      async = false
    $.ajax {
      url: "#{@api}/#{resource}"
      cache: @cache
      type: 'GET'
      data: params
      success: success
      error: error
      async: async
    }
    return result

class mongofb.Collection
  constructor: (@database, @name) ->
    @ref = new mongofb.CollectionRef @

  get: (path) ->
    path = path.split /[\/\.]/g
    doc = collection.findById path[0]
    return doc if path.length == 1
    doc.get path[1..].join '/'

  insert: (doc, priority, next) ->
    if typeof priority == 'function'
      next = priority
      priority = null
    @database.request 'ObjectID', (err, id) =>
      return next?(err) if err
      doc._id = id
      doc.created = Firebase.ServerValue.TIMESTAMP
      ref = @database.firebase.child "#{@name}/#{id}"
      ref.set doc, (err) =>
        return next?(err) if err
        ref.setPriority priority if priority
        @database.request "update/#{@name}/#{id}", (err, doc) =>
          return next?(err) if err
          next?(null, new mongofb.Document @, doc)

  find: (query, next) ->
    if next
      @database.request "#{@name}/find", query, (err, docs) =>
        return next err if err
        docs = (new mongofb.Document @, doc for doc in docs)
        next null, docs
    else
      docs = @database.request "#{@name}/find", query
      return (new mongofb.Document @, doc for doc in docs)

  findById: (id, next) ->
    if next
      @database.request "#{@name}/#{id}", (err, doc) =>
        return next err if err
        return next null, null if not doc
        next null, new mongofb.Document @, doc
    else
      doc = @database.request "#{@name}/#{id}"
      return null if not doc
      return new mongofb.Document @, doc

  findOne: (query, next) ->
    if next
      @database.request "#{@name}/findOne", query, (err, doc) =>
        return next err if err
        return next null, null if not doc
        next null, new mongofb.Document @, doc
    else
      doc = @database.request "#{@name}/findOne", query
      return null if not doc
      return new mongofb.Document @, doc

  list: (priority, limit=1) ->
    @ref.endAt priority
    @ref.limit limit
    @ref

  remove: (_id, next) ->
    ref = @database.firebase.child "#{@name}/#{_id}"
    ref.set null, (err) =>
      return next?(err) if err
      @database.request "update/#{@name}/#{_id}", (err, doc) =>
        return next?(err) if err
        next?(null)

class mongofb.CollectionRef extends mongofb.EventEmitter
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

class mongofb.Document
  constructor: (@collection, @data) ->
    @database = @collection.database
    @key = "#{@collection.name}/#{@data._id}"
    @ref = new mongofb.DocumentRef @

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

  remove: (next) ->
    @collection.remove @data._id, next

  save: (next) ->
    @ref.set @data, next

  set: (value, next=null) ->
    @ref.set value, next

  val: ->
    @ref.val()

class mongofb.DocumentRef extends mongofb.EventEmitter
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
    while mongofb.utils.startsWith path, '..'
      temp.pop()
      path = path[2..]
      path = path[1..] if mongofb.utils.startsWith path, '/'
    new mongofb.DocumentRef @document, "#{temp.join '/'}/#{path}"

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
        return if mongofb.utils.isEquals @data, snapshot.val()
        @updateData snapshot.val()
        @emit 'update', @data
        @emit 'value', @data

  off: (event, callback=null) ->
    super event, callback

    if @events.update?.length == 0 and @events.value?.length == 0
      @ref.off 'value'

  parent: ->
    new mongofb.DocumentRef @document, @path[0...@path.length-1]

  set: (value, next) ->
    ref = @database.firebase.child @key
    ref.set value, (err) =>
      return next?(err) if err
      @database.request "update/#{@key}", (err, doc) =>
        return next?(err) if err
        @updateData value
        next?(null)

  updateData: (data) ->
    @data = data
    if @path.length == 0
      @document.data = data
    else
      [keys..., key] = @path
      target = @document.data
      target = target[k] for k in keys
      target[key] = data

  val: ->
    if typeof @data == 'object'
      $.extend true, {}, @data
    else if Array.isArray @data
      $.extend true, [], @data
    else
      @data

