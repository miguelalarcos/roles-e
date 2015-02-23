roleE._roles.remove({})
post.remove({})
Meteor.users.remove({})
roleE._rules.remove({})

roleE.addRole 'clinical'
roleE.addRole 'nurse', ['clinical']
roleE.addRole 'nurse1floor', ['nurse']
roleE.addRole 'nurse2floor', ['nurse']
roleE.addRole 'nurse3floor', ['nurse']
roleE.addRole 'nurse_supervisor', ['nurse1floor', 'nurse2floor', 'nurse3floor']
roleE.removeRole 'nurse3floor'

userId = Accounts.createUser
  email: 'm@m.es'
  password: 'secret'
roleE.addRolesToUser(['nurse_supervisor'], userId)

roleE.addRule 'post', 'insert', {name: 'A', query: {code: '04'}, role: 'clinical'}
roleE.addRule 'post', 'insert', {name: 'A2', query: {code: '05'}, role: 'clinical'}
roleE.addRule 'post', 'insert', {name: 'A3', query: {code: '06'}, role: 'clinical'}
roleE.removeRule 'post', 'insert', 'A3'
roleE.addRule 'post', 'update', {name: 'B', query: {code: '04'}, role: 'clinical'}
roleE.addRule 'post', 'remove', {name: 'C', query: {code: '04'}, role: 'nurse_supervisor'}

roleE.setPermission 'post'
