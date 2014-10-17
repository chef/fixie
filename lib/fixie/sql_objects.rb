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

module Fixie
  module Sql
    # predeclare these so the metaprogrammed 'element' method works

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

      
      
    end

    class Org < SqlObject
      include AuthzObjectMixin

      def self.scoped_type(*args)
        args.each do |field|
          fundef = "def #{field}; Groups.new(Sequel::Model(:#{field}).filter(:org_id=>org_id)); end"
          self.class_eval(fundef)
        end
      end
      
      def initialize(data)
        super(data)
      end
      def org_id
        data[:id]
      end

      # Maybe autogenerate this from data.columns?
      ro_access :id, :authz_id, :assigned_at, :last_updated_by, :created_at, :updated_at, :name, :full_name
      scoped_type :nodes, :groups
      
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
    class Node < SqlObject
      include AuthzActorMixin
      def initialize(data)
        super(data)
      end
      ro_access :id, :org_id, :authz_id, :last_updated_by, :created_at, :updated_at, :name
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
        puts fundef
        self.class_eval(fundef)
      end
      # doesn't work yet
      # element Org in class Orgs will fail because it can't find Org (undefined)
      def self.element(name)
        fundef = "ElementType = name; def mk_element(x); #{name}.new(x); end"
        puts fundef
        self.class_eval(fundef)
      end     
    end     

    class Orgs < SqlTable
      table :orgs
      element Sql::Org        
      register_authz :org, :object
      
      primary :name
      filter_by :name, :id, :full_name, :authz_id

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
    
    class Groups < SqlTable
      table :groups
      element Sql::Group
      register_authz :group, :group
      
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



    
  end
end
