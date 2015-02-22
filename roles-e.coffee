@roles = new Mongo.Collection('Roles')
roles.remove({})
roleE = {}

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

Security.defineMethod "ifHasRoleE",
  fetch: []
  deny: (type, arg, userId)->
    return not roleE.userHasRole(userId, arg)
