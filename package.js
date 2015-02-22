Package.describe({
  name: 'miguelalarcos:roles-e',
  version: '0.0.1',
  summary: 'A simple role package for Meteor with role inheritance',
  git: '',
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

