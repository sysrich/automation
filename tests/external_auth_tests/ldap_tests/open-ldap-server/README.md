# Open LDAP Test Server

Docker compose file that creates an LDAP server for testing the eternal auth feature.

It comes pre set up to allow simple TLS, startTLS, anonymous binds, and anonymous search. 

For more info on the container go to https://github.com/osixia/docker-openldap

This server also comes with a test user that can be found in custom_ldif/03-test-user.ldif the users credentials are is `test:pass`.