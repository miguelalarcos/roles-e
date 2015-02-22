roles = new Mongo.Collection('Roles')
roles.remove({})
roleE = {}

roleE.getPath = (name)->
  path = roles.findOne(name:name).path
  if path
    path + ':' + name
  else
    name

roleE.add = (base, name)->
  if base is null
    path = null
  else
    path = roleE.getPath(base)
  roles.insert({path: path, name:name})

roleE.addRolesToUser = (roles_, userId) ->
  Meteor.users.update(userId, {$push: {roles: {$each: roles_}}})


roleE.userHasRole = (userId, role)->
  userRoles = Meteor.users.findOne(userId).roles

  for rol in userRoles
    if rol == role
      return true
    for r in roles.findOne(name: rol).path.split(':')
      if role == r
        return true
  return false


Security.defineMethod "ifHasRoleE",
  fetch: []
  deny: (type, arg, userId)->
    return not roleE.userHasRole(userId, arg)
