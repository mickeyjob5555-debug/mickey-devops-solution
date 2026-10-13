# MongoDB cookbook attributes.

default['mongodb']['port'] = 27017
default['mongodb']['data_dir'] = '/var/lib/mongodb'

# Package version to install.
default['mongodb']['version'] = '6.0'

# Network settings. Bind to the private interface, not 0.0.0.0,
# so the database is not exposed on every network interface.
default['mongodb']['bind_ip'] = '127.0.0.1'

# Replica set name.
default['mongodb']['replset'] = 'rs0'

# Admin credentials. In a real cookbook these must NOT be hardcoded.
# They should come from an encrypted data bag, HashiCorp Vault, or
# the Chef Infra Server's secret store.
default['mongodb']['admin_user'] = 'admin'
default['mongodb']['admin_password'] = nil
