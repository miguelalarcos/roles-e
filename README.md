roles-e
=======

A simple role package for Meteor with multiple role inheritance.

Explanation
-----------

Use:
```coffee
roleE.add 'clinical' # create a basic role
roleE.add 'nurse', ['clinical'] # role nurse extends 'clinical'
roleE.add 'nurse1floor', ['nurse']
roleE.add 'nurse2floor', ['nurse']
roleE.add 'nurse_supervisor', ['nurse1floor', 'nurse2floor'] # multiple extends

roleE.addRolesToUser(['nurse1floor'], userId) # add roles to user

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

# client side

_id = post.insert
  text: 'insert coin'
  code: '04'

post.update _id, {$set: {text: 'game over!'}}
post.remove _id  # access denied

```

