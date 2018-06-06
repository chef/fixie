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

require "pp"
require "sequel"

require_relative "config"
require_relative "authz_objects"
require_relative "authz_mapper"

Sequel.extension :inflector

module ChefFixie
  module Sql

    # Maps entity names like 'org' to the table class (Orgs) and the entity class (Org), as well as the cannonical
    # each table has a name, a class to wrap the table, an row, and a class to map the row.
    # Wrapping this in a class to handle things if we have to not be consisitent with our naming.
    # table :orgs, class wrapper Orgs, row :org, class for row Org
    module Relationships

      def self.base
        "ChefFixie::Sql" + "::" # this should be autogenerated not hardcoded
      end

      def self.to_name(class_or_name)
        name =
          case
          when class_or_name.is_a?(Symbol)
            class_or_name.to_s
          when class_or_name.is_a?(Class)
            class_or_name.name
          when class_or_name.is_a?(String)
            class_or_name
          else
            class_or_name.class.to_s
          end
        name.split("::")[-1]
      end

      # The class for the table, e.g. Orgs
      def self.table_class(name)
        name = to_name(name)
        (base + name.to_s.pluralize.camelize).constantize
      end

      # The class for one instance of the object, e.g. Org
      def self.object_class(name)
        name = to_name(name)
        (base + name.to_s.singularize.camelize).constantize
      end

      def self.singular(name)
        name = to_name(name)
        name.to_s.singularize
      end

      def self.plural(name)
        name = to_name(name)
        name.to_s.pluralize
      end
    end

    # we declare these first so that the 'element' metaprogramming in SqlTable works
    class SqlObject
      def initialize(data)
        @data = data
      end

      def data
        @data
      end

      def table
        Relationships.table_class(self).new
      end

      # TODO rework this to use better style
      def self.ro_access(*args)
        args.each do |field|
          fundef = "def #{field}; @data.#{field}; end"
          class_eval(fundef)
        end
      end
      # TODO figure out model for write access

      def self.name_field(field)
        fundef = "def name; @data.#{field}; end"
        class_eval(fundef)
      end

      def self.std_timestamp
        [:created_at, :updated_at].each do |i|
          ro_access(i)
        end
      end

      # Pretty much any object with an authz id has these fields
      def self.std_authz
        std_timestamp
        [:authz_id, :last_updated_by].each do |i|
          ro_access(i)
        end
      end

      def delete
        rows = table.by_id(id)
        raise "id #{id} matches more than one object" if rows.all.count != 1
        rows.inner.delete
        if respond_to?(:authz_delete)
          authz_delete
        end
      end
    end

    class Org < SqlObject
      include AuthzObjectMixin

      def self.scoped_type(*args)
        args.each do |object|
          funname = Relationships.plural(object)
          # defer evaluation of mapper to make sure we have a chance for everyone to initialize
          fundef = "def #{funname}; Relationships.table_class(:#{object}).new.by_org_id(org_id); end"
          class_eval(fundef)
        end
      end

      def initialize(data)
        super(data)
      end

      def org_id
        data[:id]
      end

      def global_admins
        name = self.name
        global_admins_name = "#{name}_global_admins"
        read_access_name = "#{name}_read_access_group"
        ChefFixie::Sql::Groups.new[global_admins_name] || \
          ChefFixie::Sql::Groups.new[read_access_name]
      end

      alias read_access_group global_admins

      # Iterators for objects in authz; using containers to enumerate things
      # It might be better to metaprogram this up instead,
      #
      # TODO Write some tests to validate that this stuff
      # works, since it depends on a lot of name magic...

      NAME_FIXUP = { "data" => "data_bags", "sandboxes" => nil }
      def objects_by_container_type(container)
        name = NAME_FIXUP.has_key?(container) ? NAME_FIXUP[container] : container
        return [] if name.nil?

        object_type = name.to_sym
        #        raise Exception "No such object_type #{object_type}" unless respond_to?(object_type)
        send(object_type).all(:all)
      end

      def each_authz_object_by_class
        containers = self.containers.all(:all)
        containers.each do |container|
          objects = objects_by_container_type(container.name)
          if block_given?
            yield objects
          end
        end
        nil
      end

      def each_authz_object
        each_authz_object_by_class do |objectlist|
          objectlist.each do |object|
            yield object
          end
        end
        nil
      end

      scoped_type :container, :group, :client,
                  :cookbook_artifact, :cookbook, :data_bag, :environment, :node, :policy, :policy_group , :role

      # Maybe autogenerate this from data.columns?
      ro_access :id, :authz_id, :assigned_at, :last_updated_by, :created_at, :updated_at, :name, :full_name
    end

    #
    # Some types have an org_id field and may be scoped to an org (some, like groups are able to be global as well)
    # This sets up a filtered accessor that limits
    #
