#
# Copyright (c) 2014-2015 Chef Software Inc.
# License :: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Author: Mark Anderson <mark@chef.io>
#

require 'pp'
require 'ffi_yajl'
require 'chef/http'

require 'fixie/config'

module Fixie

  class AuthzApi
    def initialize(user=nil)
      @requestor_authz = user ? user : Fixie.configure { |x| x.superuser_id }
      @auth_uri ||= Fixie.configure { |x| x.authz_uri }
      @rest = Chef::HTTP.new(@auth_uri)
    end

    def json_helper(s)
      if s.kind_of?(Hash)
        FFI_Yajl::Encoder.encode(s)
      else
        s
      end
    end

    def get(resource)
      result = @rest.get(resource,
                         'Content-Type'=>'application/json',
                         'Accept'=>'application/json',
                         'X-Ops-Requesting-Actor-Id'=>@requestor_authz)
      FFI_Yajl::Parser.parse(result)
    end
    def put(resource, data)
      result = @rest.put(resource, self.json_helper(data),
                         'Content-Type'=>'application/json',
                         'Accept'=>'application/json',
                         'X-Ops-Requesting-Actor-Id'=>@requestor_authz)
      FFI_Yajl::Parser.parse(result)
    end
    def post(resource, data)
      result = @rest.post(resource, self.json_helper(data),
                          'Content-Type'=>'application/json',
                          'Accept'=>'application/json',
                          'X-Ops-Requesting-Actor-Id'=>@requestor_authz)
      FFI_Yajl::Parser.parse(result)
    end
    def delete(resource)
      result = @rest.delete(resource,
                            'Content-Type'=>'application/json',
                            'Accept'=>'application/json',
                            'X-Ops-Requesting-Actor-Id'=>@requestor_authz)
      FFI_Yajl::Parser.parse(result)
    end

  end

  module AuthzUtils
    Types = [:object,:actor,:group,:container] # order is an attempt to optimize by most probable.
    Actions = [:create, :read, :update, :delete, :grant]

    def to_resource(t)
      # This is a rails thing... t.to_s.pluralize
      t.to_s + "s" # hack
    end

    def get_type(id)
      Types.each do |t|
        begin
          r = AuthzApi.get("#{self.to_resource(t)}/#{id}")
          return t
        rescue RestClient::ResourceNotFound=>e
          # expected if not found
        end
      end
      return :none
    end

    def check_action(action)
      # TODO Improve; stack trace isn't the best way to communicate with the user
      raise "#{action} not one of #{Actions.join(', ')} " if !Actions.member?(action)
    end

    def check_actor_or_group(a_or_g)
      raise "#{a_or_g} not one of :actor or :group" if a_or_g != :actor && a_or_g != :group
    end

    def resourcify_actor_or_group(a_or_g)
      return a_or_g if ["actors", "groups"].member?(a_or_g)
      check_actor_or_group(a_or_g)
      to_resource(a_or_g)
    end

    def get_authz_id(x)
      return x.authz_id if x.respond_to?(:authz_id)
      # if it quacks like an authz id
      return x if x.is_a?(String) && x =~ /^[[:xdigit:]]{32}$/
      raise "#{x} doesn't look like an authz_id"
    end
  end

  #
  module AuthzObjectMixin
    include AuthzUtils # reconsider this mixin; maybe better to refer to those routines explictly

    def self.included(base)
#      pp :note=>"Include", :base=>base, :super=>(base.superclass rescue :nil)
#      block = lambda { :object }
#      base.send(:define_method, :type_me, block )
#      pp :methods=>(base.methods.sort - Object.methods)
    end

    def type
      :object
    end

    def authz_api
       @@authz_apiAsSuperUser ||= AuthzApi.new
    end


    # we expect to be mixed in with a class that has the authz_id method
    def prefix
      "#{to_resource(type)}/#{authz_id}"
    end

    def is_authorized(action, actor)
      result = authz_api.get("#{prefix}/acl/#{action}/ace/#{actor.authz_id}")
      [:unparsed, result] # todo figure this out in more detail
    end

    def acl_raw
      authz_api.get("#{prefix}/acl")
    end
    # Todo: filter this by scope and type
    def acl
      Fixie::AuthzMapper.struct_to_name(acl_raw)
    end

    def ace_get_util(action)
      check_action(action)

      resource = "#{prefix}/acl/#{action}"
      ace = authz_api.get(resource)
      [resource, ace]
    end


    def ace_raw(action)
      resource,ace = ace_get_util(action)
      ace
    end
    # Todo: filter this by scope and type
    def ace(action)
      Fixie::AuthzMapper.struct_to_name(ace_raw(action))
    end

    def expand_actions(action)
      if action == :all
        action = AuthzUtils::Actions
      end
      action.is_a?(Array) ? action : [action]
    end



    # add actor or group to acl
    def ace_add_raw(action, actor_or_group, entity)
      # groups or actors
      a_or_g_resource = resourcify_actor_or_group(actor_or_group)
      resource, ace = ace_get_util(action)

      ace[a_or_g_resource] << get_authz_id(entity)
      ace[a_or_g_resource].uniq!
      authz_api.put("#{resource}", ace)
    end
    def ace_add(action, entity)
      actions = expand_actions(action)
      actions.each {|a| ace_add_raw(a, entity.type, entity) }
    end

    def ace_delete_raw(action, actor_or_group, entity)
      # groups or actors
      a_or_g_resource = resourcify_actor_or_group(actor_or_group)
      resource, ace = ace_get_util(action)

      ace[a_or_g_resource] -= [get_authz_id(entity)]
      ace[a_or_g_resource].uniq!
      authz_api.put("#{resource}", ace)
    end

    def ace_delete(action, entity)
      actions = expand_actions(action)
      actions.each {|a| ace_delete_raw(a, entity.type, entity) }
    end

    def ace_member?(action, entity)
      a_or_g_resource = resourcify_actor_or_group(entity.type)
      resource, ace = ace_get_util(action)
      ace[a_or_g_resource].member?(entity.authz_id)
    end


    def acl_add_from_object(object)
      src = object.acl_raw

      # this could be made more efficient by refactoring ace_add_raw to split fetch and update, but this works
      src.each do |action, ace|
        ace.each do |type, list|
          list.each do |item|
            ace_add_raw(action.to_sym, type, item)
          end
        end
      end
    end

  end

  module AuthzActorMixin
    include AuthzObjectMixin
    def type
      :actor
    end
  end
  module AuthzContainerMixin
    include AuthzObjectMixin
    def type
      :container
    end
  end
  module AuthzGroupMixin
    include AuthzObjectMixin
    def type
      :group
    end

    # Groups need a little more code to manage members.
    def group_raw
      authz_api.get("#{prefix}")
    end
    # Todo: filter this by scope and type
    def group
      Fixie::AuthzMapper.struct_to_name(group_raw)
    end

    def group_add_raw(actor_or_group, entity)
      entity_resource = to_resource(actor_or_group)
      authz_api.put("#{prefix}/#{entity_resource}/#{entity.authz_id}",{})
    end
    def group_add(entity)
      group_add_raw(entity.type, entity)
    end

    def group_delete_raw(actor_or_group, entity)
      entity_resource = to_resource(actor_or_group)
      authz_api.delete("#{prefix}/#{entity_resource}/#{entity.authz_id}")
    end

    def group_delete(entity)
      group_delete_raw(entity.type, entity)
    end

    def member?(entity)
      members = group_raw
      return members[resourcify_actor_or_group(entity.type)].member?(entity.authz_id)
    end
  end

end
