Meteor.loginWithPassword 'm@m.es', 'secret'

_id = post.insert
  text: 'insert coin'
  code: '04'

post.update _id, {$set: {text: 'game over!'}}
post.remove _id
