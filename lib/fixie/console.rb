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
# Much of this code was orginally derived from the orgmapper tool, which had many varied authors.

module Fixie
  module Console
    extend self

    def irb_conf
      IRB.conf
    end

    def start
      # FUGLY HACK: irb gives us no other choice.
      irb_help = [:help, :irb_help, IRB::ExtendCommandBundle::NO_OVERRIDE]
      IRB::ExtendCommandBundle.instance_variable_get(:@ALIASES).delete(irb_help)

      # This has to come before IRB.setup b/c IRB.setup eats ARGV.
      configure

      # Horrible shameful hack TODO FIXME
      # We can't include a lot of the SQL code until we configure things, because
      # we inherit from Model e.g.
      # class Users < Sequel::Model(:users) 
      require 'fixie'
      

      # HACK: this duplicates the functions of IRB.start, but we have to do it
      # to get access to the main object before irb starts.
      ::IRB.setup(nil)

      irb = IRB::Irb.new

      setup(irb.context.main)


      irb_conf[:IRB_RC].call(irb.context) if irb_conf[:IRB_RC]
      irb_conf[:MAIN_CONTEXT] = irb.context

      trap("SIGINT") do
        irb.signal_handle
      end

      catch(:IRB_EXIT) do
        irb.eval_input
      end
    end

    def configure

      if ARGV.first && ARGV[0].chars.first != "-" && config_file = ARGV.shift
        config_file = File.expand_path(config_file)
        load_config_file = true
      end

      options = {}
      OptionParser.new do |opt|
        opt.banner = "Usage: fixie [config] [options]"
        opt.on('--authz_uri AUTH_URI', "The URI of the opscode authz service") { |v| options[:authz_uri] =v }
        opt.on("--sql_database DATABASE", 'The URI of the opscode_chef database') { |v| options[:sql_database] = v }
        opt.on_tail('-h', '--help', 'Show this message') do
          puts opt
          puts "\nExample configuration file:\n\n"
          puts Fixie::Config.instance.example_config
          puts "\n"
          exit(1)
        end
        opt.parse!(ARGV)
      end
      pp :cli_opts => options if ENV["DEBUG"]

      if load_config_file
        puts "loading config: #{config_file}..."
        Kernel.load(config_file)
      end

      Fixie::Config.instance.merge_opts(options)
      puts Fixie::Config.instance.to_text
    end

    def setup(context)
      # TODO: do we have to polute global object with this to make it available to the irb instance?
      Object.const_set(:ORGS, Fixie::Sql::Orgs.new)
      Object.const_set(:USERS, Fixie::Sql::Users.new)
      Object.const_set(:ASSOCS, Fixie::Sql::Associations.new)
      Object.const_set(:INVITES, Fixie::Sql::Invites.new)

      # scope this by the global org id?
      Object.const_set(:GLOBAL_GROUPS, Fixie::Sql::Groups.new.by_org_id(Fixie::Sql::Orgs::GlobalOrg))
      Object.const_set(:GLOBAL_CONTAINERS, Fixie::Sql::Containers.new.by_org_id(Fixie::Sql::Orgs::GlobalOrg))

      context.extend(Context)

    end

    # Configure IRB how we like it. This needs to be hooked into IRB.run_config
    # because much of IRB's code is anachronistic
    def configure_irb
      IRB.init_config(__FILE__)

      IRB.conf[:HISTORY_FILE] = "~/.fixie_history"
      IRB.conf[:SAVE_HISTORY]=1000
      IRB.conf[:USE_READLINE]=true
      IRB.conf[:PROMPT][:FIXIE] = { # name of prompt mode
        :PROMPT_I => "fixie:%i > ", # normal prompt
        :PROMPT_S => "..%l ",   # prompt for continuing strings
        :PROMPT_C => "... ",    # prompt for continuing statement
        :RETURN => "%s\n"  # format to return value
      }

      IRB.conf[:PROMPT_MODE] = :FIXIE

      begin
        require 'wirble'
        Wirble.init
      rescue LoadError
      end

    end

  end
end
