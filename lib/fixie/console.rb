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

require 'optparse'
require 'pp'
require 'pry'

require 'fixie'
require 'fixie/context'

module Fixie
  module Console
    extend self

    def start
      configure
      Fixie.setup
      configure_pry
      Pry.start
    end

    def configure
      config_file = nil
      if ARGV.first && ARGV[0].chars.first != "-" && config_file = ARGV.shift
        config_file = File.expand_path(config_file)
      end
      Fixie.load_config(config_file)

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

      Fixie::Config.instance.merge_opts(options)
      puts Fixie::Config.instance.to_text
    end

    def configure_pry
      Pry.config.history.file = "~/.fixie_history"
      Pry.config.prompt_name = "fixie"
      Pry::Commands.block_command("fixie-help", "Show fixie's help") do
      output.puts(<<-HALP)
** ORGS **
* access with ORGS or ORGS
* access a specific org: ORGS['orgname']

** USERS **
* users.find('clownco-org-admin')
* users.grep :clownco
* users.usernames

** RAW SQL ACCESS**
* sql[:users].select(:column, :column).where(:column => "condition").all

** irb Help **
irb_help

HALP
      end
    end

  end
end
