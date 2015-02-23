@post = new Mongo.Collection 'Posts'
post.remove({})

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
  else if collection == 'post' and type == 'update'
    ret.fetch = -> [{query: {a: '1', b: '2'}, role: 'A'}]
  return ret

Tinytest.add 'can true', (test) ->
  bool = roleE.can 'userId', 'insert', {a: '1', b: '2', c: '3'}, 'post'
  test.equal bool, true

Tinytest.add 'can false', (test) ->
  bool = roleE.can 'userId', 'insert', {a: '2', b: '2', c: '3'}, 'post'
  test.equal bool, false

# ---------------------

roleE.setPermission 'post'

Tinytest.add 'insert post', (test) ->
  post.remove({})
  Meteor.call '/Posts/insert', {a: '1', b: '2', c: '3'}
  count = post.find().count()
  test.equal count, 1
  post.remove({})

Tinytest.add 'insert post fail', (test) ->
  post.remove({})
  try
    Meteor.call '/Posts/insert', {a: '2', b: '2', c: '3'}
  catch error

  count = post.find().count()
  test.equal count, 0
  post.remove({})

describe 'suite update', ->
  beforeEach (test)->
    post.remove({})
    Meteor.call '/Posts/insert', {_id: '0', a: '1', b: '2', c: '3'}
  afterEach (test)->
    post.remove({})
  it 'test update ok', (test)->
    try
      Meteor.call '/Posts/update', _id: '0', {$set: {c:'9'}}
      test.equal 1,1
    catch
      test.equal 1,0
  it 'test update fail', (test)->
    try
      Meteor.call '/Posts/update', _id: '0', {$set: {a:'9'}}
      test.equal 0,1
    catch
      test.equal 1,1

