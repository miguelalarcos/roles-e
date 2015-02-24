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

_isMatch = (doc, query) ->
  doc = _.clone(doc)
  for key, value of query
    if value == '*'
      doc[key] = '*'
  subdoc = _.pick(doc, _.keys(query))
  if _.isEqual(subdoc, query)
    return true
  else
    return false

roleE.can = (userId, type, doc, collection) ->
  ret = []
  for doc_ in rules.find(collection: collection, type: type).fetch()
    for field of doc_.query
      if doc_.query[field] is null
        delete doc_.query[field]
        if userId != doc[field]
          return false
    if _isMatch(doc, doc_.query)
      ret.push roleE.userHasRole(userId, doc_.role)
  #return _.all(ret)
  return not _.isEmpty(ret) and _.all(ret)

roleE.addRole = (role, bases)->
  roles.insert({role:role, bases:bases})

roleE.removeRole = (role)->
  roles.remove({role:role})

roleE.addRule = (rule) ->
  rules.insert rule

roleE.removeRule = (rule) ->
  rules.remove(rule)

roleE._roleIsIn = (role, bases) ->
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
  ncanu = (not roleE.can(userId, 'update', doc, collection))
  _id = tmp.insert doc
  tmp.update _id, modifier
  doc_u = tmp.findOne _id
  tmp.remove _id
  ncani = (not roleE.can(userId, 'insert', doc_u, collection))

  return ncanu or ncani

roleE._insert = (userId, doc, collection) ->
  not roleE.can(userId, 'insert', doc, collection)

roleE._remove = (userId, doc, collection) ->
  not roleE.can(userId, 'remove', doc, collection)

roleE.setPermission = (collection) ->
  roleE.self[collection].deny
    insert: (userId, doc) -> roleE._insert(userId, doc, collection)
    update : (userId, doc, fields, modifier) -> roleE._update(userId, doc, fields, modifier, collection)
    remove: (userId, doc) -> roleE._remove(userId, doc, collection)

  roleE.self[collection].allow
    insert: -> true
    update: -> true
    remove: -> true