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
require_relative "config"
require_relative "authz_objects"

module ChefFixie
  module AuthzMapper

    #
    # It would be really awesome if this was integrated with the
    # AuthzObjectMixin so that when it was mixed in, we automatically
    # added code to the reverse mapping
    #
    #
    # Much of this might be better folded up into a sql stored procedure
    #

    def self.included(base)
      base.extend(ClassMethods)
    end

    def authz_to_name(authz_id)
      objects = by_authz_id(authz_id).all(1)
      scope = :unknown
      name = :unknown
      if objects.count == 1
        object = objects.first
        name = object.name
        scope =
          if object.respond_to?(:org_id)
            ChefFixie::Sql::Orgs.org_guid_to_name(object.org_id)
          else
            :global
          end
        [scope, name]
      else
        :unknown
      end
    end

    class ReverseMapper
      attr_reader :names, :by_type, :instance

      def initialize
        # name of object map
        @names ||= {}
        @by_type ||= { :actor => {}, :container => {}, :group => {}, :object => {} }
        # maps class to a pre-created instance for efficiency
        @instance ||= {}
      end

      def class_cache(klass)
        instance[klass] ||= klass.new
      end

      def register(klass, name, type)
        names[name] = klass
        by_type[type][name] = klass
      end

      def dump
        pp names
      end

      def authz_to_name(authz_id, ctype = nil)
        types = if ctype.nil?
                  AuthzUtils::TYPES
                else
                  [ctype]
                end
        types.each do |type|
          by_type[type].each_pair do |name, klass|
            result = class_cache(klass).authz_to_name(authz_id)
            return result if result != :unknown
          end
        end
        :unknown
      end
    end

    def self.mapper
      @mapper ||= ReverseMapper.new
    end

    def self.register(klass, name, type)
      mapper.register(klass, name, type)
    end

    # Translates the json from authz for group membership and acls into a human readable form
    # This makes some assumptions about the shape of the data structure, but works well enough to
    # be quite useful
    def self.struct_to_name(s)
      mapper = AuthzMapper.mapper
      if s.kind_of?(Hash)
        s.keys.inject({}) do |h, k|
          v = s[k]
          if v.kind_of?(Array)
            case k
            when "actors"
              h[k] = v.map { |a| mapper.authz_to_name(a, :actor) } #.sort We should sort these, but the way we're returning unknown causes sort
            when "groups"
              h[k] = v.map { |a| mapper.authz_to_name(a, :group) } #.sort to fail
            else
              h[k] = v
            end
          else
            h[k] = struct_to_name(v)
          end
          h
        end
      end
    end

    module ClassMethods
      # TODO: We should be able to automatically figure out the type somehow.
      # At minimum should figure out a self check
      def register_authz(name, type)
        AuthzMapper.register(self, name, type)
      end
    end

  end
end
