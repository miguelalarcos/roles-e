roleE._roles.findOne = (role)->
  if role.role == 'A'
    return {bases: null}
  else if role.role == 'B'
    return {bases: null}
  else if role.role == 'C'
    return {bases: ['A', 'B']}

Tinytest.add '_roleIsIn true', (test) ->
  bool = roleE._roleIsIn 'A', ['C']
  test.equal(bool, true)

Tinytest.add '_roleIsIn false', (test) ->
  bool = roleE._roleIsIn 'A', ['B']
  test.equal(bool, false)

Meteor.users.findOne = (userId) ->
  {roles: ['C']}

Tinytest.add 'userHasRole true', (test) ->
  bool = roleE.userHasRole('userId', 'A')
  test.equal(bool, true)

Tinytest.add 'userHasRole false', (test) ->
  bool = roleE.userHasRole('userId', 'D')
  test.equal bool, false

roleE._rules.find = (arg)->
  ret = {}
  collection = arg.collection
  type = arg.type
  if collection == 'post' and type == 'insert'
    ret.fetch = -> [{query: {a: '1', b: '2'}, role: 'A'}]
  return ret

Tinytest.add 'can true', (test) ->
  bool = roleE.can 'userId', 'insert', {a: '1', b: '2', c: '3'}, 'post'
  test.equal bool, true

Tinytest.add 'can false', (test) ->
  bool = roleE.can 'userId', 'insert', {a: '2', b: '2', c: '3'}, 'post'
  test.equal bool, false

