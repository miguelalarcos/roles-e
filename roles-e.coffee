roles = new Mongo.Collection('Roles')
rules = new Mongo.Collection('Rules')
tmp = new Mongo.Collection(null)
tmp.remove({})

roles.deny
  insert: -> true
  update: -> true
  remove: -> true

rules.deny
  insert: -> true
  update: -> true
  remove: -> true

roleE = {}
roleE.self = @
roleE._roles = roles
roleE._rules = rules

roleE._isMatch = (doc, pattern) ->
  for k, v of pattern
    if doc[k] is undefined
      return false
    if _.isArray(v)
      if doc[k] not in v
        return false
    else
      if doc[k] != v
        return false
  return true

roleE.filter = (userId, collection) ->
  ret = []
  #userRoles = Meteor.users.findOne(userId).roles
  for doc_ in rules.find(collection: collection, type: 'find').fetch()
    if roleE.userHasRole(userId, doc_.role)
      ret.push doc_.pattern
  {$or: ret}

roleE.can = (userId, type, doc, collection) ->
  ret = []
  for doc_ in rules.find(collection: collection, type: type).fetch()
    for field of doc_.pattern
      if doc_.pattern[field] is null
        delete doc_.pattern[field]
        if userId != doc[field]
          return false
    if roleE._isMatch(doc, doc_.pattern)
      ret.push roleE.userHasRole(userId, doc_.role)
  return not _.isEmpty(ret) and _.all(ret)

roleE.addRole = (role, bases)->
  roles.insert({role:role, bases:bases})

roleE.removeRole = (role)->
  roles.remove({role:role})

roleE.addRule = (rule) ->
  rules.insert rule

roleE.removeRule = (name) ->
  rules.remove(name:name)

roleE._roleIsIn = (role, bases) ->
  bases = bases or []
  bases = bases[..]
  done = bases[..]
  flag = false
  while not _.isEmpty(bases)
    r = bases.shift()
    if role == r
      flag = true
      break
    for b in (roles.findOne(role: r)?.bases or [])
      if b not in done
        bases.push b
        done.push b
  return flag


roleE.addRolesToUser = (roles_, userId) ->
  Meteor.users.update(userId, {$push: {roles: {$each: roles_}}})


roleE.userHasRole = (userId, role)->
  userRoles = Meteor.users.findOne(userId).roles
  return roleE._roleIsIn(role, userRoles)

roleE._update = (userId, doc, fields, modifier, collection)->
  canu = roleE.can(userId, 'update', doc, collection)
  _id = tmp.insert doc
  tmp.update _id, modifier
  doc_u = tmp.findOne _id
  tmp.remove _id
  cani = roleE.can(userId, 'insert', doc_u, collection)

  return canu and cani

roleE._insert = (userId, doc, collection) ->
  roleE.can(userId, 'insert', doc, collection)

roleE._remove = (userId, doc, collection) ->
  roleE.can(userId, 'remove', doc, collection)

roleE.setPermission = (collection) ->
  roleE.self[collection].allow
    insert: (userId, doc) -> roleE._insert(userId, doc, collection)
    update : (userId, doc, fields, modifier) -> roleE._update(userId, doc, fields, modifier, collection)
    remove: (userId, doc) -> roleE._remove(userId, doc, collection)

Meteor.methods
  canInsert: (doc, collection) ->
    roleE._insert(this.userId, doc, collection)
  canUpdate: (doc, fields, modifier, collection) ->
    #roleE._insert(this.userId, modifier['$set'], collection)
    roleE._update(this.userId, doc, fields, modifier, collection)
  canRemove: (doc, collection) ->
    roleE._remove(this.userId, doc, collection)
  canSave: (doc, collection) ->
    roleE._insert(this.userId, doc, collection)

