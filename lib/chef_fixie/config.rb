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
# Much of this code was orginally derived from the orgmapper tool, which had many varied authors.

require 'singleton'
require 'ffi_yajl'
require 'pathname'

module ChefFixie
  def self.configure
    yield Config.instance
  end

  def self.load_config(config_file = nil)
    if config_file
      puts "loading config: #{config_file}..."
      Kernel.load(config_file)
    else
      path = "/etc/opscode"
      puts "loading config from #{path}"
      ChefFixie::Config.instance.load_from_pc(path)
    end
  end

  def self.setup
    # TODO: do we have to polute global object with this to make it available to the irb instance?
    Object.const_set(:ORGS, ChefFixie::Sql::Orgs.new)
    Object.const_set(:USERS, ChefFixie::Sql::Users.new)
    Object.const_set(:ASSOCS, ChefFixie::Sql::Associations.new)
    Object.const_set(:INVITES, ChefFixie::Sql::Invites.new)

    # scope this by the global org id?
    Object.const_set(:GLOBAL_GROUPS, ChefFixie::Sql::Groups.new.by_org_id(ChefFixie::Sql::Orgs::GlobalOrg))
    Object.const_set(:GLOBAL_CONTAINERS, ChefFixie::Sql::Containers.new.by_org_id(ChefFixie::Sql::Orgs::GlobalOrg))
  end

  ##
  # = ChefFixie::Config
  # configuration for the fixie command.
  #
  # ==Example Config File:
  #
  #   Fixie.configure do |mapper|
  #     mapper.authz_uri = 'http://authz.example.com:5959'
  #   end
  #
  class Config
    include Singleton
    KEYS = [:authz_uri, :sql_database, :superuser_id, :pivotal_key]
    KEYS.each { |k| attr_accessor k }

    def merge_opts(opts={})
      opts.each do |key, value|
        send("#{key}=".to_sym, value)
      end
    end

    # this is waaay tightly coupled to ::Backend's initialize method
    def to_ary
      [couchdb_uri, database, auth_uri, authz_couch, sql_database, superuser_id].compact
    end

    def to_text
      txt = ["### ChefFixie::Config"]
      max_key_len = KEYS.inject(0) do |max, k|
        key_len = k.to_s.length
        key_len > max ? key_len : max
      end
      KEYS.each do |key|
        value = send(key) || 'default'
        txt << "# %#{max_key_len}s: %s" % [key.to_s, value]
      end
      txt.join("\n")
    end

    def example_config
      txt = ["Fixie.configure do |mapper|"]
      KEYS.each do |key|
        txt << "  mapper.%s = %s" % [key.to_s, '"something"']
      end
      txt << "end"
      txt.join("\n")
    end

    def load_from_pc(dir = "/etc/opscode")
      configdir = Pathname.new(dir)

      config_files = %w(chef-server-running.json)
      config = load_json_from_path([configdir], config_files)

      authz_config = config['private_chef']['oc_bifrost']
      authz_vip = authz_config['vip']
      authz_port = authz_config['port']
      @authz_uri = "http://#{authz_vip}:#{authz_port}"
      
      @superuser_id = authz_config['superuser_id']

      sql_config = config['private_chef']['postgresql']
      
      sql_user = sql_config['sql_user']
      sql_pw = sql_config['sql_password']
      sql_vip = sql_config['vip']
      sql_port = sql_config['port']
      
      @sql_database = "postgres://#{sql_user}:#{sql_pw}@#{sql_vip}/opscode_chef"
      
      @pivotal_key = configdir + "pivotal.pem"
    end

    def load_json_from_path(pathlist, filelist)
      parser = FFI_Yajl::Parser.new
      pathlist.each do |path|
        filelist.each do |file|
          configfile = path + file
          if configfile.file?
            data = File.read(configfile)
            return parser.parse(data)
          end
        end
      end
    end
  end
end
