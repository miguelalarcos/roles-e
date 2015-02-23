roles.remove({})
post.remove({})
Meteor.users.remove({})
rules.remove({})

roleE.add 'clinical'
roleE.add 'nurse', ['clinical']
roleE.add 'nurse1floor', ['nurse']
roleE.add 'nurse2floor', ['nurse']
roleE.add 'nurse_supervisor', ['nurse1floor', 'nurse2floor']

userId = Accounts.createUser
  email: 'm@m.es'
  password: 'secret'
roleE.addRolesToUser(['nurse1floor'], userId)

rules.insert
  collection: 'post'
  rules:
    insert: [
      query: {code: '04'}
      role: 'clinical'
    ]
    update: [
      query: {code: '04'}
      role: 'clinical'
    ]
    remove: [
      query: {code: '04'}
      role: 'nurse_supervisor'
    ]

roleE.setPermission 'post'
