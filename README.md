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

roleE.addRolesToUser(['nurse_supervisor'], userId) # add roles to user

observation.permit('insert').ifHasRoleE('clinical').apply() # role 'nurse' is checked only one time
```

