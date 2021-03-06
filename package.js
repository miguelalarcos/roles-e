Package.describe({
  name: 'miguelalarcos:roles-e',
  version: '0.5.7',
  summary: 'A simple role package for Meteor with multiple role inheritance and rules.',
  git: 'https://github.com/miguelalarcos/roles-e.git',
  documentation: 'README.md'
});

Package.onUse(function(api) {
  api.versionsFrom('1.0.3.1');
  api.use('coffeescript', 'server');
  api.use('mongo', 'server');
  api.use('underscore', 'server');
  api.addFiles('roles-e.coffee', 'server');
  api.export('roleE', 'server');
});

Package.onTest(function(api) {
    api.use('tinytest');
    api.use('underscore', 'server');
    api.use('practicalmeteor:munit', 'server');
    api.use('coffeescript');
    api.use('accounts-password');
    api.use('mongo');
    api.use('miguelalarcos:roles-e');
    api.addFiles('roles-e-tests.coffee', 'server');
});

