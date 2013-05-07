# Chef Search Helper

## Usage

~~~
rabbitmq_hosts = search_helper_best_ip(node[:rabbitmq_search], node[:rabbitmq_hosts]) do |ip, other_node|
  "#{ip}:#{other_node[:rabbitmq][:port]}"
end
~~~

~~~
sysadmins = search_helper(:users, node[:sysadmin_search], node[:sysadmins]) do |user|
  "#{user['id']}"
end
~~~
