# ex: set tabstop=2 shiftwidth=2 expandtab:
#
# Cookbook Name:: serverdensity
# Recipe:: install

if node['serverdensity']['agent_key'].nil?
  # No agent key provided, try the API
  include_recipe 'serverdensity::api'
end

case node[:platform]

when "debian", "ubuntu"
  include_recipe "apt"

  apt_repository "serverdensity" do
    key "https://www.serverdensity.com/downloads/boxedice-public.key"
    uri "https://www.serverdensity.com/downloads/linux/deb"
    distribution "all"
    components ["main"]
    action :add
  end

  # Update the local package list
  execute "serverdensity-apt-get-update" do
    command "apt-get update"
    action :nothing

  end

when "redhat", "centos", "fedora", "scientific", "amazon"
  include_recipe "yum::epel"

  yum_key "RPM-GPG-KEY-serverdensity" do
    url "https://www.serverdensity.com/downloads/boxedice-public.key"
    action :add
  end

  yum_repository "serverdensity" do
    name "serverdensity"
    description "Server Density sd-agent"
    url "https://www.serverdensity.com/downloads/linux/redhat/" 
    key "RPM-GPG-KEY-serverdensity"
    enabled 1
    action :add
  end

end

package "sd-agent" do
  action :install
end

# Configure your Server Density agent key
template "/etc/sd-agent/config.cfg" do
  source "config.cfg.erb"
  owner "root"
  group "root"
  mode "644"
  variables(node[:serverdensity])
  notifies :restart, "service[sd-agent]"
end

service "sd-agent" do
  supports :start => true, :stop => true, :restart => true
  # Starts the service if it's not running and enables it to start at system boot time
  action [:enable, :start]
end
