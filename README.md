[![Build Status](https://travis-ci.org/miguelalarcos/roles-e.svg)](https://travis-ci.org/miguelalarcos/roles-e)

roles-e
=======

A simple role package for Meteor with multiple role inheritance and rules to pass for inserting, updating and removing.

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

* {name: 'F1', query: {a: '*'}, role: 'A'}
* {name: 'F2', query: {a: '1', b: '2'}, role: 'B'}

Suppose we want to insert {a:'1', b: '2', c: '3'}, then it matches with the two rules. If user has in his role tree the roles 'A' and 'B', then passes. If one doesn't pass, then it denys.

Update is special because there are two phases:

* check the doc in database with the rules type *update*
* check the resultant doc after insert (simulated) with the rules of type *insert*. We don't want an inconsistent state: if we don't do that, with update we could achieve what is deny by an insert

So, if there's one rule that denys, the action is denied. Must be at least one rule that allows so that the action is allowed.

If you specify one field of a rule with null, when the match is going to happen, this field is substituted with the userId and compared with the one in Data Base. This is the way to check, for example, that I can edit a post because I'm the owner.
For example, given a collection and type='update':

```coffee
{query: {a: '1', b: '2', owner: null}, role: 'A'}

```

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