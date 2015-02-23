@roles = new Mongo.Collection('Roles')
@rules = new Mongo.Collection('Rules')

roleE = {}
roleE.self = @

roleE.can = (userId, type, doc, collection) ->
  for rule in rules.findOne(collection: collection).rules[type]
    subdoc = _.pick(doc, _.keys(rule.query))
    if _.isEqual(subdoc, rule.query)
      return roleE.userHasRole(userId, rule.role)
  return false #nunca deberiamos llegar aqui


roleE.add = (role, bases)->
  roles.insert({role:role, bases:bases})

roleE.roleIsIn = (role, bases) ->
  done = bases[..]
  flag = false
  while not _.isEmpty(bases)
    r = bases.shift()
    if role == r
      flag = true
      break
    for b in (roles.findOne(role: r).bases or [])
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
  @self[collection].deny
    insert: (userId, doc) ->
      not roleE.can userId, 'insert', doc, collection
    update: (userId, doc, fields, modifier)->
      not roleE.can userId, 'update', doc, collection
    remove: (userId, doc) ->
      not roleE.can userId, 'remove', doc, collection

  @self[collection].allow
    insert: -> true
    update: -> true
    remove: -> true