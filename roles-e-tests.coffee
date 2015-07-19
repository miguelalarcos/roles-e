@post = new Mongo.Collection 'TestPosts'
post.remove({})

flag = false

injectArgPosi = (i, obj, method, arg) ->
  original = obj[method]
  obj[method] = ->
    arguments[i] = arg
    original.apply {}, arguments

injectArgPos0 = _.partial(injectArgPosi, 0)

describe 'suite basics', ->
  beforeAll (test)->
    if not flag
      roleE.setPermission 'post'

      injectArgPos0 roleE, '_update', 'miguel'
      injectArgPos0 roleE, '_remove', 'miguel'

      flag = true

    spies.restoreAll()
    stubs.restoreAll()
    post.remove({})

    stubs.create '_roles_findOne', roleE._roles, 'findOne'
    stubs._roles_findOne.withArgs({role: 'A'}).returns({bases: null})
    stubs._roles_findOne.withArgs({role: 'B'}).returns({bases: null})
    stubs._roles_findOne.withArgs({role: 'C'}).returns({bases: ['A', 'B']})

    stubs.create 'meteor_users_findOne', Meteor.users, 'findOne'
    stubs.meteor_users_findOne.withArgs().returns({roles: ['C']})

    stubs.create '_rules_find', roleE._rules, 'find'
    stubs._rules_find.withArgs({collection: 'post', type: 'insert'}).returns({fetch: -> [
      {pattern: {}, role: 'A'},
      {pattern: {a: '1'}, role: 'A'},
      {pattern: {a: '1', b: '2'}, role: 'B'},
      {pattern: {b: '2', c: '3'}, role: 'C'},
      {pattern: {a: '1', b: '2', c: '4'}, role: 'D'},
      {pattern: {a: '2', b: '2', c: '3'}, role: 'C'},
      {pattern: {a: '2', b: '2', c: ['7','8']}, role: 'C'}
    ]})

    stubs._rules_find.withArgs({collection: 'post2', type: 'insert'}).returns({fetch: -> []})

    stubs._rules_find.withArgs({collection: 'post', type: 'update'}).returns({fetch: -> [{pattern: {a: '1', b: '2', owner: null}, role: 'A'}]})
    stubs._rules_find.withArgs({collection: 'post', type: 'remove'}).returns({fetch: -> [{pattern: {a: '1', b: '2', owner: null}, role: 'A'}]})

  beforeEach (test)->
    post.remove({})

  afterEach (test) ->
    post.remove({})

  afterAll (test) ->
    spies.restoreAll()
    stubs.restoreAll()
    post.remove({})

  it 'test _isMatch true basic', (test) ->
    test.isTrue roleE._isMatch({a:7}, {a:7})

  it 'test _isMatch false basic', (test) ->
    test.isFalse roleE._isMatch({a:7}, {a:8})

  it 'test _isMatch true array', (test) ->
    test.isTrue roleE._isMatch({a:7}, {a:[7, 8]})

  it 'test _isMatch false array', (test) ->
    test.isFalse roleE._isMatch({a:7}, {a:[8, 9]})

  it 'test _roleIsIn true', (test) ->
    bool = roleE._roleIsIn 'A', ['C']
    test.equal(bool, true)

  it 'test _roleIsIn true 2', (test) ->
    bool = roleE._roleIsIn 'A', ['C', 'B']
    test.equal(bool, true)

  it 'test _roleIsIn false', (test) ->
    bool = roleE._roleIsIn 'A', ['B']
    test.equal(bool, false)

  it 'test _roleIsIn false 2', (test) ->
    bool = roleE._roleIsIn 'A', []
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

  it 'test can true 2', (test) ->
    bool = roleE.can 'userId', 'insert', {a: '2', b: '2', c: '3'}, 'post'
    test.equal bool, true

  it 'test can true array', (test) ->
    bool = roleE.can 'userId', 'insert', {a: '2', b: '2', c: '7'}, 'post'
    test.equal bool, true

  it 'test can false', (test) ->
    bool = roleE.can 'miguel', 'insert', {a: '1', b: '2', c: '4'}, 'post'
    test.equal bool, false

  it 'test can empty rule', (test) ->
    bool = roleE.can 'miguel', 'insert', {x:5, y:5}, 'post'
    test.equal bool, true

  it 'test can false no rules match', (test) ->
    bool = roleE.can 'miguel', 'insert', {z: 1}, 'post2'
    test.equal bool, false

  it 'test insert post ok', (test) ->
    Meteor.call '/TestPosts/insert', {a: '1', b: '2', c: '3'}
    count = post.find().count()
    test.equal count, 1

  it 'test insert post fail', (test) ->
    try
      Meteor.call '/TestPosts/insert', {a: '1', b: '2', c: '4'}
    catch error

    count = post.find().count()
    test.equal count, 0

  it 'test update ok', (test)->
    Meteor.call '/TestPosts/insert', {_id: '0', a: '1', b: '2', c: '3', owner:'miguel'}
    try
      Meteor.call '/TestPosts/update', _id: '0', {$set: {c:'9'}}
      test.equal 1,1
    catch error
      test.equal 1,0

  it 'test update ok2', (test)->
    Meteor.call '/TestPosts/insert', {_id: '0', a: '1', b: '2', c: '3', owner:'miguel'}
    try
      Meteor.call '/TestPosts/update', _id: '0', {$set: {a:'9'}}
      test.equal 1,1
    catch
      test.equal 1,0

  it 'test update fail', (test)->
    Meteor.call '/TestPosts/insert', {_id: '0', a: '1', b: '2', c: '3', owner:'miguel'}
    try
      Meteor.call '/TestPosts/update', _id: '0', {$set: {c:'4'}}
      test.equal 1,0
    catch
      test.equal 1,1

  it 'test update ok owner', (test)->
    Meteor.call '/TestPosts/insert', {_id: '0', a: '1', b: '2', c: '3', owner:'miguel'}
    try
      Meteor.call '/TestPosts/update', _id: '0', {$set: {a:'99'}}
      test.equal 1,1
    catch
      test.equal 1,0

  it 'test update fail owner', (test)->
    Meteor.call '/TestPosts/insert', {_id: '0', a: '1', b: '2', c: '3', owner:'xmiguelx'}
    try
      Meteor.call '/TestPosts/update', _id: '0', {$set: {a:'4'}}
      test.equal 1,0
    catch
      test.equal 1,1

  it 'test remove ok owner', (test)->
    Meteor.call '/TestPosts/insert', {_id: '0', a: '1', b: '2', c: '3', owner:'miguel'}
    try
      Meteor.call '/TestPosts/remove', _id: '0'
      test.equal 1,1
    catch
      test.equal 1,0

  it 'test remove fail owner', (test)->
    Meteor.call '/TestPosts/insert', {_id: '0', a: '1', b: '2', c: '3', owner:'xmiguelx'}
    try
      Meteor.call '/TestPosts/remove', _id: '0'
      test.equal 1,0
    catch
      test.equal 1,1

