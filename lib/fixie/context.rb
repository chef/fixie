#
# Copyright Chef Inc. 2015
# All rights reserved.
#
# Author: Mark Anderson <mark@chef.io>
#
# Much of this code was orginally derived from the orgmapper tool, which had many varied authors.


module Fixie
    module Context

    def describe_orgs
      OrgMetrics.org_stats(orgs)
    end

    def orgs
      Fixie::Organizations.new
    end

    def jobs
      Fixie::Jobs.new
    end

    def users
      Fixie::Users.new
    end

    def global_groups
      Fixie::GlobalGroups.new
    end

    def help
      puts(<<-HALP)
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
      :COOL_STORY_BRO
    end

    def sql
      Fixie::Sql.default_connection
    end

    def associate_user(username, orgname)
      unless user = users.find(username)
        raise ArgumentError, "No users matched '#{username}'"
      end
      unless org = ORGS[orgname]
        raise ArgumentError, "No orgs matched '#{orgname}'"
      end

      Fixie::Associator.associate_user(org, user)
    end

    def dissociate_user(username, orgname)
      unless user = users.find(username)
        raise ArgumentError, "No users matched '#{username}'"
      end
      unless org = ORGS[orgname]
        raise ArgumentError, "No orgs matched '#{orgname}'"
      end

      Fixie::Dissociator.dissociate_user(org, user)
    end

  end
end
