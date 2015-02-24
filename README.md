[![Build Status](https://travis-ci.org/miguelalarcos/roles-e.svg)](https://travis-ci.org/miguelalarcos/roles-e)

roles-e
=======

A simple role package for Meteor with multiple role inheritance.

Explanation
-----------

Use:
```coffee
#server side

roleE.addRole 'clinical'
roleE.addRole 'nurse', ['clinical']
roleE.addRole 'nurse1floor', ['nurse']
roleE.addRole 'nurse2floor', ['nurse']
roleE.addRole 'nurse3floor', ['nurse']
roleE.addRole 'nurse_supervisor', ['nurse1floor', 'nurse2floor', 'nurse3floor']
roleE.removeRole 'nurse3floor'

roleE.addRolesToUser(['nurse1floor'], userId)

roleE.addRule {collection: 'post', type: 'insert', name: 'A', query: {code: '04'}, role: 'clinical'}
roleE.addRule {collection: 'post', type: 'insert', name: 'A2', query: {code: '05'}, role: 'clinical'}
roleE.addRule {collection: 'post', type: 'insert', name: 'A3', query: {code: '06'}, role: 'clinical'}
roleE.removeRule {collection: 'post', type: 'insert', name: 'A3'}
roleE.addRule {collection: 'post', type: 'update', name: 'B', query: {code: '04'}, role: 'clinical'}
roleE.addRule {collection: 'post', type: 'remove', name: 'C', query: {code: '04'}, role: 'nurse_supervisor'}

roleE.setPermission 'post'

#client side

_id = post.insert
  text: 'insert coin'
  code: '04'

post.update _id, {$set: {text: 'game over!'}}
post.remove _id #remove failed: Access denied

#both sides
@post = new Mongo.Collection('Posts')

```

You can have several rules like this (given some collection and type 'insert', for example):

* {name: 'F', query: {a: '1'}, role: 'A'}
* {name: 'F2', query: {a: '1', b: '2'}, role: 'B'}
* {name: 'F3', query: {a: '1', b: '2', c: '4'}, role: 'D'}

If you want to insert {a:'1', b:'2', c:'4', d:'100'}, you match the three rules, and must pass all.

API
---
* addRule:
```roleE.addRule = (arg) ->```
Example:
```coffee
roleE.addRule {collection: 'post', type: 'insert', name: 'A', query: {code: '04'}, role: 'clinical'}
#this rule will be checked if a doc with {code: '04'} inside is intended to be inserted. Role 'clinical' has the permission to insert
```

* removeRule:
```roleE.removeRule = (arg) ->```
Example:
```coffee
roleE.removeRule {collection: 'post', type: 'insert', name: 'A3'}
```

* addRole:
```roleE.addRole = (role, bases)->```
Example:
```coffee
roleE.addRole 'clinical' # add a basic role
roleE.addRole 'nurse', ['clinical'] # add a role that extends 'clinical' role
roleE.addRole 'nurse_supervisor', ['nurse1floor', 'nurse2floor', 'nurse3floor'] # multiple inheritance
```

* removeRole:
```roleE.removeRole = (role)->```
Example:
```coffee
roleE.removeRole 'nurse3floor'
```

* can:
```roleE.can = (userId, type, doc, collection) ->```
Example:
```coffee
roleE.can(userId, 'insert', doc, 'post') # user can insert doc in collection post?
```

* addRolesToUser:
```addRolesToUser = (roles_, userId) ->```
Example:
```coffee
roleE.addRolesToUser(['nurse_supervisor'], userId)
```

* userHasRole:
```userHasRole = (userId, role)->```
Example:
```coffee
roleE.userHasRole(userId, 'nurse')
```

* setPermission:
```setPermission = (collection) ->```
Example:
```coffee
roleE.setPermission 'post'
```

Run tests:
  ```meteor test-packages ./```