# ##############
describe 'suite can', ->
  beforeAll (test)->
    if not flag
      roleE.setPermission 'post'

      injectArgPos0 roleE, '_update', 'miguel'
      injectArgPos0 roleE, '_remove', 'miguel'

      flag = true

    spies.restoreAll()
    stubs.restoreAll()
    post.remove({})

    stubs.create '_roles_findOne', roleE._roles, 'findOne'
    stubs._roles_findOne.withArgs({role: 'A'}).returns({bases: null})
    stubs._roles_findOne.withArgs({role: 'B'}).returns({bases: null})
    stubs._roles_findOne.withArgs({role: 'C'}).returns({bases: ['A', 'B']})

    stubs.create 'meteor_users_findOne', Meteor.users, 'findOne'
    stubs.meteor_users_findOne.withArgs().returns({roles: ['C']})

    stubs.create '_rules_find', roleE._rules, 'find'
    stubs._rules_find.withArgs({collection: 'post', type: 'insert'}).returns({fetch: -> [
      {pattern: {a: '1'}, role: 'R'}
      {pattern: {a: '1', b:'2'}, role: 'A'}
      {pattern: {c: '3'}, role: 'R'}
      {pattern: {c: '4'}, role: 'A'}
    ]})


    stubs._rules_find.withArgs({collection: 'post', type: 'update'}).returns({fetch: -> [
      {pattern: {owner: null, role: 'A'}}
    ]})

  beforeEach (test)->
    post.remove({})

  afterEach (test) ->
    post.remove({})

  afterAll (test) ->
    spies.restoreAll()
    stubs.restoreAll()
    post.remove({})

  it 'test can a: 1', (test) ->
    bool = roleE.can 'userId', 'insert', {a: '1'}, 'post'
    test.equal bool, false

  it 'test can 0', (test) ->
    bool = roleE.can 'userId', 'insert', {a: '1', b: '2', c: '3'}, 'post'
    test.equal bool, false

  it 'test can 1', (test) ->
    bool = roleE.can 'userId', 'insert', {a: '1', b: '2', c: '4'}, 'post'
    test.equal bool, true

  it 'test can 2', (test) ->
    bool = roleE.can 'miguel', 'update', {owner: 'miguel'}, 'post'
    test.equal bool, true

  it 'test can 3', (test) ->
    bool = roleE.can 'miguel', 'update', {owner: null}, 'post'
    test.equal bool, false