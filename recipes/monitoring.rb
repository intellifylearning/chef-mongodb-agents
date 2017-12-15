#
# Cookbook Name:: mongodb-agents
# Recipe:: monitoring
#
# Copyright 2015, Bill Moritz
#
# All rights reserved - Do Not Redistribute
#

package_name = "mongodb-mms-monitoring-agent"
package_file = "#{package_name}_#{node['mongodb-agents']['monitoring']['version']}_#{node['kernel']['machine'] == 'x86_64' ? 'amd64' : 'i386'}.#{node['platform_version'] == '16.04' ? 'ubuntu1604' : ''}.deb"
download_url = "#{node['mongodb-agents']['agent_url']}/monitoring/#{package_file}"

remote_file "#{Chef::Config[:file_cache_path]}/#{package_file}" do
  action :create_if_missing
  backup 5
  owner "root"
  group "root"
  mode "0644"
  source download_url
end

dpkg_package package_name do
  action :install
  source "#{Chef::Config[:file_cache_path]}/#{package_file}"
end

template "/etc/mongodb-mms/monitoring-agent.config" do
  source "monitoring-agent.config.erb"
  owner "root"
  group "root"
  mode "0644"
  notifies :restart, "service[mongodb-mms-monitoring-agent]"
  variables( :api_key => node['mongodb-agents']['api_key'],
             :mms_baseurl => node['mongodb-agents']['mms_baseurl'],
             :group_id => node['mongodb-agents']['group_id']  )
end

service "mongodb-mms-monitoring-agent" do

  case node['platform']
     when 'ubuntu'
         if node['platform_version'] == '16.04'
           provider Chef::Provider::Service::Systemd
         end
     else
       provider Chef::Provider::Service::Upstart
     end
  supports :status => true, :restart => true, :reload => true
  action [ :enable, :start ]
end