#    module ScopedType
#      def self.included(base)
#        pp :base=>base
#        Org.scoped_type(base)
#      end
#    end

    class Container < SqlObject
      include AuthzContainerMixin

      def initialize(data)
        super(data)
      end

      ro_access :id, :org_id, :authz_id, :last_updated_by, :created_at, :updated_at, :name
    end
    class Group < SqlObject
      include AuthzGroupMixin

      def initialize(data)
        super(data)
      end

      ro_access :id, :org_id, :authz_id, :last_updated_by, :created_at, :updated_at, :name
    end

    class User < SqlObject
      include AuthzActorMixin
      def initialize(data)
        super(data)
      end
      name_field :username
      ro_access :id, :authz_id, :last_updated_by, :created_at, :updated_at, :username, :email, :public_key, :pubkey_version, :serialized_object, :external_authentication_uid, :recovery_authentication_enabled, :admin, :hashed_password, :salt, :hash_type
    end
    class Client < SqlObject
      include AuthzActorMixin
      def initialize(data)
        super(data)
      end
      ro_access :id, :org_id, :authz_id, :last_updated_by, :created_at, :updated_at, :name
    end

    # Objects

    # At the time of writing there are more objects in sql than we
    # support here; we should add them. We have only covered the
    # objects that have their own authz info
    # Missing objects include:
    # checksums cookbook_artifact_version_checksums
    # cookbook_artifact_versions cookbook_artifact_versions_id_seq
    # cookbook_artifacts_id_seq cookbook_version_checksums
    # cookbook_version_dependencies cookbook_versions
    # cookbook_versions_by_rank cookbooks_id_seq data_bag_items
    # joined_cookbook_version keys keys_by_name node_policy opc_customers
    # opc_customers_id_seq opc_users org_migration_state
    # org_migration_state_id_seq policy_revisions
    # policy_revisions_policy_groups_association sandboxed_checksums

    class CookbookArtifact < SqlObject
      include AuthzObjectMixin
      def initialize(data)
        super(data)
      end
      ro_access :id, :org_id, :authz_id, :name
    end

    class Cookbook < SqlObject
      include AuthzObjectMixin
      def initialize(data)
        super(data)
      end
      ro_access :id, :org_id, :authz_id, :name
    end

    class DataBag < SqlObject
      include AuthzObjectMixin
      def initialize(data)
        super(data)
      end
      ro_access :id, :org_id, :authz_id, :last_updated_by, :created_at, :updated_at, :name
    end

    # data bag item needs some prep work to do since it doesn't have authz stuff.

    class Environment < SqlObject
      include AuthzObjectMixin
      def initialize(data)
        super(data)
      end
      ro_access :id, :org_id, :authz_id, :last_updated_by, :created_at, :updated_at, :name, :serialized_object
      # serialized_object requires work since most of the time it isn't wanted
    end

    class Node < SqlObject
      include AuthzObjectMixin
      def initialize(data)
        super(data)
      end
      ro_access :id, :org_id, :authz_id, :last_updated_by, :created_at, :updated_at, :name, :serialized_object
      # serialized_object requires work since most of the time it isn't wanted
    end

    class Policy < SqlObject
      include AuthzObjectMixin
      def initialize(data)
        super(data)
      end
      ro_access :id, :org_id, :authz_id, :last_updated_by, :name
      # serialized_object requires work since most of the time it isn't wanted
    end

    class PolicyGroup < SqlObject
      include AuthzObjectMixin
      def initialize(data)
        super(data)
      end
      ro_access :id, :org_id, :authz_id, :last_updated_by, :name, :serialized_object
      # serialized_object requires work since most of the time it isn't wanted
    end

    class Role < SqlObject
      include AuthzObjectMixin
      def initialize(data)
        super(data)
      end
      ro_access :id, :org_id, :authz_id, :last_updated_by, :created_at, :updated_at, :name, :serialized_object
      # serialized_object requires work since most of the time it isn't wanted
    end

    #
    #
    #
    class SqlTable
      include AuthzMapper

      def self.max_count_default
        50
      end

      def get_table
        :unknown_table
      end

      def mk_element(x)
        x
      end

      def initialize(tablespec = nil)
        ChefFixie::Sql.default_connection
        @inner = tablespec || Sequel::Model(get_table)
      end

      def inner
        # Make sure we have init
        @inner
      end

      def filter_core(field, exp)
        self.class.new(inner.filter(field => exp))
      end

      def all(max_count = :default)
        if max_count == :default
          max_count = ChefFixie::Sql::SqlTable.max_count_default
        end
        if max_count != :all
          return :too_many_results if inner.count > max_count
        end
        elements = inner.all.map { |org| mk_element(org) }
      end

      #
      # TODO Improve these via define_method
      # See http://blog.jayfields.com/2007/10/ruby-defining-class-methods.html
      #     https://stackoverflow.com/questions/9658724/ruby-metaprogramming-class-eval/9658775#9658775
      def self.primary(arg)
        name = :"by_#{arg}"
        class_eval("def [](arg); #{name}(arg).all(1).first; end")

        listfun = <<EOLF
