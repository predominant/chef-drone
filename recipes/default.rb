include_recipe 'docker' if node['drone']['install_docker']

remote_file node['drone']['temp_file'] do
  source node['drone']['package_url']
  action :create_if_missing
end

dpkg_package 'drone' do
  source node['drone']['temp_file']
  action :install
end

template 'drone.conf' do
  source 'drone.conf.erb'
  path node['drone']['config_file']
  mode 0644
  owner 'root'
  group 'root'
  notifies :restart, 'service[drone]', :delayed
end

chef_gem 'toml'
require 'toml'
toml_string = ::TOML::Generator.new(node['drone']['config']).body

file node['drone']['toml_file'] do
  mode 0644
  action :create
  content toml_string
  notifies :restart, 'service[drone]', :delayed
end

service 'drone' do
  provider Chef::Provider::Service::Upstart
  supports status: true, restart: true
  action [:enable, :start]
  restart_command 'service drone restart'
  subscribes :restart, 'template[drone.conf]', :immediately
  subscribes :restart, "file[#{node['drone']['toml_file']}]", :immediately
end
