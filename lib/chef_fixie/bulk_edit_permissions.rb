#
# Copyright (c) 2015 Chef Software Inc.
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
require 'sequel'

require_relative 'config.rb'
require_relative 'authz_objects.rb'
require_relative 'authz_mapper.rb'

require 'pp'

module ChefFixie
  module BulkEditPermissions
    def self.orgs
      @orgs ||= ChefFixie::Sql::Orgs.new
    end
    def self.users
      @users ||= ChefFixie::Sql::Users.new
    end
    def self.assocs
      @assocs ||= ChefFixie::Sql::Associations.new
    end
    def self.invites
      invites ||= ChefFixie::Sql::Invites.new
    end

    def self.check_permissions(org)
      org = orgs[org] if org.is_a?(String)
      admins = org.groups['admins'].authz_id
      pivotal = users['pivotal'].authz_id
      errors = Hash.new({})
      org.each_authz_object do |object|
        acl = object.acl_raw
        broken_acl = {}
        # the one special case
        acl.each do |k,v|
          list = []
          list << "pivotal" if !v['actors'].member?(pivotal)
          # admins doesn't belong to the billing admins group
          if object.class != ChefFixie::Sql::Group || object.name != 'billing-admins'
            list << "admins" if !v['groups'].member?(admins)
          end
          broken_acl[k] = list if !list.empty?
        end
        if !broken_acl.empty?
          classname = object.class
          errors[classname] = {} if !errors.has_key?(classname)
          errors[classname][object.name] = broken_acl
        end
      end
      return errors
    end

    def self.ace_add(list, ace_type, entity)
      list.each do |item|
        if item.respond_to?(:ace_add)
          item.ace_add(ace_type, entity)
        else
          puts "item.class is not a native authz type"
          return
        end
      end
    end
    def self.ace_delete(list, ace_type, entity)
      list.each do |item|
        if item.respond_to?(:ace_delete)
          item.ace_delete(ace_type, entity)
        else
          puts "item.class is not a native authz type"
          return
        end
      end
    end

    def self.do_all_objects(org)
      org = orgs[org] if org.is_a?(String)

      containers = org.containers.all(:all)
      # Maybe we should fix up containers first?
      # fix up objects in containers
      containers.each do |container|
        # TODO Write some tests to validate that this stuff
        # works, since it depends on a lot of name magic...
        object_type = container.name.to_sym
#        raise Exception "No such object_type #{object_type}" unless org.respond_to?(object_type)
        objects = org.send(object_type).all(:all)
        if block_given?
          yield objects
        end
      end
    end

    def self.ace_add_all(org, ace_type, entity)
      org = orgs[org] if org.is_a?(String)
      org.each_authz_object_by_class do |objects|
        ace_add(objects, ace_type, entity)
      end
    end

    def self.ace_delete_all(org, ace_type, entity)
      org = orgs[org] if org.is_a?(String)
      org.each_authz_object_by_class do |objects|
        ace_delete(objects, ace_type, entity)
      end
    end

    def self.add_admin_permissions(org)
      org = orgs[org] if org.is_a?(String)
      # rework when ace add takes multiple items...
      admins = org.groups['admins']
      pivotal = users['pivotal']
      org.each_authz_object do |object|
        object.ace_add(:all, pivotal)
        if object.class != ChefFixie::Sql::Group || object.name != 'billing-admins'
          object.ace_add(:all, admins)
        end
      end
    end

    def self.copy_from_containers(org)
      org = orgs[org] if org.is_a?(String)

      containers = org.containers.all(:all)
      containers.each do |c|
        # don't mess with containers and groups, they are special
        next if c.name == "containers" || c.name == "groups"
        org.objects_by_container_type(c.name).each do |obj|
          obj.acl_add_from_object(c)
          puts "#{obj.name} from #{c.name}"
        end
      end
      return
    end

  end
end
