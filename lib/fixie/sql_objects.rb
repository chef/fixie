#
# Copyright Chef Inc. 2014
# All rights reserved.
#
# Author: Mark Anderson <mark@getchef.com>
# 
require 'yajl'
require 'uuidtools'
require 'sequel'

require 'fixie/config.rb'
require 'fixie/authz_objects.rb'
require 'fixie/authz_mapper.rb'

Sequel.extension :inflector

module Fixie
  module Sql

    # Maps entity names like 'org' to the table class (Orgs) and the entity class (Org), as well as the cannonical 
    # each table has a name, a class to wrap the table, an row, and a class to map the row.
    # Wrapping this in a class to handle things if we have to not be consisitent with our naming.
    # table :orgs, class wrapper Orgs, row :org, class for row Org
    module Relationships

      def self.base
        "Fixie::Sql" + "::" # this should be autogenerated not hardcoded
      end

      # The class for the table, e.g. Orgs
      def self.table_class(name)
        (base + name.to_s.pluralize.capitalize).constantize
      end
      # The class for one instance of the object, e.g. Org
      def self.object_class(name)
        (base + name.to_s.singularize.capitalize).constantize
      end
      def self.singular(name)
        name.to_s.singularize
      end
      def self.plural(name)
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
      
      # TODO rework this to use better style
      def self.ro_access(*args)
        args.each do |field|
          fundef = "def #{field}; @data.#{field}; end"
          self.class_eval(fundef)
        end
      end
      # TODO figure out model for write access

      # for objects whose name isn't the same as the field.
      def self.name(field)
        fundef = "def name; @data.#{field}; end"
        self.class_eval(fundef)
      end

      def self.std_timestamp
        [:created_at, :updated_at].each do |i|
          self.ro_access(i)
        end
      end
      # Pretty much any object with an authz id has these fields
      def self.std_authz
        self.std_timestamp
        [:authz_id, :last_updated_by].each do |i|
          self.ro_access(i)
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
          self.class_eval(fundef)
        end
      end
      
      def initialize(data)
        super(data)
      end
      def org_id
        data[:id]
      end

      scoped_type :container, :group, :clients, :cookbook, :databag, :environment, :node, :role

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
      name :username      
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
      
      def get_table
        :unknown_table
      end
      def mk_element(x)
        x
      end

      def initialize(tablespec = nil)
        Fixie::Sql.default_connection
        @inner = tablespec || Sequel::Model(self.get_table)
      end
      def inner
        # Make sure we have init
        @inner
      end

      def filter_core(field, exp)
        self.class.new(inner.filter(field=>exp))
      end

      def all(max_count=10)
        return :too_many_results if (inner.count > max_count)
        elements = inner.all.map {|org| mk_element(org) }
      end

      # 
      # TODO Improve these via define_method
      # See http://blog.jayfields.com/2007/10/ruby-defining-class-methods.html
      #     https://stackoverflow.com/questions/9658724/ruby-metaprogramming-class-eval/9658775#9658775
      def self.primary(arg)
        name = :"by_#{arg}"
        self.class_eval("def [](arg); #{name}(arg).all(1).first; end")
      end

      def self.filter_by(*args)
        args.each do |field|
          name = "by_#{field}"
          fundef = "def #{name}(exp); filter_core(:#{field},exp); end"
          self.class_eval(fundef)
        end
      end

      def self.table(name)
        fundef = "def get_table; :#{name}; end"
        self.class_eval(fundef)
      end
      # doesn't work yet
      # element Org in class Orgs will fail because it can't find Org (undefined)
      def self.element(name)
        fundef = "ElementType = name; def mk_element(x); #{name}.new(x); end"
        self.class_eval(fundef)
      end     
    end     

    class Orgs < SqlTable
      table :orgs
      element Sql::Org        
      register_authz :org, :object
      
      primary :name
      filter_by :name, :id, :full_name, :authz_id

      GlobalOrg = "0"*32
     
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
    end
    class Invites < SqlTable
      table :org_user_invites 
      filter_by :org_id, :user_id, :last_updated_by
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

    class Roles  < SqlTable
      table :roles
      element Sql::Role
      register_authz :role, :object
      
      primary :name
      filter_by :name, :id, :org_id, :authz_id, :last_updated_by
    end
    

    
  end
end
