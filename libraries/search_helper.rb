# Copyright 2013 Hewlett-Packard Development Company, L.P.
#
# Author: Kiall Mac Innes <kiall@hp.com>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

module SearchHelper
  def search_best_ip(query, override, &block)
    if Chef::Config[:solo] and override.nil?
      Chef::Application.fatal!("You must supply an override with chef-solo")
    elsif override.nil?
      # Perform a search
      nodes = search(:node, query)

      if nodes.empty?
        Chef::Application.fatal!("Search was unable to find any nodes.")
      else
        nodes.map! do |member|
          yield select_best_ip(member), member
        end

        return nodes
      end
    else
      return override
    end
  end

  def search2(type, query, override, &block)
    # TODO: Find a better name for this method search2 is.. awful..
    if Chef::Config[:solo] and override.nil?
      Chef::Application.fatal!("You must supply an override with chef-solo")
    elsif override.nil?
      # Perform a search
      results = search(type, query)

      if results.empty?
        Chef::Application.fatal!("Search was unable to find any results.")
      else
        results.map! do |member|
          yield member
        end

        return results
      end
    else
      return override
    end
  end

  protected

  def select_best_ip(other_node)
    # HP Specific
    ip = select_best_ip_hp(other_node)
    return ip if not ip.nil?

    # Ohai Cloud Plugin
    ip = select_best_ip_ohai(other_node)
    return ip if not ip.nil?

    # Fallback
    return other_node['ipaddress']
  end

  def select_best_ip_hp(other_node)
    if node.attribute?('area') and other_node.attribute?('area')
      # HP Specific "Best" - Cloud 1.0 Specific
      if node['area'] == other_node['area'] and node['az'] == other_node['az']
        return member['meta_data']['private_ipv4']
      else
        return member['meta_data']['public_ipv4']
      end
    end

    return nil
  end

  def select_best_ip_ohai(other_node)
    # Really? ohai doesn't offer the placement of an instance. Great.
    if other_node.attribute?('cloud')
      if node.attribute?('cloud') && (other_node['cloud']['provider'] == node['cloud']['provider'])
        return other_node['cloud']['local_ipv4']
      else
        return other_node['cloud']['public_ipv4']
      end
    end

    return nil
  end
end

class Chef::Recipe
    include SearchHelper
end
