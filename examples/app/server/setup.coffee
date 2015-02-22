post.remove({})

roleE.add 'clinical'
roleE.add 'nurse', ['clinical']
roleE.add 'nurse1floor', ['nurse']
roleE.add 'nurse2floor', ['nurse']
roleE.add 'nurse_supervisor', ['nurse1floor', 'nurse2floor']

Meteor.users.remove({})
userId = Accounts.createUser
  email: 'm@m.es'
  password: 'secret'
roleE.addRolesToUser(['nurse_supervisor'], userId)

