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


module ChefFixie
    module Context

    def describe_orgs
      OrgMetrics.org_stats(orgs)
    end

    def orgs
      ChefFixie::Organizations.new
    end

    def jobs
      ChefFixie::Jobs.new
    end

    def users
      ChefFixie::Users.new
    end

    def global_groups
      ChefFixie::GlobalGroups.new
    end

    def sql
      ChefFixie::Sql.default_connection
    end

    def associate_user(username, orgname)
      unless user = users.find(username)
        raise ArgumentError, "No users matched '#{username}'"
      end
      unless org = ORGS[orgname]
        raise ArgumentError, "No orgs matched '#{orgname}'"
      end

      ChefFixie::Associator.associate_user(org, user)
    end

    def dissociate_user(username, orgname)
      unless user = users.find(username)
        raise ArgumentError, "No users matched '#{username}'"
      end
      unless org = ORGS[orgname]
        raise ArgumentError, "No orgs matched '#{orgname}'"
      end

      ChefFixie::Dissociator.dissociate_user(org, user)
    end

  end
end