def list(max_count=:default)
  elements = all(max_count)
  if elements == :too_many_results
     elements
  else
     elements.map {|e| e.#{arg} }.sort
  end
end
EOLF
        class_eval(listfun)
      end

      def self.filter_by(*args)
        args.each do |field|
          name = "by_#{field}"
          fundef = "def #{name}(exp); filter_core(:#{field},exp); end"
          class_eval(fundef)
        end
      end

      def self.table(name)
        fundef = "def get_table; :#{name}; end"
        class_eval(fundef)
      end

      # doesn't work yet
      # element Org in class Orgs will fail because it can't find Org (undefined)
      def self.element(name)
        fundef = "ElementType = name; def mk_element(x); #{name}.new(x); end"
        class_eval(fundef)
      end
    end

    class Orgs < SqlTable
      table :orgs
      element Sql::Org
      register_authz :org, :object

      primary :name
      filter_by :name, :id, :full_name, :authz_id

      GlobalOrg = "0" * 32

      def self.org_guid_to_name(guid)
        "global" if guid == GlobalOrg
        # Cache the class
        @orgs ||= Orgs.new
        names = @orgs.by_id(guid).all(1)
        if names.count == 1
          names.first.name
        else
          "unknown-#{guid}"
        end
      end
    end

    class Associations < SqlTable
      table :org_user_associations
      filter_by :org_id, :user_id, :last_updated_by

      def by_org_id_user_id(org_id, user_id)
        # db table constraint guarantees that this is unique
        inner.filter(:org_id => org_id, :user_id => user_id).all.first
      end

    end
    class Invites < SqlTable
      table :org_user_invites
      filter_by :org_id, :user_id, :last_updated_by

      def by_org_id_user_id(org_id, user_id)
        # db table constraint guarantees that this is unique
        inner.filter(:org_id => org_id, :user_id => user_id).all.first
      end
    end
    class Users < SqlTable
      table :users
      element Sql::User
      register_authz :user, :actor

      primary :username
      filter_by :id, :authz_id, :username, :email
    end
    class Clients < SqlTable
      table :clients
      element Sql::Client
      register_authz :client, :actor

      primary :name
      filter_by :name, :id, :org_id, :authz_id, :last_updated_by
    end

    class Containers < SqlTable
      table :containers
      element Sql::Container
      register_authz :container, :container

      primary :name
      filter_by :name, :id, :org_id, :authz_id, :last_updated_by
    end
    class Groups < SqlTable
      table :groups
      element Sql::Group
      register_authz :group, :group

      primary :name
      filter_by :name, :id, :org_id, :authz_id, :last_updated_by
    end

    # Objects
    # todo check
    class CookbookArtifacts < SqlTable
      table :cookbook_artifacts
      element Sql::CookbookArtifact
      register_authz :cookbook_artifact, :object

      primary :name
      filter_by :name, :id, :org_id, :authz_id
    end

    class Cookbooks < SqlTable
      table :cookbooks
      element Sql::Cookbook
      register_authz :cookbook, :object

      primary :name
      filter_by :name, :id, :org_id, :authz_id
    end

    class DataBags < SqlTable
      table :data_bags
      element Sql::DataBag
      register_authz :data_bag, :object

      primary :name
      filter_by :name, :id, :org_id, :authz_id, :last_updated_by
    end

    class Environments < SqlTable
      table :environments
      element Sql::Environment
      register_authz :environment, :object

      primary :name
      filter_by :name, :id, :org_id, :authz_id, :last_updated_by
    end

    class Nodes < SqlTable
      table :nodes
      element Sql::Node
      register_authz :node, :object

      primary :name
      filter_by :name, :id, :org_id, :authz_id, :last_updated_by
    end

    class Policies < SqlTable
      table :policies
      element Sql::Policy
      register_authz :policy, :object

      primary :name
      filter_by :name, :id, :org_id, :authz_id
    end

    class PolicyGroups < SqlTable
      table :policy_groups
      element Sql::PolicyGroup
      register_authz :policygroup, :object

      primary :name
      filter_by :name, :id, :org_id, :authz_id
    end

    class Roles < SqlTable
      table :roles
      element Sql::Role
      register_authz :role, :object

      primary :name
      filter_by :name, :id, :org_id, :authz_id, :last_updated_by
    end

  end
end
