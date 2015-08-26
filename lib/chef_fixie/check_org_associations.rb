# -*- indent-tabs-mode: nil; fill-column: 110 -*-
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

require 'chef_fixie/config'
require 'chef_fixie/authz_objects'
require 'chef_fixie/authz_mapper'

require 'chef_fixie/utility_helpers'

module ChefFixie
  module CheckOrgAssociations
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

    def self.make_user(user)
      if user.is_a?(String)
        return users[user]
      elsif user.is_a?(ChefFixie::Sql::User)
        return user
      else
        raise "Expected a user, got a #{user.class}"
      end
    end
    def self.make_org(org)
      if org.is_a?(String)
        return orgs[org]
      elsif org.is_a?(ChefFixie::Sql::Org)
        return org
      else
        raise "Expected an org, got a #{org.class}"
      end
    end

    def self.check_association(org, user, global_admins = nil)
      # magic to make usage easier
      org = make_org(org)
      user = make_user(user)
      global_admins ||= org.global_admins

      # check that the user is associated
      if !assocs.by_org_id_user_id(org.id, user.id)
        return :not_associated
      end

      usag = org.groups[user.id]
      # check that user has USAG
      if usag.nil?
        return :missing_usag
      end

      if !usag.member?(user)
        return :user_not_in_usag
      end

      if !org.groups['users'].member?(usag)
        return :usag_not_in_users
      end

      if !user.ace_member?(:read, global_admins)
        return :global_admins_lacks_read
      end

      if invites.by_org_id_user_id(org.id, user.id)
        return :zombie_invite
      end
      return true
    end

    def self.fix_association(org, user, global_admins = nil)
      # magic to make usage easier
      org = orgs[org] if org.is_a?(String)
      user = users[user] if user.is_a?(String)
      global_admins ||= org.global_admins

      failure = check_association(org,user,global_admins)

      case failure
      when true
        puts "#{org.name} #{user.name} doesn't need repair"
      when :user_not_in_usag
        usag = org.groups[user.id]
        usag.group_add(user)
      when :usag_not_in_users
        usag = org.groups[user.id]
        org.groups['users'].group_add(usag)
      when :global_admins_lacks_read
        user.ace_add(:read, global_admins)
      else
        puts "#{org.name} #{user.name} can't fix problem #{failure} yet"
        return false
      end
      return true
    end

    def self.check_associations(org)
      success = true
      org = make_org(org)
      orgname = org.name

      # check that global_admins exists:
      global_admins = org.global_admins
      if !global_admins || !global_admins.is_a?(ChefFixie::Sql::Group)
        puts "#{orgname} Missing global admins group"
        success = false
      end

      users_assoc = assocs.by_org_id(org.id).all(:all)
      users_invite = invites.by_org_id(org.id).all(:all)

      user_ids = users_assoc.map {|a| a.user_id }
      users_in_org = user_ids.map {|i| users.by_id(i).all.first }
      usernames = users_in_org.map {|u| u.name }


      # check that users aren't both invited and associated
      invited_ids = users_invite.map {|a| a.user_id }
      overlap_ids = user_ids & invited_ids

      if !overlap_ids.empty?
        overlap_names = overlap_ids.map {|i| users.by_id(i).all.first.name rescue "#{i}" }
        puts "#{orgname} users both associated and invited: #{overlap_names.join(', ') }"
        success = false
      end

      # Check that we don't have zombie USAGs left around (not 100% reliable)
      # because someone could create a group that looks like a USAG
      possible_usags = org.groups.list(:all) - user_ids
      usags = possible_usags.select {|n| n =~ /^\h+{20}$/ }
      if !usags.empty?
        puts "#{orgname} Suspicious USAGS without associated user #{usags.join(', ') }"
      end

      # Check group membership for sanity
      success &= check_group(org, 'billing-admins', usernames)
      success &= check_group(org, 'admins', usernames)

      # TODO check for non-usags in users!
      users_members = org.groups['users'].group
      users_actors = users_members['actors'] - [[:global, "pivotal"]]
      if !users_actors.empty?
        puts "#{orgname} has actors in it's users group #{users_actors}"
      end
      non_usags = users_members['groups'].map {|g| g[1] } - user_ids
      if !non_usags.empty?
        puts "#{orgname} warning: has non usags in it's users group #{non_usags.join(', ')}"
      end


      # Check individual associations
      users_in_org.each do |user|
        result = self.check_association(org,user,global_admins)
        if (result != true)
          puts "Org #{orgname} Association check failed for #{user.name} #{result}"
          success = false
        end
      end

      puts "Org #{orgname} is #{success ? 'ok' : 'bad'} (#{users_in_org.count} users)"
      return success
    end

    # expect at least one current user to be in admins and billing admins
    def self.check_group(org, groupname, users)
      g = org.groups[groupname]
      if g.nil?
        puts "#{orgname} Missing group #{groupname}"
        return :no_such_group
      end
      actors = g.group['actors'].map {|x| x[1] }
      live = actors & users

      if live.count == 0
        puts "Org #{org.name} has no active users in #{groupname}"
        return false
      end
      return true
    end


    ## TODO: Port this
    def self.remove_association(org, user)
      # magic to make usage easier
      org = orgs[org] if org.is_a?(String)
      user = users[user] if user.is_a?(String)

      # remove USAG
      delete_usag_for_user(orgname,username)

      # remove read ACE
      u_aid =  user.authz_id
      ga = OrgMapper::CouchSupport.doc_from_view("#{orgname}_global_admins", "#{Group}/by_groupname")
      ga_aid = user_to_authz(ga["_id"])

      read_ace = OrgMapper::RawAuth.get("actors/#{u_aid}/acl/read")
      read_ace["groups"] -= [ga_aid]
      OrgMapper::RawAuth.put("actors/#{u_aid}/acl/read", read_ace)

      # remove association record

      org_assoc = OrgMapper::CouchSupport.associations_for_org(orgname)
      doc = org_assoc.select {|x| x[:uid] == user.id}.first

      OrgMapper::CouchSupport.delete_account_doc(doc[:id])

      # clean up excess invites
      invites = OrgMapper::CouchSupport.invites_for_org(orgname)
      invite_map = invites.inject({}) {|a,e| a[e[:name]] = e; a}

      if invite_map.has_key?(username)
        invite = invite_map[username]
        OrgMapper::CouchSupport.delete_account_doc(invite[:id])
      end
    end
  end
end
