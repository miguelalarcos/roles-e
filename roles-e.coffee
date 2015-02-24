roles = new Mongo.Collection('Roles')
rules = new Mongo.Collection('Rules')

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

roleE.can = (userId, type, doc, collection) ->
  for doc_ in rules.find(collection: collection, type: type).fetch()
    subdoc = _.pick(doc, _.keys(doc_.query))
    if _.isEqual(subdoc, doc_.query)
      return roleE.userHasRole(userId, doc_.role)
  return false

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

roleE.setPermission = (collection) ->
  roleE.self[collection].deny
    insert: (userId, doc) ->
      not roleE.can(userId, 'insert', doc, collection)
    update: (userId, doc, fields, modifier)->
      docSimulateInsert = _.clone(doc)
      for field in fields
        docSimulateInsert[field] = modifier['$set'][field]
      ncanu = (not roleE.can(userId, 'update', doc, collection))
      ncani = (not roleE.can(userId, 'insert', docSimulateInsert, collection))
      return ncanu or ncani
    remove: (userId, doc) ->
      not roleE.can(userId, 'remove', doc, collection)

  roleE.self[collection].allow
    insert: -> true
    update: -> true
    remove: -> true