**v0.8.2** (2014-05-25)

 - only check created and last_modified fields on document level refs

**v0.8.1** (2014-05-24)

 - fix updateData bug for when @data.created is undefined

**v0.8.0** (2014-05-23)

 - Add auto created=Date.now() config option
 - ignore 'created' and 'last_modified' fields for triggering updates

**v0.7.8** (2014-05-23)

 - Date.now() should be enough

**v0.7.7** (2014-05-23)

 - fix caching when running server-side

**v0.7.6** (2014-05-23)

 - add npm-debug.log to gitignore
 - handle 500 responses as errors from server-side usage fetches

**v0.7.5** (2014-05-22)

 - body = JSON.parse body bug

**v0.7.4** (2014-05-22)

 - need to keep next(null, null) for 404 case from fetch

**v0.7.3** (2014-05-22)

 - 0.7.2, but let 404s return as null instead of error

**v0.7.2** (2014-05-22)

 - better handling of bad request responses

**v0.7.1** (2014-05-15)

 - better error messaging

**v0.7.0** (2014-05-01)

 - update asset-wrap dependency

**v0.6.4** (2014-03-08)

 - add last_modified feature

**v0.6.3** (2014-03-08)

 - add fields to findById query

**v0.6.2** (2014-03-08)

 - add built-in hooks for common operations

**v0.6.1** (2014-03-06)

 - rollback firebase data if mongodb sync fails

**v0.6.0** (2014-02-03)

 - update asset-wrap to 0.6.x
 - switch to jwt parsing library for token check
 - watch out for invalid query parameters
 - update other dependencies

**v0.5.8** (2014-02-03)

 - update asset-wrap to 0.5.x

**v0.5.7** (2014-01-20)

 - allow fields for non json http requests

**v0.5.6** (2014-01-17)

 - default values of query field should be null

**v0.5.5** (2014-01-17)

 - send 404 when findOne finds nothing

**v0.5.4** (2014-01-16)

 - add a new find query object for token and nocache
 - multiple ways to use find and findOne arguments

**v0.5.3** (2014-01-15)

 - add fields and options to javascript SDK
 - only allow writes to queried fields

**v0.5.2** (2014-01-13)

 - fix example for v0.4.x+
 - fix duplicate update bug
 - add .gitignore

**v0.5.1** (2014-01-13)

 - add ObjectID to exports
 - allow multiple arguments to hooks
 - hooks edit object instead of returning new
 - no max limit (this should be set through a hook)
 - no default limit (this should be set through a hook)
 - refactor findOne and findById to route through find
 - allow json arguments for criteria and fields
 - add field filtering
 - add sort and skip

**v0.4.1** (2013-12-27)

 - emit object clone for events

**v0.3.14** (2013-11-22)

 - add Database.auth
 - fix server-side ObjectID fetching (response is not json)

**v0.3.13** (2013-11-22)

 - add request dependency

**v0.3.12** (2013-11-04)

 - setToken function for client
 - check for statusCode on server-side client.coffee fetch
 - check for admin property in authentication
 - add mongofb reference to incoming requests

**v0.3.11** (2013-11-02)

 - for browser-side errors, return jqXHR object instead of error string

**v0.3.10** (2013-10-30)

 - more verbose cache bust for ObjectID (cant risk collisions here)

**v0.3.9** (2013-10-30)

 - dont set firebase created timestamp on new docs (use custom or ObjectID)
 - check for Array before object when getting val()

**v0.3.8** (2013-10-30)

 - simpler way to generate ObjectIDs
 - handle exceptions for bad ObjectIDs to sync and findByID

**v0.3.7** (2013-10-29)

 - pass json to fetch (needed for server-side mongofb client)
 - set correct limit parameter for finds

**v0.3.6** (2013-10-26)

 - cache avoid for ObjectId and sync on inserts

**v0.3.5** (2013-10-26)

 - expose fb and db

**v0.3.4** (2013-10-23)

 - fix EventEmitter.off to remove if the callback matched
 - fix actually removing the firebase listener if no events left to listen to
 - add a refresh function to force getting up-to-date data

**v0.3.3** (2013-10-22)

 - require crypto

**v0.3.2** (2013-10-22)

 - manually parse token instead of using auth

**v0.3.1** (2013-10-12)

 - typo "firebase", not "Firebase"

**v0.3.0** (2013-10-12)

 - make javascript sdk accessible server-side

**v0.2.6** (2013-08-11)

 - allow cache to be disabled

**v0.2.5** (2013-08-04)

 - parse null, true, false into actual values

**v0.2.4** (2013-07-30)

 - fix findById bug

**v0.2.3** (2013-07-30)

 - fix updateData bug where a key might not exist yet

**v0.2.2** (2013-07-29)

 - fix authentication by checking for token parameter
 - add authentication to README

**v0.2.1** (2013-07-29)

 - update documentation
 - turn into express middleware

**v0.1.2**

 - Start CHANGELOG.md
