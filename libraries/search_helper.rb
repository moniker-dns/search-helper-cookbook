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
  def search_helper_best_ip(query, override=nil, required=true, &block)
    Chef::Log.debug("Preparing to search using query: #{query}")

    if Chef::Config[:solo] and override.nil?
      if required
        Chef::Application.fatal!("You must supply an override with chef-solo")
      else
        return []
      end
    elsif override.nil?
      # Perform a search
      nodes = search(:node, query)

      if nodes.empty? and required
        Chef::Application.fatal!("Search was unable to find any nodes.")
      elsif nodes.empty?
        Chef::Log.info("Search found no nodes")
        return []
      else
        Chef::Log.info("Search found #{nodes.length} nodes: #{nodes.map{|n| n[:hostname]}}")

        nodes.map! do |member|
          yield select_best_ip(member), member
        end

        return nodes
      end
    else
      Chef::Log.info("Search skipped. Using override value.")

      return override
    end
  end

  def search_helper(type, query, override=nil, required=true, &block)
    Chef::Log.debug("Preparing to search #{type} using query: #{query}")

    if Chef::Config[:solo] and override.nil?
      if required
        Chef::Application.fatal!("You must supply an override with chef-solo")
      else
        return []
      end
    elsif override.nil?
      results = search(type, query)

      if results.empty? and required
        Chef::Application.fatal!("Search was unable to find any results.")
      elsif results.empty?
        Chef::Log.info("Search found no results")
        return []
      else
        Chef::Log.info("Search found #{results.length} results")

        results.map! do |result|
          yield result
        end

        return results
      end
    else
      Chef::Log.info("Search skipped. Using override value.")

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
        return other_node['meta_data']['private_ipv4']
      else
        return other_node['meta_data']['public_ipv4']
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

class Chef::Node
  include SearchHelper
end
