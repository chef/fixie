require 'yajl'
require 'uuidtools'
require 'sequel'

require 'fixie/config.rb'

Sequel.default_timezone = :utc

module Fixie
  module Sql
    
    class InvalidConfig < StandardError
    end
    
    # A connection string passed to Sequel.connect()
    #
    # Examples:
    # * "mysql2://root@localhost/opscode_chef"
    # * "mysql2://user:password@host/opscode_chef"
    # * "jdbc:mysql://localhost/test?user=root&password=root"
    #
    # See also: http://sequel.rubyforge.org/rdoc/files/doc/opening_databases_rdoc.html
    def self.connection_string=(sequel_connection_string)
      @database.disconnect if @database.respond_to?(:disconnect)
      @database = nil
      @connection_string = sequel_connection_string
    end

    # Returns the connection string or raises an error if you didn't set one.
    def self.connection_string
      @connection_string ||= Fixie.configure {|x| x.sql_database }
    end
    
    # Returns a Sequel::Data baseobject, which wraps access to the database.
    def self.default_connection
      @database ||= Sequel.connect(connection_string, :max_connections => 2)
      #      @database.loggers << Logger.new($stdout)
    end
    
    # Generate a new UUID. Currently uses the v1 UUID scheme.
    def new_uuid
      UUIDTools::UUID.timestamp_create.hexdigest
    end
    
    # Parse the portion of the object that's stored as a blob o' JSON
    def from_json(serialized_data)
      Yajl::Parser.parse(serialized_data, :symbolize_keys => true)
    end
    
    # Encode the portion of the object that's stored as a blob o' JSON
    def as_json(data)
      Yajl::Encoder.encode(data)
    end

    # Set the connection up 
    puts "String: #{connection_string}"
#    default_connection

#    class Orgs < Sequel::Model(:orgs) 
#    end
#    
#    class Users < Sequel::Model(:users) 
#    end
#
#    class Associations < Sequel::Model(:org_user_associations) 
#    end
#
#    class Invitations < Sequel::Model(:org_user_invites) 
#    end



  end
end
