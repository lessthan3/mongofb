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
