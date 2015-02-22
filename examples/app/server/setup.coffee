post.remove({})

roleE.add null, 'base'
roleE.add 'base', 'admin'
roleE.add 'admin','superadmin'

Meteor.users.remove({})
userId = Accounts.createUser
  email: 'm@m.es'
  password: 'secret'
roleE.addRolesToUser(['admin'], userId)

