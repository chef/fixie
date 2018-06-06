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

require "ffi_yajl"
require "uuidtools"
require "sequel"

require_relative "config"

Sequel.default_timezone = :utc

module ChefFixie
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
      @connection_string ||= ChefFixie.configure { |x| x.sql_database }
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
      FFI_Yajl::Parser.parse(serialized_data, :symbolize_keys => true)
    end

    # Encode the portion of the object that's stored as a blob o' JSON
    def as_json(data)
      FFI_Yajl::Encoder.encode(data)
    end

  end
end
