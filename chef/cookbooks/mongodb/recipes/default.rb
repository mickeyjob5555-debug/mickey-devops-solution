#
# Cookbook:: mongodb
# Recipe:: default
#
# Installs MongoDB, writes its config, starts the service,
# and brings up a single-node replica set.

# Add the MongoDB apt repository. mongodb-org is not in the
# default Ubuntu repos, so this has to be done first.
apt_repository 'mongodb-org' do
  uri "https://repo.mongodb.org/apt/ubuntu"
  distribution "#{node['lsb']['codename']}/mongodb-org/#{node['mongodb']['version']}"
  components ['multiverse']
  keyserver 'keyserver.ubuntu.com'
  key '4B7C549A058F8B6B'
  action :add
end

# Install the packages at the version from attributes.
package 'mongodb-org' do
  version node['mongodb']['version']
  action :install
end

# Data directory. Mode is restrictive because it holds the database files.
directory node['mongodb']['data_dir'] do
  owner 'mongodb'
  group 'mongodb'
  mode '0750'
  recursive true
end

# Config file. Notifies the service to restart if the file changes.
template '/etc/mongod.conf' do
  source 'mongod.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
  notifies :restart, 'service[mongod]', :immediately
end

# Enable and start the service in one resource.
# This replaces the old execute + separate start, and it is idempotent.
service 'mongod' do
  action [:enable, :start]
end

# Wait for mongod to accept connections before we try to talk to it.
# The init script below will fail if mongod is not ready yet.
execute 'wait-for-mongod' do
  command 'until mongosh --quiet --eval "db.adminCommand({ping:1})" >/dev/null 2>&1; do sleep 2; done'
  action :run
end

# Initiate the replica set. Guarded so it only runs once.
# Uses mongosh, not mongo, because mongo is removed in MongoDB 6.
execute 'init-replica-set' do
  command "mongosh --quiet --eval 'rs.initiate({_id: \"#{node['mongodb']['replset']}\", members: [{_id: 0, host: \"127.0.0.1:#{node['mongodb']['port']}\"}]})'"
  not_if "mongosh --quiet --eval 'rs.status().ok' 2>/dev/null | grep -q 1"
  action :run
end
