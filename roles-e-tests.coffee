@post = new Mongo.Collection 'Posts'
post.remove({})

flagSetPermission = false

describe 'suite basics', ->
  beforeAll (test)->
    if not flagSetPermission
      roleE.setPermission 'post'
      flagSetPermission = true

    spies.restoreAll()
    stubs.restoreAll()
    post.remove({})

    stubs.create '_roles_findOne', roleE._roles, 'findOne'
    stubs._roles_findOne.withArgs({role: 'A'}).returns({bases: null})
    stubs._roles_findOne.withArgs({role: 'B'}).returns({bases: null})
    stubs._roles_findOne.withArgs({role: 'C'}).returns({bases: ['A', 'B']})

    stubs.create 'meteor_users_findOne', Meteor.users, 'findOne'
    stubs.meteor_users_findOne.returns({roles: ['C']})

    stubs.create '_rules_find', roleE._rules, 'find'
    stubs._rules_find.withArgs({collection: 'post', type: 'insert'}).returns({fetch: -> [{query: {a: '1', b: '2'}, role: 'A'}]})
    stubs._rules_find.withArgs({collection: 'post', type: 'update'}).returns({fetch: -> [{query: {a: '1', b: '2'}, role: 'A'}]})

  beforeEach (test)->
    post.remove({})

  afterEach (test) ->
    post.remove({})

  afterAll (test) ->
    spies.restoreAll()
    stubs.restoreAll()
    post.remove({})

  it 'test _roleIsIn true', (test) ->
    bool = roleE._roleIsIn 'A', ['C']
    test.equal(bool, true)

  it 'test _roleIsIn false', (test) ->
    bool = roleE._roleIsIn 'A', ['B']
    test.equal(bool, false)

  it 'test userHasRole true', (test) ->
    bool = roleE.userHasRole('userId', 'A')
    test.equal(bool, true)

  it 'test userHasRole false', (test) ->
    bool = roleE.userHasRole('userId', 'D')
    test.equal bool, false

  it 'test can true', (test) ->
    bool = roleE.can 'userId', 'insert', {a: '1', b: '2', c: '3'}, 'post'
    test.equal bool, true

  it 'test can false', (test) ->
    bool = roleE.can 'userId', 'insert', {a: '2', b: '2', c: '3'}, 'post'
    test.equal bool, false

  it 'test insert post', (test) ->
    Meteor.call '/Posts/insert', {a: '1', b: '2', c: '3'}
    count = post.find().count()
    test.equal count, 1

  it 'test insert post fail', (test) ->
    try
      Meteor.call '/Posts/insert', {a: '2', b: '2', c: '3'}
    catch error

    count = post.find().count()
    test.equal count, 0

  it 'test update ok', (test)->
    Meteor.call '/Posts/insert', {_id: '0', a: '1', b: '2', c: '3'}
    try
      Meteor.call '/Posts/update', _id: '0', {$set: {c:'9'}}
      test.equal 1,1
    catch error
      test.equal 1,0

  it 'test update fail', (test)->
    Meteor.call '/Posts/insert', {_id: '0', a: '1', b: '2', c: '3'}
    try
      Meteor.call '/Posts/update', _id: '0', {$set: {a:'9'}}
      test.equal 0,1
    catch
      test.equal 1,1