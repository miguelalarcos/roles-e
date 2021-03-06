[![Build Status](https://travis-ci.org/miguelalarcos/roles-e.svg)](https://travis-ci.org/miguelalarcos/roles-e)

roles-e
=======

A simple role package for Meteor with multiple role inheritance and rules to pass for inserting, updating and removing.

Explanation
-----------

Use:
```coffee
# server side

roleE.addRole 'A'
roleE.addRole 'B', ['A']  # B extends A role
roleE.addRole 'C', ['B']
roleE.addRole 'D', ['B']
roleE.addRole 'E', ['B']
roleE.addRole 'F', ['C', 'D', 'E'] # multiple extend
roleE.removeRole 'C'

roleE.addRolesToUser(['E'], userId)

# role A can insert in post collection if code == '04' in the doc to be inserted
# Example: a role 'nurse' can insert a doc with level attribute == 'NURSE'
roleE.addRule {collection: 'post', type: 'insert', name: 'R1', pattern: {code: '04'}, role: 'A'}

roleE.addRule {collection: 'post', type: 'insert', name: 'R2', pattern: {code: '05'}, role: 'E'}
roleE.addRule {collection: 'post', type: 'insert', name: 'R3', pattern: {code: '06'}, role: 'E'}
roleE.removeRule 'R3' # the name of rules must be unique in the app

# role A can update post collection if the doc in database has code == '04' and if the resultant doc after update passes the insert rules.
# Example: a role 'nurse' can modify a document if the level attribute of that document is 'NURSE', and if not trying to set that level to 'DOCTOR'.
roleE.addRule {collection: 'post', type: 'update', name: 'R4', pattern: {code: '04'}, role: 'A'}
roleE.addRule {collection: 'post', type: 'remove', name: 'R5', pattern: {code: '04'}, role: 'F'}

# sets the allow and deny rules to collection 'post'.
roleE.setPermission 'post'

# client side

_id = pt.insert
  text: 'insert coin'
  code: '04'

pt.update _id, {$set: {text: 'game over!'}}
pt.remove _id # remove failed: Access denied

# both sides
@pt = new Mongo.Collection('post')

```

You can have several rules like this (given some collection and type 'insert', for example):

* {name: 'F1', pattern: {a: '1'}, role: 'A'}
* {name: 'F2', pattern: {a: '1', b: '2'}, role: 'B'}
* {name: 'F3', pattern: {c:'3'}, role: 'C'}

The algorithm explained:

If you are going to insert the next doc {a: '1', b:'2', c:'3'}, then the doc matches with te three rules. But F1 is a subset of F2,
so it's not considered. Then, if the user has the roles 'B' and 'C', the insert will success.

Update is special because there are two phases:

* check the doc already in database with the rules type *update*.
* check the resultant doc after insert (simulated) with the rules of type *insert*. We don't want an inconsistent state: if we don't do that, with update we could achieve what is denied by an insert.

If you specify one field of a rule with null, when the match is going to happen, this field is substituted with the userId and compared with the one in database. This is the way to check, for example, that I can edit a post because I'm the owner.
For example, given a collection and type='update':

```coffee
{pattern: {owner: null}, role: 'A'}
```
In this case, if checks true then the match is ok, but if it fails, it continues checking the next patterns.

Note that pattern value can be an array:

```coffee
{name: 'F3', pattern: {a: '1', b: ['3', '4', '5']}, role: 'B'}
```

API
---
* addRule:
```roleE.addRule = (arg) ->```
Example:
```coffee
roleE.addRule {collection: 'post', type: 'insert', name: 'R3', pattern: {code: '04'}, role: 'A'}
```

* removeRule:
```roleE.removeRule = (name) ->```
Example:
```coffee
roleE.removeRule 'R3'
```

* addRole:
```roleE.addRole = (role, bases)->```
Example:
```coffee
roleE.addRole 'A' # add a basic role
roleE.addRole 'B', ['A'] # add a role that extends 'A' role
roleE.addRole 'D', ['B', 'C'] # multiple inheritance
```

* removeRole:
```roleE.removeRole = (role)->```
Example:
```coffee
roleE.removeRole 'B'
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
roleE.addRolesToUser(['D', 'E'], userId)
```

* setRolesToUser:
```setRolesToUser = (roles, userId) ->```
Example:
```coffee
roleE.setRolesToUser(['D', 'E'], userId)
```

* userHasRole:
```userHasRole = (userId, role)->```
Example:
```coffee
roleE.userHasRole(userId, 'A')
```

* setPermission:
```setPermission = (collection) ->```
  Sets the allow and deny rules to the collection.

Example:
```coffee
roleE.setPermission 'post'
```

* filter:
```filter = (userId, collection) -> ```
returns an {$or: [filter1, filter2, ...]} where filters are registered this way:

```coffee
roleE.addRule {collection: 'authors', type: 'find', name: 'filter author', pattern: {x:555}, role: 'B'}
```
Example:
```coffee
Meteor.publish 'authors_filtered', ->
  authors.find(roleE.filter(this.userId, 'authors'))
```

Security
--------
You can integrate with ```ongoworks:security```. Here is an example:

```coffee
Security.defineMethod "ifRolesE",
  fetch: []
  transform: null
  deny: (type, arg, userId, doc, fields, modifier) ->
    if type == 'insert'
      not roleE._insert(userId, doc, arg)
    else if type == 'update'
      not roleE._update(userId, doc, fields, modifier, arg)
    else
      not roleE._remove(userId, doc, arg)

authors.permit(['insert', 'update', 'remove']).ifRolesE('authors').apply()
```

---
Run tests:
  ```meteor test-packages ./```