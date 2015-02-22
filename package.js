Package.describe({
  name: 'miguelalarcos:roles-e',
  version: '0.1.0',
  summary: 'A simple role package for Meteor with multiple role inheritance',
  git: 'https://github.com/miguelalarcos/roles-e.git',
  documentation: 'README.md'
});

Package.onUse(function(api) {
  api.versionsFrom('1.0.3.1');
  api.use('coffeescript', 'server');
  api.use('mongo', 'server');
  api.use('jquery', 'server');
  api.use('ongoworks:security', 'server'); //1.0.1
  api.use('accounts-base', ['client', 'server']);
  //api.use('accounts-password', ['client', 'server']);
  api.addFiles('roles-e.coffee', 'server');
  api.export('roleE', 'server');

});

