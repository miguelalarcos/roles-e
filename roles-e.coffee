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
  for rule in rules.findOne(collection: collection).rules[type]
    subdoc = _.pick(doc, _.keys(rule.query))
    if _.isEqual(subdoc, rule.query)
      return roleE.userHasRole(userId, rule.role)
  return false

roleE.addRole = (role, bases)->
  roles.insert({role:role, bases:bases})

roleE.removeRole = (role)->
  roles.remove({role:role})

roleE.addRule = (collection, type, rule) ->
  doc = rules.findOne(collection:collection)
  if doc
    rules_ = doc.rules
    if rules_[type]
      rules_[type].push rule
    else
      rules_[type] = [rule]
    rules.update({collection:collection}, {$set: {rules: rules_}})
  else
    rules_ = {}
    rules_[type] = [rule]
    rules.insert({collection:collection, rules: rules_})

roleE.removeRule = (collection, type, name) ->
  field = 'rules.' + type
  subdoc = {}
  subdoc[field] = {name: name}
  rules.update({collection:collection}, {$pull: subdoc})

roleE.roleIsIn = (role, bases) ->
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
  return roleE.roleIsIn(role, userRoles)

roleE.setPermission = (collection) ->
  roleE.self[collection].deny
    insert: (userId, doc) ->
      not roleE.can userId, 'insert', doc, collection
    update: (userId, doc, fields, modifier)->
      not roleE.can userId, 'update', doc, collection
    remove: (userId, doc) ->
      not roleE.can userId, 'remove', doc, collection

  roleE.self[collection].allow
    insert: -> true
    update: -> true
    remove: -> true