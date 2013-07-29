# MongoFB

## Table of Contents

 - [General Information](#general-information)
  - [What is MongoFB](#what-is-mongofb)
  - [Diagram](#diagram)
 - [Usage](#usage)
  - [Server Configuration](#server-configuration)
  - [Server API](#server-api)
  - [Server Hooks](#server-hooks)
  - [Authentication](#authentication)
  - [Client SDK](#client-sdk)
 - [Examples](#examples)
  - [Server](#server)
  - [Javascript Client](#javascript-client) 
  - [iOS Client](#ios-client) 
  - [Android Client](#android-client) 

## General Information

### What is MongoFB

MongoFB is a combination of MongoDB and Firebase. You can run your MongoDB
anywhere you like, and sign up for your own Firebase account.  MongoFB
provides an API so you can query, index, and aggregate your data (all the
things you wish your firebase could do).  MongoFB uses Firebase as its
master source of data, so you get built in Security Rules, Authentication,
and can listen for updates on any document of any collection, or any field
of any document (all the things you wish your mongodb would do).

 - Firebase
   - Security/Authentication
   - WebSockets
 - MongoDB
   - querying
   - indexing
   - aggregation

### Diagram
![Diagram](http://media.lessthan3.com/wp-content/uploads/2013/07/mongofb.png)

## Usage

### Sever Configuration

MongoFB can be included in your express or zappajs server, using middleware.
```
mongofb = require 'mongofb'

app.use mongofb {
  root: '/api/1'      # the root url to host mongofb on
  cache:
    max: 100          # the max number of results to store in a local LRU cache
    maxAge: 1000*60*5 # the max age of any result in the LRU cache
  firebase:
    url: ''           # the url of your firebase
    secret: ''        # your firebase secret - only needed if your firebase has security rules
  mongodb:
    db: 'test'        # the mongodb to connect to
    host: 'localhost' # the host of your mongodb
    pass: ''          # the password to connect with
    port: 27017       # the port to connect to
    user: 'admin'     # the user to connect with
    options: {}       # other connection options [ref](#https://github.com/mongodb/node-mongodb-native/blob/master/docs/articles/MongoClient.md#basic-parts-of-the-url)
}
```


### Server API

/API-ROOT/mongofb.js
```
Serves the javascript client
```

/API-ROOT/Firebase
```
Let's the client look up the public url of your Firebase
```

/API-ROOT/ObjectId
```
The client calls here to get a new ObjectID before writing to Firebase
```

/API-ROOT/sync/:collection/:id
```
After an insert, update, or remove, a client will tell the server it needs to
update data in Firebase. The server will then pull the most up-to-date data
directly from Firebase and write it to MongoDB for querying.
```

/API-ROOT/:collection/find
```
Perform a db.collection.find on your MongoDB. Pass your query as query
parameters to this endpoint. The result is returned as an array.

special options
 - limit: limits the number of results in the response
```

/API-ROOT/:collection/findOne
```
Perform a db.collection.findOne on your MongoDB. Pass your query as query
parameters to this endpoint. The result is returned as an object
```

/API-ROOT/:collection/:id*
```
Perform a db.collection.findOne by {_id: ObjectID()} on your MongoDB. Pass your
query as query parameters to this endpoint. The result is returned as an object.

This endpoint functions more like a standard resource url as no query parameters
are used.  This method also lets you query for specific fields of a document.

example: /API-ROOT/posts/510b56c221168da296f27bd5/author/name

The above might be a posts collection for my blog. With this I could directly
access the author's name of post 510b56c221168da296f27bd5.

The corresponding Firebase URL for that data would be
https://my-firebase.firebaseio.com/posts/510b56c221168da296f27bd5/author/name
```

### Server Hooks
Sometimes you may want to modify the response from your api, or set default
values for parameters, or do something special if the user is authenticated.
This is all possible with MongoFB Hooks.

You can define your hooks in your server configuration. The current hooks
available are...

new_query = collection.before.find(query)

new_doc = collection.after.find(doc)


Example Usage
```
app.use mongofb {
  firebase: config.firebase
  mongofb: config.mongodb
  root: '/api/1'
  hooks:
    users:
      after:
        find: (doc) ->
          # hide private user information to other users
          return doc if @user?.auth?.id == doc.id
          {_id: doc._id, public: doc.public}
    posts:
      before:
        find: (query) ->
          # an author changed their name
          if query.author?.name == 'joe'
            query.author.name = 'joey'

          # if we search for football or baseball, also search all sports
          if query.tag in ['football', 'baseball']
            query.tag = [query.tag, 'sports']

          # force a small limit
          query.limit = 10
}
```

### Authentication
authenticate any request by passing a token query parameter with the
value being the users' firebase token.

The @user can then be referenced in your hooks

### Client SDK
How to use the Javascript SDK

Classes
```
mongofb.Database
mongofb.Collection
mongofb.Document
mongofb.DocumentRef
```

mongofb.Database
```
# This is the equivalent to a MongoDB Database

# Connect to our MongoFB server
db = new mongofb.Database 'http://localhost:3000/API-ROOT'

# Get a collection
posts = db.collection 'posts'
posts = db.get 'posts' 

# Get a document directly
post = db.collection('posts').get('510b56c221168da296f27bd5')
post = db.get('posts/510b56c221168da296f27bd5')
post = db.get('posts.510b56c221168da296f27bd5')

# Get a field from a document directly
name = db.get('posts/510b56c221168da296f27bd5/author/name')
name = db.get('posts.510b56c221168da296f27bd5.author.name')
```

mongofb.Collection
```
# This is the equivalent to a MongoDB Collection

# Get a collection
users = db.collection 'users'
users = db.get 'users'

# Insert a document (this method must be asynchronous)
users.insert {foo: 'bar'}, (err, user) ->
  throw err if err
  console.log user.val()

# Run a find query (synchronous)
docs = users.find {foo: 'bar'}

# Run a find query (asynchronous)
users.find {foo: 'bar'}, (err, docs) ->
  throw err if err
  console.log docs

# Run a findById (synchronous)
user = users.findById '510b56c221168da296f27bd5'

# Run a findById (asynchronous)
users.findById '510b56c221168da296f27bd5', (err, user) ->
  throw err if err
  console.log user

# Run a findOne (synchronous)
user = users.findOne {foo: 'bar'}

# Run a findOne (asynchonous)
users.findOne {foo: 'bar'}, (err, user) ->
  throw err if err
  console.log user

# Remove a document (this method must be asynchronous)
# only allowed to remove by id
users.remove '510b56c221168da296f27bd5', (err) ->
  throw err if err
```

mongofb.Document
```
# This is the equivalent of a MongoDB Document
post = posts.findById '510b56c221168da296f27bd5'

# Update a field in a Document
post.get('author.name').set('new author')

# update an entire Document
post.set {author: {name: 'the author'}, content: 'long post'}

# get json for a document
post.val()

# listeners
post.on 'update', (val) ->
  # called when this document is updated

post.on 'value', (val) ->
  # called immediately, and when the document is updated

post.on 'remove', (val) ->
  # called when the post is removed from the database
```

mongofb.DocumentRef
```
# A DocumentRef is a reference to a field of a Document

# Get a ref
ref = post.get('author.name')

# add listeners
ref.on 'update', (val) ->
ref.on 'value', (val) ->

# remove listeners
ref.off 'update'
ref.off 'value'
ref.off()

# get the parent ref
ref.parent()

# change the value of this property
ref.set('new author')

# get the json value for this ref
ref.val()


```

## Examples

### Server
```
express = require 'express'
mongofb = require '../lib/server'

app = express()
app.use mongofb {
  firebase:
    url: 'https://vn42xl9zsez.firebaseio-demo.com/'
  mongodb:
    host: 'localhost'
    port: 27017
  root: '/api/v2'
}
app.get '/', (req, res) ->
  res.send """
  <html>
    <body>
      <script type='text/javascript' src='http://cdnjs.cloudflare.com/ajax/libs/jquery/2.0.2/jquery.min.js'></script>
      <script type='text/javascript' src='https://cdn.firebase.com/v0/firebase.js'></script>
      <script type='text/javascript' src='/api/v2/mongofb.js'></script>
    </body>
  </html>
  """

app.listen 3000
console.log "listening: 3000"
```


### Javascript Client
```
window.db = new mongofb.Database 'http://localhost:3000/api/v2'
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
```

### iOS Client
```
Coming Soon!
```

### Android Client
```
Coming Soon!
```

