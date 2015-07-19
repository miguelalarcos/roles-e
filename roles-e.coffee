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
  for doc_ in rules.find(collection: collection, type: 'find').fetch()
    if roleE.userHasRole(userId, doc_.role)
      ret.push doc_.pattern
  {$or: ret}

roleE.can = (userId, type, doc, collection) ->
  patterns = []
  toRemove = []
  for doc_ in rules.find(collection: collection, type: type).fetch()
    flag = false
    for field of doc_.pattern
      if doc_.pattern[field] is null
        if userId == doc[field]
          return true
        else
          flag = true
          break
    if flag then continue
    if roleE._isMatch(doc, doc_.pattern)
      for patt in patterns
        if roleE._isMatch(patt.pattern, doc_.pattern)
          continue
        else if roleE._isMatch(doc_.pattern, patt.pattern)
          toRemove.push patt
      patterns.push {pattern: doc_.pattern, value: roleE.userHasRole(userId, doc_.role)}

  patterns = (patt for patt in patterns when patt not in toRemove)
  return not _.isEmpty(patterns) and _.all(x.value for x in patterns)

roleE._can = (userId, type, doc, collection) -> # deprecated
  ret = []
  for doc_ in rules.find(collection: collection, type: type).fetch()
    flag = false
    for field of doc_.pattern
      if doc_.pattern[field] is null
        #delete doc_.pattern[field]
        if userId != doc[field]
          #return false
          flag = true
          break
        else
          return true
    if flag
      continue
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

roleE.setRolesToUser = (roles, userId) ->
  Meteor.users.update(userId, {$set: {roles: roles}})

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

roleE._edit = (userId, doc, collection) ->
  roleE.can(userId, 'update', doc, collection)

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
  #canInsert: (doc, collection) ->
  #  roleE._insert(this.userId, doc, collection)
  #canUpdate: (doc, fields, modifier, collection) ->
  #  roleE._update(this.userId, doc, fields, modifier, collection)
  roleEcanRemove: (doc, collection) ->
    roleE._remove(this.userId, doc, collection)
  #canSave: (doc, collection) ->
  #  roleE._insert(this.userId, doc, collection)
  roleEcanEdit: (doc, collection) ->
    roleE._edit(this.userId, doc, collection)

